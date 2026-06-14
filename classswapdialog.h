#ifndef CLASSSWAPDIALOG_H
#define CLASSSWAPDIALOG_H

#include <QDialog>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QComboBox>
#include <QFrame>
#include <QMessageBox>
#include <QGuiApplication>
#include <QStyleHints>
#include "csesparser.h"

class ClassSwapDialog : public QDialog
{
    Q_OBJECT

public:
    explicit ClassSwapDialog(CsesParser &parser, QWidget *parent = nullptr)
        : QDialog(parent), m_parser(parser)
    {
        bool dark = QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark;
        initColors(dark);

        setWindowTitle("换课");
        setFixedSize(520, 480);
        setStyleSheet(QString("QDialog { background-color: %1; }").arg(m_surface));

        QVBoxLayout *layout = new QVBoxLayout(this);
        layout->setContentsMargins(24, 20, 24, 20);
        layout->setSpacing(10);

        QLabel *title = new QLabel("换课");
        title->setStyleSheet(QString("font-size: 22px; font-weight: bold; color: %1;").arg(m_onSurface));
        layout->addWidget(title);

        QLabel *tip = new QLabel("仅影响当天课表，不会修改原始文件");
        tip->setStyleSheet(QString("font-size: 13px; color: %1;").arg(m_onSurfaceVariant));
        layout->addWidget(tip);

        QVariantList todayClasses = m_parser.getTodayClassesRaw();
        QStringList classNames;
        for (int i = 0; i < todayClasses.size(); i++) {
            QVariantMap cls = todayClasses[i].toMap();
            classNames.append(QString::number(i + 1) + ". " + cls["subject"].toString() +
                " (" + cls["start_time"].toString().left(5) + "-" + cls["end_time"].toString().left(5) + ")");
        }

        QLabel *swapTitle = new QLabel("交换两节课");
        swapTitle->setStyleSheet(QString("font-size: 15px; font-weight: bold; color: %1;").arg(m_primary));
        layout->addWidget(swapTitle);

        QHBoxLayout *swapRow = new QHBoxLayout;
        swapRow->setSpacing(12);
        comboA = makeCombo(classNames);
        comboB = makeCombo(classNames);
        if (classNames.size() > 1) comboB->setCurrentIndex(1);
        swapRow->addWidget(comboA);
        QLabel *arrow = new QLabel("⇄");
        arrow->setAlignment(Qt::AlignCenter);
        arrow->setFixedWidth(24);
        arrow->setStyleSheet(QString("font-size: 20px; color: %1;").arg(m_primary));
        swapRow->addWidget(arrow);
        swapRow->addWidget(comboB);
        layout->addLayout(swapRow);

        QPushButton *swapBtn = makeBtn("交换", m_primary, m_onPrimary);
        layout->addWidget(swapBtn);

        layout->addSpacing(2);
        QFrame *sep = new QFrame;
        sep->setFrameShape(QFrame::HLine);
        sep->setStyleSheet(QString("background-color: %1; max-height: 1px; border: none;").arg(m_outlineVariant));
        layout->addWidget(sep);

        QLabel *replaceTitle = new QLabel("替换单节课");
        replaceTitle->setStyleSheet(QString("font-size: 15px; font-weight: bold; color: %1;").arg(m_primary));
        layout->addWidget(replaceTitle);

        QHBoxLayout *replaceRow = new QHBoxLayout;
        replaceRow->setSpacing(12);
        comboTarget = makeCombo(classNames);
        comboNew = new QComboBox;
        QStringList subjectNames;
        for (const auto &s : m_parser.subjects()) {
            subjectNames.append(s.toMap()["name"].toString());
        }
        comboNew->addItems(subjectNames);
        comboNew->setStyleSheet(comboStyle());
        replaceRow->addWidget(comboTarget);
        QLabel *arrow2 = new QLabel("→");
        arrow2->setAlignment(Qt::AlignCenter);
        arrow2->setFixedWidth(24);
        arrow2->setStyleSheet(QString("font-size: 18px; color: %1;").arg(m_primary));
        replaceRow->addWidget(arrow2);
        replaceRow->addWidget(comboNew);
        layout->addLayout(replaceRow);

        QPushButton *replaceBtn = makeBtn("替换", m_primary, m_onPrimary);
        layout->addWidget(replaceBtn);

        layout->addSpacing(2);
        QFrame *sep2 = new QFrame;
        sep2->setFrameShape(QFrame::HLine);
        sep2->setStyleSheet(QString("background-color: %1; max-height: 1px; border: none;").arg(m_outlineVariant));
        layout->addWidget(sep2);

        QPushButton *clearBtn = makeBtn("清除所有换课", m_error, m_onError);
        layout->addWidget(clearBtn);

        layout->addStretch();

        connect(swapBtn, &QPushButton::clicked, this, [this]() {
            m_parser.swapClasses(comboA->currentIndex(), comboB->currentIndex());
            QMessageBox::information(this, "成功", "已交换两节课");
            accept();
        });
        connect(replaceBtn, &QPushButton::clicked, this, [this]() {
            m_parser.replaceClass(comboTarget->currentIndex(), comboNew->currentText());
            QMessageBox::information(this, "成功", "已替换课程");
            accept();
        });
        connect(clearBtn, &QPushButton::clicked, this, [this]() {
            m_parser.clearSwaps();
            QMessageBox::information(this, "成功", "已清除所有换课");
            accept();
        });
    }

private:
    CsesParser &m_parser;
    QComboBox *comboA, *comboB, *comboTarget, *comboNew;

