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
#include <QGuiApplication>
#include <QStyleHints>
#include <QIcon>
#include <QSvgRenderer>
#include <QPainter>
#include "csesparser.h"

class SettingsDialog : public QDialog
{
    Q_OBJECT

public:
    explicit SettingsDialog(CsesParser &parser, QWidget *parent = nullptr)
        : QDialog(parent), m_parser(parser), m_currentPage(0)
    {
        bool dark = QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark;
        initColors(dark);

        setWindowTitle("设置");
        setFixedSize(600, 520);
        setStyleSheet(QString(
            "QDialog { background-color: %1; }"
        ).arg(m_surface));

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
    QList<QIcon> m_iconsActive;
    QList<QIcon> m_iconsInactive;
    QLabel *m_pathLabel;

    QString m_surface, m_onSurface, m_surfaceContainer, m_onSurfaceVariant;
    QString m_primary, m_onPrimary, m_primaryContainer, m_onPrimaryContainer;
    QString m_secondaryContainer, m_outline, m_outlineVariant, m_error;
    QString m_onSurfaceVariantLight, m_onError;

    void initColors(bool dark) {
        if (dark) {
            m_surface = "#1C1B1F";
            m_onSurface = "#E6E1E5";
            m_surfaceContainer = "#2B2930";
            m_onSurfaceVariant = "#CAC4D0";
            m_onSurfaceVariantLight = "#938F99";
            m_primary = "#D0BCFF";
            m_onPrimary = "#381E72";
            m_primaryContainer = "#4F378B";
            m_onPrimaryContainer = "#EADDFF";
            m_secondaryContainer = "#4A4458";
            m_outline = "#938F99";
            m_outlineVariant = "#49454F";
            m_error = "#F2B8B5";
            m_onError = "#601410";
        } else {
            m_surface = "#FEF7FF";
            m_onSurface = "#1C1B1F";
            m_surfaceContainer = "#F3EDF7";
            m_onSurfaceVariant = "#49454F";
            m_onSurfaceVariantLight = "#79747E";
            m_primary = "#6750A4";
            m_onPrimary = "#FFFFFF";
            m_primaryContainer = "#E8DEF8";
            m_onPrimaryContainer = "#21005D";
            m_secondaryContainer = "#E8DEF8";
            m_outline = "#79747E";
            m_outlineVariant = "#CAC4D0";
            m_error = "#B3261E";
            m_onError = "#FFFFFF";
        }
    }

    QString navBtnStyle(int index, int active) {
        if (index == active) {
            return QString("QPushButton { background-color: %1; color: %2; border: none; "
                           "border-radius: 12px; font-size: 11px; font-weight: bold; }")
                .arg(m_primaryContainer, m_primary);
        }
        return QString("QPushButton { background-color: transparent; color: %1; border: none; "
                       "border-radius: 12px; font-size: 11px; font-weight: bold; }"
                       "QPushButton:hover { background-color: %2; }")
            .arg(m_onSurfaceVariant, m_primaryContainer);
    }

    void switchPage(int index) {
        m_currentPage = index;
        m_contentStack->setCurrentIndex(index);
        for (int i = 0; i < m_navBtns.size(); i++) {
            m_navBtns[i]->setStyleSheet(navBtnStyle(i, index));
            bool active = (i == index);
            m_navBtns[i]->setIcon(active ? m_iconsActive[i] : m_iconsInactive[i]);
        }
    }

    QIcon makeIcon(const QString &path, const QColor &color) {
        QSvgRenderer renderer(path);
        QPixmap pix(24, 24);
        pix.fill(Qt::transparent);
        QPainter p(&pix);
        renderer.render(&p);
        p.end();
        QPixmap result(24, 24);
        result.fill(Qt::transparent);
        QPainter rp(&result);
        rp.drawPixmap(0, 0, pix);
        rp.setCompositionMode(QPainter::CompositionMode_SourceIn);
        rp.fillRect(result.rect(), color);
        rp.end();
        return QIcon(result);
    }

    QWidget* createNavPanel() {
        QWidget *nav = new QWidget;
        nav->setFixedWidth(72);
        nav->setStyleSheet(QString("background-color: %1;").arg(m_surfaceContainer));

        QVBoxLayout *layout = new QVBoxLayout(nav);
        layout->setContentsMargins(4, 16, 4, 16);
        layout->setSpacing(4);

        QStringList labels = {"课表", "外观", "行为", "通知", "关于"};
        QStringList iconPaths = {
            ":/icons/schedule.svg",
            ":/icons/dashboard.svg",
            ":/icons/settings.svg",
            ":/icons/notifications.svg",
            ":/icons/info.svg"
        };
        QColor activeIconColor = QColor(m_primary);
        QColor inactiveIconColor = QColor(m_onSurfaceVariant);
        for (int i = 0; i < PAGE_COUNT; i++) {
            m_iconsActive.append(makeIcon(iconPaths[i], activeIconColor));
            m_iconsInactive.append(makeIcon(iconPaths[i], inactiveIconColor));

            QPushButton *btn = new QPushButton;
            btn->setIcon(m_iconsInactive[i]);
            btn->setIconSize(QSize(22, 22));
            btn->setText(labels[i]);
            btn->setFixedSize(64, 48);
            btn->setStyleSheet(navBtnStyle(i, 0));
            connect(btn, &QPushButton::clicked, this, [this, i]() { switchPage(i); });
            layout->addWidget(btn);
            m_navBtns.append(btn);
        }
        m_navBtns[0]->setIcon(m_iconsActive[0]);
        layout->addStretch();
        return nav;
    }

    QWidget* createContentPanel() {
        QWidget *panel = new QWidget;
        panel->setStyleSheet(QString("background-color: %1;").arg(m_surface));

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
        area->setStyleSheet(QString(
            "QScrollArea { border: none; background-color: %1; }"
            "QScrollBar:vertical { width: 6px; background: transparent; }"
            "QScrollBar::handle:vertical { background: %2; border-radius: 3px; min-height: 20px; }"
            "QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }"
        ).arg(m_surface, m_outlineVariant));
        return area;
    }

    QLabel* makeLabel(const QString &text, const QString &style) {
        QLabel *lbl = new QLabel(text);
        lbl->setStyleSheet(style);
        return lbl;
    }

    QString cbStyle() {
        return QString(
            "QCheckBox { font-size: 13px; color: %1; spacing: 10px; }"
            "QCheckBox::indicator { width: 18px; height: 18px; border-radius: 2px; "
            "border: 2px solid %2; background: transparent; }"
            "QCheckBox::indicator:checked { background: %3; border-color: %3; }"
            "QCheckBox::indicator:hover { border-color: %3; }"
        ).arg(m_onSurface, m_outlineVariant, m_primary);
    }

    QString sliderStyle() {
        return QString(
            "QSlider { min-height: 32px; }"
            "QSlider::groove:horizontal { height: 4px; background: %1; border-radius: 2px; margin: 0 10px; }"
            "QSlider::handle:horizontal { width: 20px; height: 20px; margin: -8px -10px; "
            "background: %2; border-radius: 10px; border: 2px solid %2; }"
            "QSlider::handle:horizontal:hover { background: %3; border-color: %3; }"
            "QSlider::sub-page:horizontal { background: %2; border-radius: 2px; margin: 0 10px; }"
        ).arg(m_surfaceContainer, m_primary, m_primaryContainer);
    }

    QString spinStyle() {
        return QString(
            "QSpinBox { padding: 8px 12px; border: 1px solid %1; border-radius: 8px; "
            "background: %2; font-size: 14px; color: %3; min-width: 80px; }"
            "QSpinBox:focus { border-color: %4; border-width: 2px; padding: 7px 11px; }"
            "QSpinBox::up-button, QSpinBox::down-button { width: 0; height: 0; border: none; }"
        ).arg(m_outlineVariant, m_surfaceContainer, m_onSurface, m_primary);
    }

    QString comboStyle() {
        return QString(
            "QComboBox { padding: 8px 12px; border: 1px solid %1; border-radius: 8px; "
            "background: %2; font-size: 14px; color: %3; min-width: 180px; }"
            "QComboBox:focus { border-color: %4; border-width: 2px; padding: 7px 11px; }"
            "QComboBox::drop-down { width: 0; border: none; }"
            "QComboBox QAbstractItemView { background: %2; color: %3; border: 1px solid %1; "
            "border-radius: 8px; padding: 4px; selection-background-color: %5; }"
        ).arg(m_outlineVariant, m_surfaceContainer, m_onSurface, m_primary, m_primaryContainer);
    }

    QFrame* hsep() {
        QFrame *sep = new QFrame;
        sep->setFrameShape(QFrame::HLine);
        sep->setStyleSheet(QString("background-color: %1; max-height: 1px; border: none;").arg(m_outlineVariant));
        return sep;
    }

    QString pageTitleStyle() {
        return QString("font-size: 22px; font-weight: bold; color: %1; padding: 0;").arg(m_onSurface);
    }

    QString sectionTitleStyle() {
        return QString("font-size: 14px; font-weight: bold; color: %1; padding: 0;").arg(m_onSurface);
    }

    QString bodyLabelStyle() {
        return QString("font-size: 14px; color: %1; padding: 0;").arg(m_onSurface);
    }

    QString captionLabelStyle() {
        return QString("font-size: 12px; color: %1; padding: 0;").arg(m_onSurfaceVariant);
    }

    QString primaryBtnStyle() {
        return QString(
            "QPushButton { background-color: %1; color: %2; border: none; "
            "border-radius: 20px; padding: 8px 24px; font-size: 14px; font-weight: bold; }"
            "QPushButton:hover { background-color: %3; }"
        ).arg(m_primary, m_onPrimary, m_primaryContainer);
    }

    QString outlineBtnStyle() {
        return QString(
            "QPushButton { background-color: transparent; color: %1; border: 1px solid %2; "
            "border-radius: 20px; padding: 8px 20px; font-size: 13px; font-weight: bold; }"
            "QPushButton:hover { background-color: %3; }"
        ).arg(m_primary, m_outline, m_primaryContainer);
    }

    static constexpr int PAGE_COUNT = 5;

    QWidget* createSchedulePage() {
        QWidget *page = new QWidget;
        page->setStyleSheet(QString("background-color: %1;").arg(m_surface));

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(16);

        layout->addWidget(makeLabel("课表设置", pageTitleStyle()));
        layout->addWidget(hsep());

        layout->addWidget(makeLabel("课表文件", sectionTitleStyle()));

        QHBoxLayout *fileRow = new QHBoxLayout;
        fileRow->setSpacing(12);
        m_pathLabel = new QLabel(m_parser.loaded() ? m_parser.filePath() : "未导入课表");
        m_pathLabel->setWordWrap(true);
        QString pathColor = m_parser.loaded() ? m_onSurface : m_onSurfaceVariant;
        m_pathLabel->setStyleSheet(
            QString("background-color: %1; color: %2; padding: 10px 14px; "
                    "border-radius: 12px; font-size: 13px;").arg(m_surfaceContainer, pathColor)
        );
        fileRow->addWidget(m_pathLabel, 1);
        QPushButton *importBtn = new QPushButton("导入");
        importBtn->setFixedSize(80, 40);
        importBtn->setStyleSheet(primaryBtnStyle());
        fileRow->addWidget(importBtn);
        layout->addLayout(fileRow);

        layout->addWidget(hsep());

        layout->addWidget(makeLabel("时间设置", sectionTitleStyle()));

        auto addSettingRow = [&](const QString &label, QWidget *control) {
            QHBoxLayout *row = new QHBoxLayout;
            row->setSpacing(12);
            row->addWidget(makeLabel(label, bodyLabelStyle()));
            row->addWidget(control);
            row->addStretch();
            layout->addLayout(row);
        };

        QSpinBox *offsetSpin = new QSpinBox;
        offsetSpin->setRange(-60, 60);
        offsetSpin->setValue(m_parser.timeOffset());
        offsetSpin->setStyleSheet(spinStyle());
        addSettingRow("时间偏移(分钟)", offsetSpin);

        QSpinBox *prepSpin = new QSpinBox;
        prepSpin->setRange(0, 10);
        prepSpin->setValue(m_parser.preparationTime());
        prepSpin->setStyleSheet(spinStyle());
        addSettingRow("预备铃提前(分钟)", prepSpin);

        QSpinBox *weekSpin = new QSpinBox;
        weekSpin->setRange(0, 30);
        weekSpin->setValue(m_parser.currentWeek());
        weekSpin->setSpecialValueText("自动");
        weekSpin->setStyleSheet(spinStyle());
        addSettingRow("当前周次", weekSpin);

        layout->addWidget(hsep());

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
        page->setStyleSheet(QString("background-color: %1;").arg(m_surface));

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(16);

        layout->addWidget(makeLabel("外观设置", pageTitleStyle()));
        layout->addWidget(hsep());

        auto addSliderRow = [&](const QString &label, QSlider *slider, QLabel *valLabel) {
            QHBoxLayout *row = new QHBoxLayout;
            row->setSpacing(12);
            row->addWidget(makeLabel(label, bodyLabelStyle()));
            row->addWidget(slider, 1);
            valLabel->setMinimumWidth(42);
            valLabel->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
            valLabel->setStyleSheet(captionLabelStyle());
            row->addWidget(valLabel);
            layout->addLayout(row);
        };

        QSlider *scaleSlider = new QSlider(Qt::Horizontal);
        scaleSlider->setRange(50, 200);
        scaleSlider->setValue(qRound(m_parser.widgetScale() * 100));
        scaleSlider->setStyleSheet(sliderStyle());
        QLabel *scaleVal = new QLabel(QString::number(qRound(m_parser.widgetScale() * 100)) + "%");
        addSliderRow("缩放比例", scaleSlider, scaleVal);

        QSlider *opacitySlider = new QSlider(Qt::Horizontal);
        opacitySlider->setRange(20, 100);
        opacitySlider->setValue(qRound(m_parser.widgetOpacity() * 100));
        opacitySlider->setStyleSheet(sliderStyle());
        QLabel *opacityVal = new QLabel(QString::number(qRound(m_parser.widgetOpacity() * 100)) + "%");
        addSliderRow("不透明度", opacitySlider, opacityVal);

        QCheckBox *onBottomCheck = new QCheckBox("窗口置底");
        onBottomCheck->setChecked(m_parser.alwaysOnBottom());
        onBottomCheck->setStyleSheet(cbStyle());
        layout->addWidget(onBottomCheck);

        layout->addWidget(hsep());

        QHBoxLayout *fontRow = new QHBoxLayout;
        fontRow->setSpacing(12);
        fontRow->addWidget(makeLabel("字体", bodyLabelStyle()));
        QFontComboBox *fontCombo = new QFontComboBox;
        fontCombo->setCurrentFont(QFont(m_parser.fontFamily()));
        fontCombo->setStyleSheet(comboStyle());
        fontRow->addWidget(fontCombo, 1);
        layout->addLayout(fontRow);

        layout->addStretch();

        connect(scaleSlider, &QSlider::valueChanged, &m_parser, [&p = m_parser, scaleVal](int val) {
            p.setWidgetScale(val / 100.0); scaleVal->setText(QString::number(val) + "%");
        });
        connect(opacitySlider, &QSlider::valueChanged, &m_parser, [&p = m_parser, opacityVal](int val) {
            p.setWidgetOpacity(val / 100.0); opacityVal->setText(QString::number(val) + "%");
        });
        connect(onBottomCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setAlwaysOnBottom(val); });
        connect(fontCombo, &QFontComboBox::currentFontChanged, &m_parser, [&p = m_parser](const QFont &font) {
            p.setFontFamily(font.family());
        });

        return page;
    }

