#include "processor.h"
#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QDir>

// define number of samples for removing noise from accelerometer data
#define ACCELEROMETER_SAMPLE_NUM 10
#define GYROSCOPE_SAMPLE_NUM 10
#define ACCEL_DATA_RATE 20
#define GYRO_DATA_RATE 20
#define THRESHOLD 0.5
#define PATTERN_MATCH_THRESHOLD 0.2

Processor::Processor(QObject *parent) 
            : QObject(parent),
            m_dataRate(ACCEL_DATA_RATE)
{
    // Initialize the processor
    
    totalSampleNumber = 0;
    currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, ZERO, ZERO};
    currentPath = {0, 0, 0, 0, "", 0};

    Eigen::MatrixXd A(3, 3);  // State transition matrix
    Eigen::MatrixXd C(3, 3);  // Observation matrix
    Eigen::MatrixXd Q(3, 3);  // Process noise covariance matrix
    Eigen::MatrixXd R(3, 3);  // Measurement noise covariance matrix
    Eigen::MatrixXd P0(3, 3); // Initial state covariance matrix

    // Initialize Kalman filter
    auto kalmanFilter = new KalmanFilter(1.0 / static_cast<qreal>(ACCEL_DATA_RATE), A, C, Q, R, P0);

    Eigen::VectorXd x0(3);
    x0.setZero();
    kalmanFilter->init(0, x0);
}

void Processor::defineNewPattern()
{
    // Define a new pattern
    // Reset the path vector
    newPathVector.clear();
    patternVector.clear();
    
    // Reset the current path
    currentPath = {0, 0, 0, 0, "", 0};
    // Reset the current sensor data
    currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, ZERO, ZERO};
}


void Processor::updateDirection() {
    // Normalize the angle to be within 0 to 360 degrees
    qreal normalizedAngle = fmod(currentPath.angle, 360);
    if (normalizedAngle < 0) {
        normalizedAngle += 360;
    }

    // Determine direction based on normalized angle
    if (normalizedAngle >= 0 && normalizedAngle < 45 || normalizedAngle >= 315 && normalizedAngle < 360) {
        if (currentSensorData.x_axis == POSITIVE) {
            currentPath.direction = "right";
        } else if (currentSensorData.x_axis == NEGATIVE) {
            currentPath.direction = "left";
        } else if (currentSensorData.y_axis == POSITIVE) {
            currentPath.direction = "up";
        } else if (currentSensorData.y_axis == NEGATIVE){
            currentPath.direction = "down";
        }
    } else if (normalizedAngle >= 45 && normalizedAngle < 135) {
        if (currentSensorData.x_axis== POSITIVE) {
            currentPath.direction = "up";
        } else if (currentSensorData.x_axis == NEGATIVE) {
            currentPath.direction = "down";
        } else if (currentSensorData.y_axis== POSITIVE) {
            currentPath.direction = "left";
        } else if (currentSensorData.y_axis == NEGATIVE) {
            currentPath.direction = "right";
        }
    } else if (normalizedAngle >= 135 && normalizedAngle < 225) {
        if (currentSensorData.x_axis== POSITIVE) {
            currentPath.direction = "left";
        } else if (currentSensorData.x_axis == NEGATIVE) {
            currentPath.direction = "right";
        } else if (currentSensorData.y_axis== POSITIVE) {
            currentPath.direction = "down";
        } else if (currentSensorData.y_axis == NEGATIVE) {
            currentPath.direction = "up";
        }
    } else if (normalizedAngle >= 225 && normalizedAngle < 315) {
        if (currentSensorData.x_axis== POSITIVE) {
            currentPath.direction = "down";
        } else if (currentSensorData.x_axis == NEGATIVE) {
            currentPath.direction = "up";
        } else if (currentSensorData.y_axis== POSITIVE) {
            currentPath.direction = "right";
        } else if (currentSensorData.y_axis == NEGATIVE) {
            currentPath.direction = "left";
        }
    }
}


void Processor::processPathData()
{
    // calculate direction. only 4 directions are considered: up, down, left, right
    updateDirection();

    // update endX, endY. if direction is up or down, endX = startX. if direction is left or right, endY = startY
    if (currentPath.direction == "up" || currentPath.direction == "down") {
        currentPath.endX = currentPath.startX;
        currentPath.endY = currentPath.startY + currentSensorData.distanceMovedY;
    }
    else if (currentPath.direction == "left" || currentPath.direction == "right") {
        currentPath.endX = currentPath.startX + currentSensorData.distanceMovedX;
        currentPath.endY = currentPath.startY;
    }
        
    // add path to newPathVector
    newPathVector.append(currentPath);
}

