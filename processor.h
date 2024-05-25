#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <QObject>
#include <QQmlEngine>
#include "kalmanfilter.h"

struct Path {
    qreal startX;
    qreal startY;
    qreal endX;
    qreal endY;
    QString direction;
    qreal angle;
};

enum Direction {ZERO, POSITIVE, NEGATIVE};
struct sensorData {
    int accelerometerSampleNumber, gyroscopeSampleNumber;
    qreal averageAccelerometerX, averageAccelerometerY, averageAccelerometerZ;
    qreal averageGyroscopeX, averageGyroscopeY, averageGyroscopeZ;
    qreal distanceMovedX, distanceMovedY;
    qreal angleZ;
    qreal zeroVelocityNum;
    bool lastSampleWasMoving;
    qreal last_velocity_x, last_velocity_y;
    Direction x_axis;
    Direction y_axis;
};

class Processor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int dataRate READ dataRate WRITE setDataRate NOTIFY dataRateChanged)
public:
    explicit Processor(QObject *parent = nullptr);

    

    int dataRate() const { return m_dataRate; }
    void setDataRate(int dataRate) { m_dataRate = dataRate; emit dataRateChanged(); }
    // void saveNewPath();
    void updatePosition(qreal x, qreal y);
    void calibrateAccelerometer(qreal x, qreal y, qreal z);
    qreal filterAccelerometerData(qreal data, qreal average);
    void processPathData();
    void calibrateGyroscope(qreal x, qreal y, qreal z);
    void updateAngle();
    void updateDirection();
    void sendCurrentLoacationData();

signals:
    void accelerometerDataProcessed(const QString &result);
    void gyroscopeDataProcessed(const QString &result);
    void pathDataProcessed(const QString &result);
    void locationDataProcessed(const QString &result);
    void patternMatched(const QString &result);
    void patternSaved(const QString &result);
    void dataRateChanged();
    void gyroSensorEnabled();
    void gyroSensorDisabled();
    void accelSensorEnabled();
    void accelSensorDisabled();

public slots:
    void processAccelerometerData(qreal x, qreal y, qreal z);
    void processGyroscopeData(qreal x, qreal y, qreal z);
    void defineNewPattern();
    void savePattern();
    void startCapturing();
    void checkPatternMatch(const QVariant &pattern);

private:
    int m_dataRate;

    long long totalSampleNumber;

    sensorData currentSensorData;

    Path currentPath;

    // vector to store path
    QVector<Path> newPathVector;

    // vector to store pattern
    QVector<Path> patternVector;

    KalmanFilter *kalmanFilter;

};



#endif // PROCESSOR_H
