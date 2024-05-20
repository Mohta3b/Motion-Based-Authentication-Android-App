#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <QObject>
#include <QQmlEngine>

class Processor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit Processor(QObject *parent = nullptr);

signals:
    void accelerometerDataProcessed(QString result);

public slots:
    void processAccelerometerData(double x, double y, double z);
    void processGyroscopeData(double x, double y, double z);
};

#endif // PROCESSOR_H