void Processor::calibrateAccelerometer(qreal x, qreal y, qreal z)
{
    // calibrate accelerometer
    currentSensorData.averageAccelerometerX = (currentSensorData.averageAccelerometerX * currentSensorData.accelerometerSampleNumber + x) / (currentSensorData.accelerometerSampleNumber + 1);
    currentSensorData.averageAccelerometerY = (currentSensorData.averageAccelerometerY * currentSensorData.accelerometerSampleNumber + y) / (currentSensorData.accelerometerSampleNumber + 1);
    currentSensorData.averageAccelerometerZ = (currentSensorData.averageAccelerometerZ * currentSensorData.accelerometerSampleNumber + z) / (currentSensorData.accelerometerSampleNumber + 1);
    currentSensorData.accelerometerSampleNumber++;
}

qreal Processor::filterAccelerometerData(qreal data, qreal average)
{
    // Subtract the average to remove bias
    qreal filteredData = data - average;
    // Apply threshold to filter out noise
    filteredData = filteredData < THRESHOLD && filteredData > -THRESHOLD ? 0 : filteredData;
    return filteredData;
}

void Processor::sendCurrentLoacationData()
{
    // Send the current location data to the GUI including current x and y values
    emit locationDataProcessed(QString("X: %1, Y: %2")
                                .arg(currentPath.startX + currentSensorData.distanceMovedX, 0, 'f', 3)
                                .arg(currentPath.startY + currentSensorData.distanceMovedY, 0, 'f', 3));
}

int zeroVelocityXandYNum = 0;

void Processor::updatePosition(qreal x, qreal y)
{
    if (x == 0 && y == 0) {
        zeroVelocityXandYNum++;
        if (zeroVelocityXandYNum > 10){
            // enable gyro sensor
            emit gyroSensorEnabled();
            if (currentSensorData.lastSampleWasMoving) {
                processPathData();
                // TODO: emit new pattern path
                // send the last path to the GUI using json format
                emit pathDataProcessed(QString("[Path]\nstartX: %1, startY: %2\nendX: %3, endY: %4\ndirection: %5, angle: %6")
                                           .arg(currentPath.startX, 0, 'f', 3)
                                           .arg(currentPath.startY, 0, 'f', 3)
                                           .arg(currentPath.endX, 0, 'f', 3)
                                           .arg(currentPath.endY, 0, 'f', 3)
                                           .arg(currentPath.direction)
                                           .arg(currentPath.angle));

                // update currentPath
                currentPath.direction = "";
                currentPath.startY = currentPath.endY;
                currentPath.startX = currentPath.endX;

                // reset currentSensorData
                currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, currentPath.angle, 0, false, 0, 0, ZERO, ZERO};
            }
        }
        return;
    }
    else if (currentSensorData.zeroVelocityNum > 10){
        zeroVelocityXandYNum = 0;
        // disable gyro sensor
        emit gyroSensorDisabled();
        currentSensorData.averageGyroscopeZ = 0;
        currentSensorData.angleZ = 0;
        if (!currentSensorData.lastSampleWasMoving) {
            // update distanceMovedX, distanceMovedY. distance = (1/2 * abs(a) * t^2) + v0 * t. which t is the 1 / data_rate
            if (x > 0)
                currentSensorData.x_axis = POSITIVE;
            else if (x < 0)
                currentSensorData.x_axis = NEGATIVE;
            if (y > 0)
                currentSensorData.y_axis = POSITIVE;
            else if (y < 0)
                currentSensorData.y_axis = NEGATIVE;
        }
        currentSensorData.lastSampleWasMoving = true;

        const qreal deltaTime = 1 / static_cast<qreal>(m_dataRate);

        // distance = (1/2 * abs(a) * t^2) + v0 * t
        qreal distanceX = qAbs(x) * 0.5 * deltaTime * deltaTime + currentSensorData.last_velocity_x * deltaTime;
        qreal distanceY = qAbs(y) * 0.5 * deltaTime * deltaTime + currentSensorData.last_velocity_y * deltaTime;

        if (currentSensorData.x_axis == NEGATIVE)
            currentSensorData.distanceMovedX -= distanceX;
        else
            currentSensorData.distanceMovedX += distanceX;

        if (currentSensorData.y_axis == NEGATIVE)
            currentSensorData.distanceMovedY -= distanceY;
        else
            currentSensorData.distanceMovedY += distanceY;

        // v = a * t + v0
        currentSensorData.last_velocity_x = qAbs(x) * deltaTime + currentSensorData.last_velocity_x;
        currentSensorData.last_velocity_y = qAbs(y) * deltaTime + currentSensorData.last_velocity_y;
        sendCurrentLoacationData();
    }
}



