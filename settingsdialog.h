#ifndef SETTINGSDIALOG_H
#define SETTINGSDIALOG_H

#include <QDialog>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QFrame>
#include <QFileDialog>
#include <QMessageBox>
#include <QSpinBox>
#include <QCheckBox>
#include <QSettings>
#include <QCoreApplication>
#include <QSlider>
#include <QFontDatabase>
#include <QFontComboBox>
#include <QStackedWidget>
#include <QScrollArea>
#include <QFileInfo>
#include "csesparser.h"

class SettingsDialog : public QDialog
{
    Q_OBJECT

public:
    explicit SettingsDialog(CsesParser &parser, QWidget *parent = nullptr)
        : QDialog(parent), m_parser(parser), m_currentPage(0)
    {
        setWindowTitle("设置");
        setFixedSize(600, 520);
        setStyleSheet(
            "QDialog { background-color: #FEF7FF; }"
            "QLabel { color: #1C1B1F; font-size: 14px; }"
        );

        QHBoxLayout *mainLayout = new QHBoxLayout(this);
        mainLayout->setContentsMargins(0, 0, 0, 0);
        mainLayout->setSpacing(0);

        mainLayout->addWidget(createNavPanel());
        mainLayout->addWidget(createContentPanel(), 1);
    }

private:
    CsesParser &m_parser;
    int m_currentPage;
    QStackedWidget *m_contentStack;
    QList<QPushButton*> m_navBtns;
    QLabel *m_pathLabel;

    static constexpr int PAGE_COUNT = 5;

    void switchPage(int index) {
        m_currentPage = index;
        m_contentStack->setCurrentIndex(index);
        for (int i = 0; i < m_navBtns.size(); i++) {
            m_navBtns[i]->setStyleSheet(i == index ?
                "QPushButton { background-color: #E8DEF8; color: #6750A4; border: none; "
                "border-radius: 12px; font-size: 11px; font-weight: bold; }" :
                "QPushButton { background-color: transparent; color: #49454F; border: none; "
                "border-radius: 12px; font-size: 11px; font-weight: bold; }"
                "QPushButton:hover { background-color: #E8DEF8; }");
        }
    }

    QWidget* createNavPanel() {
        QWidget *nav = new QWidget;
        nav->setFixedWidth(72);
        nav->setStyleSheet("background-color: #F3EDF7;");

        QVBoxLayout *layout = new QVBoxLayout(nav);
        layout->setContentsMargins(4, 16, 4, 16);
        layout->setSpacing(4);

        QStringList labels = {"课表", "外观", "行为", "通知", "关于"};
        QStringList icons = {"S", "P", "B", "N", "i"};
        for (int i = 0; i < PAGE_COUNT; i++) {
            QPushButton *btn = new QPushButton(icons[i] + "\n" + labels[i]);
            btn->setFixedSize(64, 48);
            btn->setStyleSheet(i == 0 ?
                "QPushButton { background-color: #E8DEF8; color: #6750A4; border: none; "
                "border-radius: 12px; font-size: 11px; font-weight: bold; }" :
                "QPushButton { background-color: transparent; color: #49454F; border: none; "
                "border-radius: 12px; font-size: 11px; font-weight: bold; }"
                "QPushButton:hover { background-color: #E8DEF8; }");
            connect(btn, &QPushButton::clicked, this, [this, i]() { switchPage(i); });
            layout->addWidget(btn);
            m_navBtns.append(btn);
        }
        layout->addStretch();

        return nav;
    }

    QWidget* createContentPanel() {
        QWidget *panel = new QWidget;
        panel->setStyleSheet("background-color: #FEF7FF;");

        QVBoxLayout *outerLayout = new QVBoxLayout(panel);
        outerLayout->setContentsMargins(0, 0, 0, 0);

        m_contentStack = new QStackedWidget;
        m_contentStack->addWidget(wrapScroll(createSchedulePage()));
        m_contentStack->addWidget(wrapScroll(createAppearancePage()));
        m_contentStack->addWidget(wrapScroll(createBehaviorPage()));
        m_contentStack->addWidget(wrapScroll(createNotificationPage()));
        m_contentStack->addWidget(wrapScroll(createAboutPage()));

        outerLayout->addWidget(m_contentStack);
        return panel;
    }

