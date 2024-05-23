#include "processor.h"
#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QDir>

// define number of samples for removing noise from accelerometer data
#define ACCELEROMETER_SAMPLE_NUM 20
#define GYROSCOPE_SAMPLE_NUM 20
#define DATA_RATE 5
#define THRESHOLD 0.3
#define PATTERN_MATCH_THRESHOLD 0.2

Processor::Processor(QObject *parent) 
            : QObject(parent),
            m_dataRate(DATA_RATE)
{
    // Initialize the processor
    
    totalSampleNumber = 0;
    currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, ZERO, ZERO};
    currentPath = {0, 0, 0, 0, "", 0};
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
    currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, ZERO, ZERO};
}

void Processor::updateDirection()
{
    if (currentSensorData.x_axis == POSITIVE) {
        if (currentSensorData.y_axis == POSITIVE) {
            if (currentPath.angle > 0) {
                currentPath.direction = "up";
            }
            else {
                currentPath.direction = "right";
            }
        }
        else if (currentSensorData.y_axis == NEGATIVE) {
            if (currentPath.angle > 0) {
                currentPath.direction = "down";
            }
            else {
                currentPath.direction = "right";
            }
        }
        else {
            currentPath.direction = "right";
        }
    }
    else if (currentSensorData.x_axis == NEGATIVE) {
        if (currentSensorData.y_axis == POSITIVE) {
            if (currentPath.angle > 0) {
                currentPath.direction = "up";
            }
            else {
                currentPath.direction = "left";
            }
        }
        else if (currentSensorData.y_axis == NEGATIVE) {
            if (currentPath.angle > 0) {
                currentPath.direction = "down";
            }
            else {
                currentPath.direction = "left";
            }
        }
        else {
            currentPath.direction = "left";
        }
    }
    else {
        if (currentSensorData.y_axis == POSITIVE) {
            currentPath.direction = "up";
        }
        else if (currentSensorData.y_axis == NEGATIVE) {
            currentPath.direction = "down";
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
    newPathVector.push_back(currentPath);
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

void Processor::updatePosition(qreal x, qreal y)
{
    if (x == 0 && y == 0) {
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
            // emit pathDataProcessed(QString("DistanceX: %1, DistanceY: %2, direction: %3, angle: %4")
            //                         .arg(currentSensorData.distanceMovedX)
            //                         .arg(currentSensorData.distanceMovedY)
            //                         .arg(currentPath.direction)
            //                         .arg(currentPath.angle));
                                    

            // update currentPath
            currentPath.direction = "";
            currentPath.startY = currentPath.endY;
            currentPath.startX = currentPath.endX;

            // reset currentSensorData
            currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, ZERO, ZERO};
        }
        return;
    }
    else {
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
        currentSensorData.distanceMovedX += qAbs(x) * 0.5 * deltaTime * deltaTime + currentSensorData.last_velocity_x * deltaTime;
        currentSensorData.distanceMovedY += qAbs(y) * 0.5 * deltaTime * deltaTime + currentSensorData.last_velocity_y * deltaTime;

        // v = a * t + v0
        currentSensorData.last_velocity_x += qAbs(x) * deltaTime + currentSensorData.last_velocity_x;
        currentSensorData.last_velocity_y += qAbs(y) * deltaTime + currentSensorData.last_velocity_y;

        sendCurrentLoacationData();
    }
}


void Processor::processAccelerometerData(qreal x, qreal y, qreal z)
{

    // calibrate accelerometer
    if (currentSensorData.accelerometerSampleNumber < ACCELEROMETER_SAMPLE_NUM) {
        calibrateAccelerometer(x, y, z);
        // Emit the message to show the number of samples left to remove noise
        emit accelerometerDataProcessed(QString("[Calibrating accelerometer]\nSamples left for noise removal: %1")
                                        .arg(ACCELEROMETER_SAMPLE_NUM - currentSensorData.accelerometerSampleNumber));
        return;
    }

    qreal filteredAccelerometerX = filterAccelerometerData(x, currentSensorData.averageAccelerometerX);
    qreal filteredAccelerometerY = filterAccelerometerData(y, currentSensorData.averageAccelerometerY);
    qreal filteredAccelerometerZ = filterAccelerometerData(z, currentSensorData.averageAccelerometerZ);

    updatePosition(filteredAccelerometerX, filteredAccelerometerY);
        
    // Send the processed data to the GUI. only first 3 digits are shown
    QString result = QString("Accelerometer: X: %1, Y: %2, Z: %3")
                    .arg(filteredAccelerometerX, 0, 'f', 3)
                    .arg(filteredAccelerometerY, 0, 'f', 3)
                    .arg(filteredAccelerometerZ, 0, 'f', 3);

    // Emit the processed data
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

void Processor::updateAngle(qreal z)
{
    currentPath.angle = z;
}

void Processor::processGyroscopeData(qreal x, qreal y, qreal z)
{
    // in gyroscope only z axis is used to determine the angle
    // calibrate gyroscope
    if (currentSensorData.gyroscopeSampleNumber < GYROSCOPE_SAMPLE_NUM) {
        calibrateGyroscope(x, y, z);
        // Emit the message to show the number of samples left to remove noise
        emit gyroscopeDataProcessed(QString("[Calibrating gyroscope]\nSamples left for noise removal: %1")
                                    .arg(GYROSCOPE_SAMPLE_NUM - currentSensorData.gyroscopeSampleNumber));
        return;
    }

    // Subtract the average to remove bias
    qreal filteredGyroscopeZ = z - currentSensorData.averageGyroscopeZ;

    const qreal GYROSCOPE_THRESHOLD = 0.2;

    // Apply threshold to filter out noise
    filteredGyroscopeZ = filteredGyroscopeZ < GYROSCOPE_THRESHOLD && filteredGyroscopeZ > -GYROSCOPE_THRESHOLD ? 0 : filteredGyroscopeZ;

    // calculate angle. angle can be 0,90,180,270, -90, -180, -270
    updateAngle(filteredGyroscopeZ);

    // Send the processed data to the GUI. only first 3 digits are shown
    QString result = QString("Gyroscope: Z: %1")
                    .arg(filteredGyroscopeZ, 0, 'f', 3);

    // Emit the processed data
    emit gyroscopeDataProcessed(result);
}


void Processor::savePattern()
{
    // Save the pattern to a json file
    // The file name is the current date and time
    // save it in the saved-pattern directory under the current directory

    // copy newPathVector to patternVector
    for (const Path& path : newPathVector) {
        patternVector.push_back(path); // Push a copy of each Path object
    }

    // delete all files under the current directory
    QDir dir("saved-pattern");
    dir.setNameFilters(QStringList() << "*.json");
    dir.setFilter(QDir::Files);
    foreach (QString dirFile, dir.entryList()) {
        dir.remove(dirFile);
    }

    // Create a new file
    QString fileName = QDateTime::currentDateTime().toString("yyyy-MM-dd-hh-mm-ss") + ".json";
    QString filePath = "saved-pattern/" + fileName;
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qDebug() << "Error: Cannot open file for writing";
        return;
    }

    // Write the pattern to the file
    QTextStream out(&file);
    out << "{\n";
    out << "  \"pattern\": [\n";
    for (int i = 0; i < newPathVector.size(); i++) {
        out << "    {\n";
        out << "      \"startX\": " << newPathVector[i].startX << ",\n";
        out << "      \"startY\": " << newPathVector[i].startY << ",\n";
        out << "      \"endX\": " << newPathVector[i].endX << ",\n";
        out << "      \"endY\": " << newPathVector[i].endY << ",\n";
        out << "      \"direction\": \"" << newPathVector[i].direction << "\",\n";
        out << "      \"angle\": " << newPathVector[i].angle << "\n";
        out << "    }";
        if (i != newPathVector.size() - 1) {
            out << ",";
        }
        out << "\n";
    }
    out << "  ]\n";
    out << "}\n";

    // Close the file
    file.close();

    qDebug() << "Pattern saved to " << filePath;
}


void Processor::startCapturing()
{
    // Start capturing the data
    // Reset the total sample number
    totalSampleNumber = 0;
    // Reset the current sensor data
    currentSensorData = {0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, ZERO, ZERO};
    // Reset the current path
    currentPath = {0, 0, 0, 0, "", 0};
    // Reset the new path vector
    newPathVector.clear();
}


void Processor::checkPatternMatch() {
    // check if newPathVector matches the patternVector with a threshold of 0.2
    bool match = true;

    if (newPathVector.size() != patternVector.size()) {
        emit patternMatched("Pattern not matched");
        return;
    }

    for (int i = 0; i < newPathVector.size(); i++) {
        if (qAbs(newPathVector[i].startX - patternVector[i].startX) > PATTERN_MATCH_THRESHOLD) {
            match = false;
        }
        if (qAbs(newPathVector[i].startY - patternVector[i].startY) > PATTERN_MATCH_THRESHOLD) {
            match = false;
        }
        if (qAbs(newPathVector[i].endX - patternVector[i].endX) > PATTERN_MATCH_THRESHOLD) {
            match = false;
        }
        if (qAbs(newPathVector[i].endY - patternVector[i].endY) > PATTERN_MATCH_THRESHOLD) {
            match = false;
        }
        if (newPathVector[i].direction != patternVector[i].direction) {
            match = false;
        }
        if (qAbs(newPathVector[i].angle - patternVector[i].angle) > 45) {
            match = false;
        }
        if (!match)
            break;
    }

    if (match) {
        emit patternMatched("Pattern matched");
    }
    else {
        emit patternMatched("Pattern not matched");
    }

}