// Process accelerometer data
void Processor::processAccelerometerData(qreal x, qreal y, qreal z)
{
    if (currentSensorData.accelerometerSampleNumber < ACCELEROMETER_SAMPLE_NUM) {
        calibrateAccelerometer(x, y, z);
        emit accelerometerDataProcessed(QString("[Calibrating accelerometer]\nSamples left for noise removal: %1")
                                        .arg(ACCELEROMETER_SAMPLE_NUM - currentSensorData.accelerometerSampleNumber));
        return;
    }

    qreal filteredAccelerometerX = filterAccelerometerData(x, currentSensorData.averageAccelerometerX);
    qreal filteredAccelerometerY = filterAccelerometerData(y, currentSensorData.averageAccelerometerY);
    qreal filteredAccelerometerZ = filterAccelerometerData(z, currentSensorData.averageAccelerometerZ);

    // Create measurement vector
    // Eigen::VectorXd measurement(3);
    // measurement << filteredAccelerometerX, filteredAccelerometerY, filteredAccelerometerZ;

    // /// Update Kalman filter with measurement
    // kalmanFilter->update(measurement);

    // // Get filtered values from Kalman filter
    // Eigen::VectorXd filteredState = kalmanFilter->state();

    // Update position with filtered values (assuming updatePosition accepts x, y, z)

    // updatePosition(filteredState(0), filteredState(1));
    updatePosition(filteredAccelerometerX, filteredAccelerometerY);

    QString result = QString("Accelerometer: X: %1, Y: %2, Z: %3")
                    .arg(filteredAccelerometerX, 0, 'f', 3)
                    .arg(filteredAccelerometerY, 0, 'f', 3)
                    .arg(filteredAccelerometerZ, 0, 'f', 3);

    emit accelerometerDataProcessed(result);
}



void Processor::calibrateGyroscope(qreal x, qreal y, qreal z)
{
    // calibrate gyroscope
    currentSensorData.averageGyroscopeX = (currentSensorData.averageGyroscopeX * currentSensorData.gyroscopeSampleNumber + x) / (currentSensorData.gyroscopeSampleNumber + 1);
    currentSensorData.averageGyroscopeY = (currentSensorData.averageGyroscopeY * currentSensorData.gyroscopeSampleNumber + y) / (currentSensorData.gyroscopeSampleNumber + 1);
    currentSensorData.averageGyroscopeZ = (currentSensorData.averageGyroscopeZ * currentSensorData.gyroscopeSampleNumber + z) / (currentSensorData.gyroscopeSampleNumber + 1);
    currentSensorData.gyroscopeSampleNumber++;
}

void Processor::updateAngle()
{
    qreal newAngleZ = currentSensorData.angleZ + currentPath.angle;
    
    qreal pathAngle = currentPath.angle;
    // if currentPath.angle has changed, then currentSensorData.angleZ should be 0
    
    // if angleZ is between 0 and 45, angle is 0. if angleZ is between 45 and 135, angle is 90. if angleZ is between 135 and 225, angle is 180. if angleZ is between 225 and 315, angle is 270. if angleZ is between 315 and 360, angle is 0
    // if angleZ is between 0 and -45, angle is 0. if angleZ is between -45 and -135, angle is -90. if angleZ is between -135 and -225, angle is -180. if angleZ is between -225 and -315, angle is -270. if angleZ is between -315 and -360, angle is 0
    if (newAngleZ >= 0 && newAngleZ < 45 || newAngleZ >= 315 && newAngleZ < 360) {
        currentPath.angle = 0;
    } else if (newAngleZ >= 45 && newAngleZ < 135) {
        currentPath.angle = 90;
    } else if (newAngleZ >= 135 && newAngleZ < 225) {
        currentPath.angle = 180;
    } else if (newAngleZ >= 225 && newAngleZ < 315) {
        currentPath.angle = 270;
    } else if (newAngleZ >= -45 && newAngleZ < 0 || newAngleZ >= -360 && newAngleZ < -315) {
        currentPath.angle = 0;
    } else if (newAngleZ >= -135 && newAngleZ < -45) {
        currentPath.angle = -90;
    } else if (newAngleZ >= -225 && newAngleZ < -135) {
        currentPath.angle = -180;
    } else if (newAngleZ >= -315 && newAngleZ < -225) {
        currentPath.angle = -270;
    }

    if (currentPath.angle != pathAngle)
        currentSensorData.angleZ = 0;
}