    QScrollArea* wrapScroll(QWidget *content) {
        QScrollArea *area = new QScrollArea;
        area->setWidgetResizable(true);
        area->setWidget(content);
        area->setStyleSheet(
            "QScrollArea { border: none; background-color: #FEF7FF; }"
            "QScrollBar:vertical { width: 6px; background: transparent; }"
            "QScrollBar::handle:vertical { background: #CAC4D0; border-radius: 3px; min-height: 20px; }"
            "QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }"
        );
        return area;
    }

    QString cbStyle() {
        return "QCheckBox { font-size: 13px; color: #1C1B1F; spacing: 8px; }"
               "QCheckBox::indicator { width: 18px; height: 18px; border-radius: 4px; "
               "border: 2px solid #79747E; background: transparent; }"
               "QCheckBox::indicator:checked { background: #0B57D0; border-color: #0B57D0; }";
    }

    QString sliderStyle() {
        return "QSlider::groove:horizontal { height: 6px; background: #CAC4D0; border-radius: 3px; }"
               "QSlider::handle:horizontal { width: 18px; height: 18px; margin: -6px 0; "
               "background: #0B57D0; border-radius: 9px; }"
               "QSlider::sub-page:horizontal { background: #0B57D0; border-radius: 3px; }";
    }

    QString spinStyle() {
        return "QSpinBox { padding: 6px 10px; border: 1px solid #CAC4D0; border-radius: 8px; "
               "background: #F3EDF7; font-size: 13px; }";
    }

    QFrame* hsep() {
        QFrame *sep = new QFrame;
        sep->setFrameShape(QFrame::HLine);
        sep->setStyleSheet("background-color: #CAC4D0; max-height: 1px; border: none;");
        return sep;
    }

