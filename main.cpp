// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
// #include <QGuiApplication>
// #include <QQmlApplicationEngine>

// int main(int argc, char *argv[])
// {
//     QGuiApplication app(argc,argv);
//     QGuiApplication::setOrganizationName("C-PASS");
//     QGuiApplication::setApplicationName("Motion Based Authentication");

//     QQmlApplicationEngine engine;
//     engine.loadFromModule("SensorShowcaseModule", "Main");
//     if (engine.rootObjects().isEmpty())
//         return -1;

//     return app.exec();
// }


#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "processor.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc,argv);
    QGuiApplication::setOrganizationName("C-PASS");
    QGuiApplication::setApplicationName("Motion Based Authentication");

    QQmlApplicationEngine engine;

    Processor processor;
    engine.rootContext()->setContextProperty("processor", &processor);

    engine.loadFromModule("SensorShowcaseModule", "Main");
        if (engine.rootObjects().isEmpty())
            return -1;

    return app.exec();


}

// const QUrl url(u"qrc:/Main.qml"_qs);
// QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
//     &app, [url](QObject *obj, const QUrl &objUrl) {
//         if (!obj && url == objUrl)
//             QCoreApplication::exit(-1);
//     }, Qt::QueuedConnection);
// engine.load(url);

// return app.exec();