qreal radToDeg(qreal radians) {
    return radians * (180.0 / M_PI);
}

// Function to calculate rotation angle from angular velocity
qreal calculateRotationAngle(qreal angularVelocity, qreal timeInterval) {
    return angularVelocity * timeInterval;
}


void Processor::processGyroscopeData(qreal x, qreal y, qreal z)
{
    // define threshold in degrees
    const qreal GYRO_THRESHOLD = 20;
    // in gyroscope only z axis is used to determine the angle
    // calibrate gyroscope
    if (currentSensorData.gyroscopeSampleNumber < GYROSCOPE_SAMPLE_NUM) {
        calibrateGyroscope(x, y, z);
        // Emit the message to show the number of samples left to remove noise
        emit gyroscopeDataProcessed(QString("[Calibrating gyroscope]\nSamples left for noise removal: %1")
                                    .arg(GYROSCOPE_SAMPLE_NUM - currentSensorData.gyroscopeSampleNumber));
        return;
    }

    // convert angular velocity to angle
    qreal angularVelocity = z - currentSensorData.averageGyroscopeZ;

    angularVelocity = angularVelocity < GYRO_THRESHOLD && angularVelocity > -GYRO_THRESHOLD ? 0 : angularVelocity;

    
    qreal rotationAngle = calculateRotationAngle(angularVelocity, 1.0 / static_cast<qreal>(GYRO_DATA_RATE));

    // rotationAngle = rotationAngle <GYRO_THRESHOLD && rotationAngle > -GYRO_THRESHOLD ? 0 : rotationAngle;

    // kalman filter
    // Create measurement vector
    // Eigen::VectorXd measurement(3);
    // measurement << 0, 0, rotationAngle;

    // /// Update Kalman filter with measurement
    // kalmanFilter->update(measurement);

    // // Get filtered values from Kalman filter
    // Eigen::VectorXd filteredState = kalmanFilter->state();

    // // update rotationAngle
    // rotationAngle = filteredState(2);

    // if rotationAngleDeg was not zero, then disable accelerometer
    if (angularVelocity == 0){
        if (currentSensorData.zeroVelocityNum > 10){
            emit accelSensorEnabled();
        }
        currentSensorData.zeroVelocityNum++;
        // emit accelSensorEnabled();
    }
    else {
        emit accelSensorDisabled();
        currentSensorData.zeroVelocityNum = 0;
        currentSensorData.lastSampleWasMoving = false;
        currentSensorData.distanceMovedX = 0;
        currentSensorData.distanceMovedY = 0;
        // qDebug() << "Gyroscope Z:  " << rotationAngle << "raw Z:  " << angularVelocity;
    }
        
    // update angleZ
    // currentSensorData.angleZ += rotationAngle;
    currentSensorData.angleZ += rotationAngle;

    // calculate angle. angle can be 0,90,180,270, -90, -180, -270
    updateAngle();

    // Send the processed data to the GUI. only first 3 digits are shown
    QString result = QString("Gyroscope: Z: %1")
                    .arg(rotationAngle, 0, 'f', 3);



    // Emit the processed data
    emit gyroscopeDataProcessed(result);
}


void Processor::savePattern()
{
    // copy newPathVector to patternVector
    for (const Path& path : newPathVector) {
        patternVector.append(path); // Push a copy of each Path object
    }

    qDebug() << "Pattern saved!";

    // emit the pattern in json format
    QString result = "[Path]\n";
    for (int i = 0; i < newPathVector.size(); i++) {
        result += QString("startX: %1, startY: %2, endX: %3, endY: %4, direction: %5, angle: %6\n")
                  .arg(newPathVector[i].startX, 0, 'f', 3)
                  .arg(newPathVector[i].startY, 0, 'f', 3)
                  .arg(newPathVector[i].endX, 0, 'f', 3)
                  .arg(newPathVector[i].endY, 0, 'f', 3)
                  .arg(newPathVector[i].direction)
                  .arg(newPathVector[i].angle);
    }
    emit patternSaved(result);
}