    QString m_surface, m_onSurface, m_surfaceContainer, m_onSurfaceVariant;
    QString m_primary, m_onPrimary, m_primaryContainer;
    QString m_outline, m_outlineVariant, m_error, m_onError;

    void initColors(bool dark) {
        if (dark) {
            m_surface = "#1C1B1F";
            m_onSurface = "#E6E1E5";
            m_surfaceContainer = "#2B2930";
            m_onSurfaceVariant = "#CAC4D0";
            m_primary = "#D0BCFF";
            m_onPrimary = "#381E72";
            m_primaryContainer = "#4F378B";
            m_outline = "#938F99";
            m_outlineVariant = "#49454F";
            m_error = "#F2B8B5";
            m_onError = "#601410";
        } else {
            m_surface = "#FEF7FF";
            m_onSurface = "#1C1B1F";
            m_surfaceContainer = "#F3EDF7";
            m_onSurfaceVariant = "#49454F";
            m_primary = "#6750A4";
            m_onPrimary = "#FFFFFF";
            m_primaryContainer = "#E8DEF8";
            m_outline = "#79747E";
            m_outlineVariant = "#CAC4D0";
            m_error = "#B3261E";
            m_onError = "#FFFFFF";
        }
    }

    QString comboStyle() {
        return QString(
            "QComboBox { padding: 10px 14px; border: 1px solid %1; border-radius: 8px; "
            "background: %2; font-size: 14px; color: %3; min-height: 20px; }"
            "QComboBox:focus { border-color: %4; border-width: 2px; padding: 9px 13px; }"
            "QComboBox::drop-down { width: 28px; border: none; }"
            "QComboBox::down-arrow { width: 12px; height: 12px; }"
            "QComboBox QAbstractItemView { background: %2; color: %3; border: 1px solid %1; "
            "border-radius: 8px; padding: 6px; selection-background-color: %5; outline: none; }"
            "QComboBox QAbstractItemView::item { min-height: 36px; padding: 8px 12px; }"
        ).arg(m_outlineVariant, m_surfaceContainer, m_onSurface, m_primary, m_primaryContainer);
    }

    QComboBox* makeCombo(const QStringList &items) {
        QComboBox *combo = new QComboBox;
        combo->addItems(items);
        combo->setStyleSheet(comboStyle());
        return combo;
    }

    QPushButton* makeBtn(const QString &text, const QString &bg, const QString &fg) {
        QPushButton *btn = new QPushButton(text);
        btn->setMinimumHeight(36);
        btn->setStyleSheet(
            QString("QPushButton { background-color: %1; color: %2; border: none; "
                    "border-radius: 18px; padding: 8px 20px; font-size: 14px; font-weight: bold; min-height: 20px; }"
                    "QPushButton:hover { background-color: %3; }")
                .arg(bg, fg, m_primaryContainer)
        );
        return btn;
    }
};
#endif