    QWidget* createSchedulePage() {
        QWidget *page = new QWidget;
        page->setStyleSheet("background-color: #FEF7FF;");

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(12);

        QLabel *title = new QLabel("课表设置");
        title->setStyleSheet("font-size: 22px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(title);
        layout->addWidget(hsep());

        QLabel *fileTitle = new QLabel("课表文件");
        fileTitle->setStyleSheet("font-size: 14px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(fileTitle);

        QHBoxLayout *fileRow = new QHBoxLayout;
        fileRow->setSpacing(12);
        m_pathLabel = new QLabel(m_parser.loaded() ? m_parser.filePath() : "未导入课表");
        m_pathLabel->setWordWrap(true);
        QString pathColor = m_parser.loaded() ? "#1C1B1F" : "#49454F";
        m_pathLabel->setStyleSheet(
            QString("background-color: #F3EDF7; color: %1; padding: 10px 12px; "
                    "border-radius: 12px; font-size: 13px;").arg(pathColor)
        );
        fileRow->addWidget(m_pathLabel, 1);
        QPushButton *importBtn = new QPushButton("导入");
        importBtn->setFixedSize(88, 40);
        importBtn->setStyleSheet(
            "QPushButton { background-color: #0B57D0; color: white; border: none; "
            "border-radius: 20px; font-size: 14px; font-weight: bold; }"
            "QPushButton:hover { background-color: #0842A0; }"
        );
        fileRow->addWidget(importBtn);
        layout->addLayout(fileRow);

        layout->addWidget(hsep());

        QLabel *timeTitle = new QLabel("时间设置");
        timeTitle->setStyleSheet("font-size: 14px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(timeTitle);

        QHBoxLayout *offsetRow = new QHBoxLayout;
        offsetRow->setSpacing(8);
        offsetRow->addWidget(new QLabel("时间偏移(分钟):"));
        QSpinBox *offsetSpin = new QSpinBox;
        offsetSpin->setRange(-60, 60);
        offsetSpin->setValue(m_parser.timeOffset());
        offsetSpin->setStyleSheet(spinStyle());
        offsetRow->addWidget(offsetSpin);
        layout->addLayout(offsetRow);

        QHBoxLayout *prepRow = new QHBoxLayout;
        prepRow->setSpacing(8);
        prepRow->addWidget(new QLabel("预备铃提前(分钟):"));
        QSpinBox *prepSpin = new QSpinBox;
        prepSpin->setRange(0, 10);
        prepSpin->setValue(m_parser.preparationTime());
        prepSpin->setStyleSheet(spinStyle());
        prepRow->addWidget(prepSpin);
        layout->addLayout(prepRow);

        QHBoxLayout *weekRow = new QHBoxLayout;
        weekRow->setSpacing(8);
        weekRow->addWidget(new QLabel("当前周次:"));
        QSpinBox *weekSpin = new QSpinBox;
        weekSpin->setRange(0, 30);
        weekSpin->setValue(m_parser.currentWeek());
        weekSpin->setSpecialValueText("自动");
        weekSpin->setStyleSheet(spinStyle());
        weekRow->addWidget(weekSpin);
        layout->addLayout(weekRow);

        QCheckBox *autoStartCheck = new QCheckBox("开机自启");
        autoStartCheck->setStyleSheet(cbStyle());
        QSettings reg("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                       QSettings::NativeFormat);
        autoStartCheck->setChecked(reg.value("ClassBoard").isValid());
        layout->addWidget(autoStartCheck);

        layout->addStretch();

        connect(importBtn, &QPushButton::clicked, this, &SettingsDialog::onImport);
        connect(offsetSpin, QOverload<int>::of(&QSpinBox::valueChanged), &m_parser, [&p = m_parser](int val) { p.setTimeOffset(val); });
        connect(prepSpin, QOverload<int>::of(&QSpinBox::valueChanged), &m_parser, [&p = m_parser](int val) { p.setPreparationTime(val); });
        connect(weekSpin, QOverload<int>::of(&QSpinBox::valueChanged), &m_parser, [&p = m_parser](int val) { p.setCurrentWeek(val); });
        connect(autoStartCheck, &QCheckBox::toggled, this, [](bool checked) {
            QSettings r("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", QSettings::NativeFormat);
            if (checked) r.setValue("ClassBoard", QCoreApplication::applicationFilePath().replace('/', '\\'));
            else r.remove("ClassBoard");
        });

        return page;
    }

    QWidget* createAppearancePage() {
        QWidget *page = new QWidget;
        page->setStyleSheet("background-color: #FEF7FF;");

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(12);

        QLabel *title = new QLabel("外观设置");
        title->setStyleSheet("font-size: 22px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(title);
        layout->addWidget(hsep());

        QHBoxLayout *scaleRow = new QHBoxLayout;
        scaleRow->setSpacing(8);
        scaleRow->addWidget(new QLabel("缩放比例:"));
        QSlider *scaleSlider = new QSlider(Qt::Horizontal);
        scaleSlider->setRange(50, 200);
        scaleSlider->setValue(qRound(m_parser.widgetScale() * 100));
        scaleSlider->setStyleSheet(sliderStyle());
        scaleRow->addWidget(scaleSlider, 1);
        QLabel *scaleVal = new QLabel(QString::number(qRound(m_parser.widgetScale() * 100)) + "%");
        scaleVal->setStyleSheet("font-size: 12px; color: #49454F; min-width: 36px;");
        scaleRow->addWidget(scaleVal);
        layout->addLayout(scaleRow);

        QHBoxLayout *opacityRow = new QHBoxLayout;
        opacityRow->setSpacing(8);
        opacityRow->addWidget(new QLabel("不透明度:"));
        QSlider *opacitySlider = new QSlider(Qt::Horizontal);
        opacitySlider->setRange(20, 100);
        opacitySlider->setValue(qRound(m_parser.widgetOpacity() * 100));
        opacitySlider->setStyleSheet(sliderStyle());
        opacityRow->addWidget(opacitySlider, 1);
        QLabel *opacityVal = new QLabel(QString::number(qRound(m_parser.widgetOpacity() * 100)) + "%");
        opacityVal->setStyleSheet("font-size: 12px; color: #49454F; min-width: 36px;");
        opacityRow->addWidget(opacityVal);
        layout->addLayout(opacityRow);

        QHBoxLayout *fontRow = new QHBoxLayout;
        fontRow->setSpacing(8);
        fontRow->addWidget(new QLabel("字体:"));
        QFontComboBox *fontCombo = new QFontComboBox;
        fontCombo->setCurrentFont(QFont(m_parser.fontFamily()));
        fontCombo->setStyleSheet(
            "QFontComboBox { padding: 6px 10px; border: 1px solid #CAC4D0; border-radius: 8px; "
            "background: #F3EDF7; font-size: 13px; min-width: 180px; }"
        );
        fontRow->addWidget(fontCombo, 1);
        layout->addLayout(fontRow);

        layout->addStretch();

        connect(scaleSlider, &QSlider::valueChanged, &m_parser, [&p = m_parser, scaleVal](int val) {
            p.setWidgetScale(val / 100.0); scaleVal->setText(QString::number(val) + "%");
        });
        connect(opacitySlider, &QSlider::valueChanged, &m_parser, [&p = m_parser, opacityVal](int val) {
            p.setWidgetOpacity(val / 100.0); opacityVal->setText(QString::number(val) + "%");
        });
        connect(fontCombo, &QFontComboBox::currentFontChanged, &m_parser, [&p = m_parser](const QFont &font) {
            p.setFontFamily(font.family());
        });

        return page;
    }

    QWidget* createBehaviorPage() {
        QWidget *page = new QWidget;
        page->setStyleSheet("background-color: #FEF7FF;");

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(12);

        QLabel *title = new QLabel("行为设置");
        title->setStyleSheet("font-size: 22px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(title);
        layout->addWidget(hsep());

        QCheckBox *hideInClassCheck = new QCheckBox("上课时自动隐藏");
        hideInClassCheck->setChecked(m_parser.hideInClass());
        hideInClassCheck->setStyleSheet(cbStyle());
        layout->addWidget(hideInClassCheck);

        QCheckBox *miniModeCheck = new QCheckBox("迷你模式");
        miniModeCheck->setChecked(m_parser.miniMode());
        miniModeCheck->setStyleSheet(cbStyle());
        layout->addWidget(miniModeCheck);

        QCheckBox *hoverFadeCheck = new QCheckBox("悬停淡出");
        hoverFadeCheck->setChecked(m_parser.hoverFade());
        hoverFadeCheck->setStyleSheet(cbStyle());
        layout->addWidget(hoverFadeCheck);

        layout->addWidget(hsep());

        QLabel *autoHideTitle = new QLabel("自动隐藏");
        autoHideTitle->setStyleSheet("font-size: 14px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(autoHideTitle);

        QCheckBox *hideMaxCheck = new QCheckBox("窗口最大化时隐藏");
        hideMaxCheck->setChecked(m_parser.hideOnMaximized());
        hideMaxCheck->setStyleSheet(cbStyle());
        layout->addWidget(hideMaxCheck);

        QCheckBox *hideFullCheck = new QCheckBox("窗口全屏时隐藏");
        hideFullCheck->setChecked(m_parser.hideOnFullscreen());
        hideFullCheck->setStyleSheet(cbStyle());
        layout->addWidget(hideFullCheck);

        layout->addStretch();

        connect(hideInClassCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setHideInClass(val); });
        connect(miniModeCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setMiniMode(val); });
        connect(hoverFadeCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setHoverFade(val); });
        connect(hideMaxCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setHideOnMaximized(val); });
        connect(hideFullCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setHideOnFullscreen(val); });

        return page;
    }

    QWidget* createNotificationPage() {
        QWidget *page = new QWidget;
        page->setStyleSheet("background-color: #FEF7FF;");

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(12);

        QLabel *title = new QLabel("通知设置");
        title->setStyleSheet("font-size: 22px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(title);
        layout->addWidget(hsep());

        QCheckBox *soundCheck = new QCheckBox("通知铃声");
        soundCheck->setChecked(m_parser.notificationSound());
        soundCheck->setStyleSheet(cbStyle());
        layout->addWidget(soundCheck);

        QHBoxLayout *volumeRow = new QHBoxLayout;
        volumeRow->setSpacing(8);
        volumeRow->addWidget(new QLabel("音量:"));
        QSlider *volumeSlider = new QSlider(Qt::Horizontal);
        volumeSlider->setRange(0, 100);
        volumeSlider->setValue(qRound(m_parser.soundVolume() * 100));
        volumeSlider->setStyleSheet(sliderStyle());
        volumeRow->addWidget(volumeSlider, 1);
        QLabel *volumeVal = new QLabel(QString::number(qRound(m_parser.soundVolume() * 100)) + "%");
        volumeVal->setStyleSheet("font-size: 12px; color: #49454F; min-width: 36px;");
        volumeRow->addWidget(volumeVal);
        layout->addLayout(volumeRow);

        QPushButton *testSoundBtn = new QPushButton("试听铃声");
        testSoundBtn->setStyleSheet(
            "QPushButton { background-color: transparent; color: #6750A4; border: 1px solid #79747E; "
            "border-radius: 20px; padding: 6px 16px; font-size: 12px; font-weight: bold; }"
            "QPushButton:hover { background-color: #F3EDF7; }"
        );
        layout->addWidget(testSoundBtn);

        QHBoxLayout *soundFileRow = new QHBoxLayout;
        soundFileRow->setSpacing(8);
        QLabel *soundFileLabel = new QLabel("铃声文件:");
        soundFileLabel->setStyleSheet("font-size: 13px;");
        soundFileRow->addWidget(soundFileLabel);
        QLabel *soundFilePathLabel = new QLabel(m_parser.soundFilePath().isEmpty() ? "未设置" : QFileInfo(m_parser.soundFilePath()).fileName());
        soundFilePathLabel->setStyleSheet(
            "background-color: #F3EDF7; color: #49454F; padding: 6px 10px; "
            "border-radius: 8px; font-size: 12px; min-width: 120px;"
        );
        soundFileRow->addWidget(soundFilePathLabel, 1);
        QPushButton *chooseSoundBtn = new QPushButton("选择");
        chooseSoundBtn->setStyleSheet(
            "QPushButton { background-color: transparent; color: #6750A4; border: 1px solid #79747E; "
            "border-radius: 20px; padding: 5px 12px; font-size: 11px; font-weight: bold; }"
            "QPushButton:hover { background-color: #F3EDF7; }"
        );
        soundFileRow->addWidget(chooseSoundBtn);
        layout->addLayout(soundFileRow);

        layout->addStretch();

        connect(soundCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setNotificationSound(val); });
        connect(volumeSlider, &QSlider::valueChanged, &m_parser, [&p = m_parser, volumeVal](int val) {
            p.setSoundVolume(val / 100.0); volumeVal->setText(QString::number(val) + "%");
        });
        connect(testSoundBtn, &QPushButton::clicked, &m_parser, [&p = m_parser]() { p.playNotificationSound(); });
        connect(chooseSoundBtn, &QPushButton::clicked, this, [this, soundFilePathLabel]() {
            QString path = QFileDialog::getOpenFileName(this, "选择铃声文件", "",
                "音频文件 (*.wav);;所有文件 (*)");
            if (!path.isEmpty()) {
                m_parser.setSoundFilePath(path);
                soundFilePathLabel->setText(QFileInfo(path).fileName());
            }
        });

        return page;
    }

    QWidget* createAboutPage() {
        QWidget *page = new QWidget;
        page->setStyleSheet("background-color: #FEF7FF;");

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(12);

        QLabel *title = new QLabel("NEO ClassBoard");
        title->setStyleSheet("font-size: 28px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(title);

        QLabel *version = new QLabel("版本 1.0.0");
        version->setStyleSheet("font-size: 14px; color: #49454F;");
        layout->addWidget(version);

        layout->addWidget(hsep());

        QLabel *desc = new QLabel("一款轻量级桌面课表小组件\n支持 CSES 课表格式导入、换课、调休日、预备铃等功能");
        desc->setStyleSheet("font-size: 13px; color: #49454F; line-height: 1.6;");
        desc->setWordWrap(true);
        layout->addWidget(desc);

        layout->addSpacing(8);

        QLabel *techTitle = new QLabel("技术栈");
        techTitle->setStyleSheet("font-size: 14px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(techTitle);

        QLabel *tech = new QLabel("Qt 6 (QML + C++)\nMaterial Design 3 组件库\nCSES YAML 课表格式");
        tech->setStyleSheet("font-size: 13px; color: #49454F;");
        tech->setWordWrap(true);
        layout->addWidget(tech);

        layout->addStretch();

        QLabel *copy = new QLabel("Made with Qt 6 & MD3");
        copy->setStyleSheet("font-size: 11px; color: #79747E;");
        copy->setAlignment(Qt::AlignCenter);
        layout->addWidget(copy);

        return page;
    }

    void onImport() {
        QString path = QFileDialog::getOpenFileName(this, "导入 CSES 课表文件", "",
            "CSES 文件 (*.yml *.yaml);;所有文件 (*)");
        if (path.isEmpty()) return;

        if (m_parser.loadFromFile(path)) {
            m_parser.saveToDataDir(path);
            m_parser.setFilePath(CsesParser::savedPath());
            m_pathLabel->setText(m_parser.filePath());
            m_pathLabel->setStyleSheet(
                "background-color: #F3EDF7; color: #1C1B1F; padding: 10px 12px; "
                "border-radius: 12px; font-size: 13px;"
            );
            QMessageBox::information(this, "成功", "课表导入成功！");
        } else {
            QMessageBox::warning(this, "失败", "无法解析课表文件。");
        }
    }
};

#endif