void Processor::startCapturing()
{
    // Reset the total sample number
    totalSampleNumber = 0;
    // Reset the current sensor data
    currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, ZERO, ZERO};
    // Reset the current path
    currentPath = {0, 0, 0, 0, "", 0};
    // Reset the new path vector
    newPathVector.clear();
}

void Processor::checkPatternMatch(const QVariant &pattern)
{
    // Convert new path vector to JSON format and emit the pattern
    QString inputPattern = "[Path]\n";
    for (const auto& path : newPathVector) {
        inputPattern += QString("startX: %1, startY: %2, endX: %3, endY: %4, direction: %5, angle: %6\n")
                        .arg(path.startX, 0, 'f', 3)
                        .arg(path.startY, 0, 'f', 3)
                        .arg(path.endX, 0, 'f', 3)
                        .arg(path.endY, 0, 'f', 3)
                        .arg(path.direction)
                        .arg(path.angle);
    }
    emit patternSaved(inputPattern);

    // Check if the newPathVector matches the pattern with a threshold of 0.2
    bool match = true;

    // Convert the QVariant to a QVariantList
    QVariantList patternList = pattern.toList();

    // Check if the sizes of the two vectors are the same
    if (newPathVector.size() != patternList.size()) {
        emit patternMatched("Pattern not matched");
        return;
    }

    // Check if the two vectors match
    for (int i = 0; i < newPathVector.size(); ++i) {
        QVariantMap newPathMap;
        newPathMap["startX"] = newPathVector[i].startX;
        newPathMap["startY"] = newPathVector[i].startY;
        newPathMap["endX"] = newPathVector[i].endX;
        newPathMap["endY"] = newPathVector[i].endY;
        newPathMap["direction"] = newPathVector[i].direction;
        newPathMap["angle"] = newPathVector[i].angle;

        QVariantMap patternMap = patternList[i].toMap();
        if (qAbs(newPathMap["startX"].toDouble() - patternMap["startX"].toDouble()) > PATTERN_MATCH_THRESHOLD ||
            qAbs(newPathMap["startY"].toDouble() - patternMap["startY"].toDouble()) > PATTERN_MATCH_THRESHOLD ||
            qAbs(newPathMap["endX"].toDouble() - patternMap["endX"].toDouble()) > PATTERN_MATCH_THRESHOLD ||
            qAbs(newPathMap["endY"].toDouble() - patternMap["endY"].toDouble()) > PATTERN_MATCH_THRESHOLD ||
            newPathMap["direction"].toString() != patternMap["direction"].toString() ||
            qAbs(newPathMap["angle"].toDouble() - patternMap["angle"].toDouble()) > 45) {
            match = false;
            break;
        }
    }

    // Emit the result
    emit patternMatched(match ? "Pattern matched" : "Pattern not matched");
}



// void Processor::checkPatternMatch() {
//     // check if newPathVector matches the patternVector with a threshold of 0.2
//     bool match = true;

//     if (newPathVector.size() != patternVector.size()) {
//         emit patternMatched("Pattern not matched");
//         return;
//     }

//     for (int i = 0; i < newPathVector.size(); i++) {
//         if (qAbs(newPathVector[i].startX - patternVector[i].startX) > PATTERN_MATCH_THRESHOLD) {
//             match = false;
//         }
//         if (qAbs(newPathVector[i].startY - patternVector[i].startY) > PATTERN_MATCH_THRESHOLD) {
//             match = false;
//         }
//         if (qAbs(newPathVector[i].endX - patternVector[i].endX) > PATTERN_MATCH_THRESHOLD) {
//             match = false;
//         }
//         if (qAbs(newPathVector[i].endY - patternVector[i].endY) > PATTERN_MATCH_THRESHOLD) {
//             match = false;
//         }
//         if (newPathVector[i].direction != patternVector[i].direction) {
//             match = false;
//         }
//         if (qAbs(newPathVector[i].angle - patternVector[i].angle) > 45) {
//             match = false;
//         }
//         if (!match)
//             break;
//     }

//     if (match) {
//         emit patternMatched("Pattern matched");
//     }
//     else {
//         emit patternMatched("Pattern not matched");
//     }

// }