    QWidget* createBehaviorPage() {
        QWidget *page = new QWidget;
        page->setStyleSheet(QString("background-color: %1;").arg(m_surface));

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(14);

        layout->addWidget(makeLabel("行为设置", pageTitleStyle()));
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

        layout->addWidget(makeLabel("自动隐藏", sectionTitleStyle()));

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
        page->setStyleSheet(QString("background-color: %1;").arg(m_surface));

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(16);

        layout->addWidget(makeLabel("通知设置", pageTitleStyle()));
        layout->addWidget(hsep());

        QCheckBox *soundCheck = new QCheckBox("通知铃声");
        soundCheck->setChecked(m_parser.notificationSound());
        soundCheck->setStyleSheet(cbStyle());
        layout->addWidget(soundCheck);

        QHBoxLayout *volumeRow = new QHBoxLayout;
        volumeRow->setSpacing(12);
        volumeRow->addWidget(makeLabel("音量", bodyLabelStyle()));
        QSlider *volumeSlider = new QSlider(Qt::Horizontal);
        volumeSlider->setRange(0, 100);
        volumeSlider->setValue(qRound(m_parser.soundVolume() * 100));
        volumeSlider->setStyleSheet(sliderStyle());
        volumeRow->addWidget(volumeSlider, 1);
        QLabel *volumeVal = new QLabel(QString::number(qRound(m_parser.soundVolume() * 100)) + "%");
        volumeVal->setMinimumWidth(42);
        volumeVal->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
        volumeVal->setStyleSheet(captionLabelStyle());
        volumeRow->addWidget(volumeVal);
        layout->addLayout(volumeRow);

        QPushButton *testSoundBtn = new QPushButton("试听铃声");
        testSoundBtn->setFixedWidth(120);
        testSoundBtn->setStyleSheet(outlineBtnStyle());
        layout->addWidget(testSoundBtn);

        layout->addWidget(hsep());

        QLabel *soundFileLabel = new QLabel("铃声文件");
        soundFileLabel->setStyleSheet(bodyLabelStyle());
        layout->addWidget(soundFileLabel);

        QHBoxLayout *soundFileRow = new QHBoxLayout;
        soundFileRow->setSpacing(12);
        QLabel *soundFilePathLabel = new QLabel(m_parser.soundFilePath().isEmpty() ? "未设置" : QFileInfo(m_parser.soundFilePath()).fileName());
        soundFilePathLabel->setStyleSheet(
            QString("background-color: %1; color: %2; padding: 10px 14px; "
                    "border-radius: 12px; font-size: 13px; min-width: 160px;")
                .arg(m_surfaceContainer, m_onSurfaceVariant)
        );
        soundFileRow->addWidget(soundFilePathLabel, 1);
        QPushButton *chooseSoundBtn = new QPushButton("选择");
        chooseSoundBtn->setStyleSheet(outlineBtnStyle());
        soundFileRow->addWidget(chooseSoundBtn);
        layout->addLayout(soundFileRow);

        layout->addStretch();

        connect(soundCheck, &QCheckBox::toggled, &m_parser, [&p = m_parser](bool val) { p.setNotificationSound(val); });
        connect(volumeSlider, &QSlider::valueChanged, &m_parser, [&p = m_parser, volumeVal](int val) {
            p.setSoundVolume(val / 100.0); volumeVal->setText(QString::number(val) + "%");
        });
        connect(testSoundBtn, &QPushButton::clicked, &m_parser, [&p = m_parser]() { p.testNotificationSound(); });
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
        page->setStyleSheet(QString("background-color: %1;").arg(m_surface));

        QVBoxLayout *layout = new QVBoxLayout(page);
        layout->setContentsMargins(24, 24, 24, 24);
        layout->setSpacing(12);

        QSvgRenderer logoRenderer(QString(":/icons/logo.svg"));
        QPixmap logoPix(96, 96);
        logoPix.fill(Qt::transparent);
        QPainter logoPainter(&logoPix);
        logoRenderer.render(&logoPainter);
        logoPainter.end();
        QLabel *logoLabel = new QLabel;
        logoLabel->setPixmap(logoPix);
        logoLabel->setAlignment(Qt::AlignCenter);
        layout->addWidget(logoLabel);

        layout->addWidget(makeLabel("NEO ClassBoard", pageTitleStyle()));
        layout->addWidget(makeLabel("版本 1.2.0", captionLabelStyle()));

        layout->addWidget(hsep());

        QLabel *desc = new QLabel("一款轻量级桌面课表小组件\n支持 CSES 课表格式导入、换课、调休日、预备铃等功能");
        desc->setStyleSheet(bodyLabelStyle());
        desc->setWordWrap(true);
        layout->addWidget(desc);

        layout->addSpacing(8);

        layout->addWidget(makeLabel("技术栈", sectionTitleStyle()));

        QLabel *tech = new QLabel("Qt 6 (QML + C++)\nMaterial Design 3 组件库\nCSES YAML 课表格式");
        tech->setStyleSheet(bodyLabelStyle());
        tech->setWordWrap(true);
        layout->addWidget(tech);

        layout->addStretch();

        QLabel *copy = new QLabel("Made with Qt 6 & MD3");
        copy->setStyleSheet(captionLabelStyle());
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
                QString("background-color: %1; color: %2; padding: 10px 14px; "
                        "border-radius: 12px; font-size: 13px;").arg(m_surfaceContainer, m_onSurface)
            );
            QMessageBox::information(this, "成功", "课表导入成功！");
        } else {
            QMessageBox::warning(this, "失败", "无法解析课表文件。");
        }
    }
};

#endif