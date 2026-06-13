#include <QApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <QFontDatabase>
#include <QDir>
#include <cstdlib>
#include <windows.h>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QActionGroup>
#include <QQuickWindow>
#include <QStyle>
#include <QMessageBox>
#include <QQmlContext>
#include <QComboBox>
#include <QSettings>
#include "csesparser.h"
#include "settingsdialog.h"
#include "scheduleeditor.h"
#include "classswapdialog.h"

extern "C" {
    unsigned long __stack_chk_guard = 0xDEADBEEFUL;
    __attribute__((noreturn)) void __stack_chk_fail(void) {
        std::abort();
    }
}

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORM", "windows");
    QApplication app(argc, argv);

    HANDLE hMutex = CreateMutexW(NULL, TRUE, L"ClassBoard_SingleInstance_Mutex");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        QMessageBox::warning(nullptr, "ClassBoard", "已有程序正在运行，请勿重复启动。");
        app.processEvents();
        return 0;
    }

    CsesParser csesParser;
    
    // 注册 MiSans 字体
    QFontDatabase::addApplicationFont("D:/NEO ClassBoard/MiSans/MiSans/ttf/MiSans-Regular.ttf");
    QFontDatabase::addApplicationFont("D:/NEO ClassBoard/MiSans/MiSans/ttf/MiSans-Bold.ttf");
    QFontDatabase::addApplicationFont("D:/NEO ClassBoard/MiSans/MiSans/ttf/MiSans-Medium.ttf");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("csesParser", &csesParser);
    engine.addImportPath("qrc:/qt/qml");

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() {
                         qCritical() << "QML object creation failed!";
                         QCoreApplication::exit(-1);
                     },
                     Qt::QueuedConnection);

    const QUrl url(QStringLiteral("qrc:/ClassBoard/main.qml"));
    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects after loading QML!";
        return -1;
    }

    QQuickWindow *mainWindow = qobject_cast<QQuickWindow *>(engine.rootObjects().first());

    if (csesParser.hasPendingSwaps()) {
        int ret = QMessageBox::question(nullptr, "换课恢复",
            "检测到今天有换课记录:\n" + csesParser.swapsSummary() + "\n\n是否继续使用？",
            QMessageBox::Yes | QMessageBox::No);
        if (ret == QMessageBox::No) {
            csesParser.clearSwaps();
        }
    }

    QSystemTrayIcon *trayIcon = new QSystemTrayIcon(&app);
    trayIcon->setIcon(app.style()->standardIcon(QStyle::SP_ComputerIcon));
    trayIcon->setToolTip("NEO ClassBoard");
    trayIcon->setVisible(true);

    QMenu *trayMenu = new QMenu();
    QAction *actShow = trayMenu->addAction("显示/隐藏");
    QAction *actSettings = trayMenu->addAction("设置");
    QAction *actEditor = trayMenu->addAction("课表编辑器");
    QMenu *rescheduleMenu = trayMenu->addMenu("调休日");
    QActionGroup *rescheduleGroup = new QActionGroup(rescheduleMenu);
    QAction *actRescheduleNone = rescheduleMenu->addAction("不调休");
    actRescheduleNone->setCheckable(true);
    actRescheduleNone->setChecked(true);
    rescheduleGroup->addAction(actRescheduleNone);
    QStringList dayNames = {"", "周一", "周二", "周三", "周四", "周五", "周六", "周日"};
    for (int d = 1; d <= 7; d++) {
        QAction *act = rescheduleMenu->addAction(dayNames[d]);
        act->setCheckable(true);
        act->setData(d);
        rescheduleGroup->addAction(act);
    }
    trayMenu->addSeparator();
    QAction *actQuit = trayMenu->addAction("退出");
    trayIcon->setContextMenu(trayMenu);

    QObject::connect(actShow, &QAction::triggered, mainWindow, [mainWindow]() {
        if (mainWindow->isVisible())
            mainWindow->hide();
        else
            mainWindow->show();
    });

    QObject::connect(actSettings, &QAction::triggered, &csesParser, [&csesParser]() {
        SettingsDialog *dlg = new SettingsDialog(csesParser);
        dlg->setAttribute(Qt::WA_DeleteOnClose);
        dlg->show();
    });

    QObject::connect(actEditor, &QAction::triggered, &csesParser, [&csesParser]() {
        ScheduleEditor *dlg = new ScheduleEditor(csesParser);
        dlg->setAttribute(Qt::WA_DeleteOnClose);
        dlg->show();
    });

    QObject::connect(rescheduleGroup, &QActionGroup::triggered, &csesParser, [&csesParser](QAction *act) {
        int day = act->data().toInt();
        csesParser.setRescheduleDay(day);
    });

    QAction *actSwap = trayMenu->addAction("换课");
    QObject::connect(actSwap, &QAction::triggered, &csesParser, [&csesParser]() {
        ClassSwapDialog *dlg = new ClassSwapDialog(csesParser);
        dlg->setAttribute(Qt::WA_DeleteOnClose);
        dlg->show();
    });

    QObject::connect(actQuit, &QAction::triggered, &app, &QApplication::quit);

    QObject::connect(trayIcon, &QSystemTrayIcon::activated,
        trayIcon, [mainWindow](QSystemTrayIcon::ActivationReason reason) {
            if (reason == QSystemTrayIcon::Trigger) {
                if (mainWindow->isVisible())
                    mainWindow->hide();
                else
                    mainWindow->show();
            }
        });

    return app.exec();
}
