#include "processor.h"

Processor::Processor(QObject *parent) : QObject(parent)
{
}

void Processor::processAccelerometerData(double x, double y, double z)
{
    // Process accelerometer data here
    QString result = QString("X: %1, Y: %2, Z: %3").arg(x).arg(y).arg(z);

    // Emit the processed data
    emit accelerometerDataProcessed(result);
}

void Processor::processGyroscopeData(double x, double y, double z)
{
    // Process gyroscope data here
    QString result = QString("X: %1, Y: %2, Z: %3").arg(x).arg(y).arg(z);

    // Emit the processed data
    emit gyroscopeDataProcessed(result);
}