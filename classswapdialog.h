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
#include "csesparser.h"

class ClassSwapDialog : public QDialog
{
    Q_OBJECT

public:
    explicit ClassSwapDialog(CsesParser &parser, QWidget *parent = nullptr)
        : QDialog(parent), m_parser(parser)
    {
        setWindowTitle("换课");
        setFixedSize(420, 360);
        setStyleSheet(
            "QDialog { background-color: #FEF7FF; }"
            "QLabel { color: #1C1B1F; }"
            "QComboBox { padding: 6px 12px; border: 1px solid #CAC4D0; border-radius: 8px; "
            "background: #F3EDF7; font-size: 13px; }"
        );

        QVBoxLayout *layout = new QVBoxLayout(this);
        layout->setContentsMargins(20, 20, 20, 20);
        layout->setSpacing(12);

        QLabel *title = new QLabel("换课");
        title->setStyleSheet("font-size: 20px; font-weight: bold; color: #1C1B1F;");
        layout->addWidget(title);

        QLabel *tip = new QLabel("仅影响当天课表，不会修改原始文件");
        tip->setStyleSheet("font-size: 12px; color: #79747E;");
        layout->addWidget(tip);

        QVariantList todayClasses = m_parser.getTodayClassesRaw();
        QStringList classNames;
        for (int i = 0; i < todayClasses.size(); i++) {
            QVariantMap cls = todayClasses[i].toMap();
            classNames.append(QString::number(i + 1) + ". " + cls["subject"].toString() +
                " (" + cls["start_time"].toString().left(5) + "-" + cls["end_time"].toString().left(5) + ")");
        }

        // 交换两节课
        QLabel *swapTitle = new QLabel("交换两节课");
        swapTitle->setStyleSheet("font-size: 15px; font-weight: bold; color: #6750A4;");
        layout->addWidget(swapTitle);

        QHBoxLayout *swapRow = new QHBoxLayout;
        swapRow->setSpacing(8);
        comboA = new QComboBox;
        comboB = new QComboBox;
        comboA->addItems(classNames);
        comboB->addItems(classNames);
        if (classNames.size() > 1) comboB->setCurrentIndex(1);
        swapRow->addWidget(comboA);
        QLabel *arrow = new QLabel("⇄");
        arrow->setAlignment(Qt::AlignCenter);
        arrow->setStyleSheet("font-size: 18px; color: #6750A4;");
        swapRow->addWidget(arrow);
        swapRow->addWidget(comboB);
        layout->addLayout(swapRow);

        QPushButton *swapBtn = makeBtn("交换", "#0B57D0");
        layout->addWidget(swapBtn);

        layout->addSpacing(4);
        QFrame *sep = new QFrame;
        sep->setFrameShape(QFrame::HLine);
        sep->setStyleSheet("background-color: #CAC4D0; max-height: 1px; border: none;");
        layout->addWidget(sep);

        // 替换单节课
        QLabel *replaceTitle = new QLabel("替换单节课");
        replaceTitle->setStyleSheet("font-size: 15px; font-weight: bold; color: #6750A4;");
        layout->addWidget(replaceTitle);

        QHBoxLayout *replaceRow = new QHBoxLayout;
        replaceRow->setSpacing(8);
        comboTarget = new QComboBox;
        comboTarget->addItems(classNames);
        comboNew = new QComboBox;
        QStringList subjectNames;
        for (const auto &s : m_parser.subjects()) {
            subjectNames.append(s.toMap()["name"].toString());
        }
        comboNew->addItems(subjectNames);
        replaceRow->addWidget(comboTarget);
        QLabel *arrow2 = new QLabel("→");
        arrow2->setAlignment(Qt::AlignCenter);
        arrow2->setStyleSheet("font-size: 16px; color: #6750A4;");
        replaceRow->addWidget(arrow2);
        replaceRow->addWidget(comboNew);
        layout->addLayout(replaceRow);

        QPushButton *replaceBtn = makeBtn("替换", "#0B57D0");
        layout->addWidget(replaceBtn);

        layout->addSpacing(4);
        QFrame *sep2 = new QFrame;
        sep2->setFrameShape(QFrame::HLine);
        sep2->setStyleSheet("background-color: #CAC4D0; max-height: 1px; border: none;");
        layout->addWidget(sep2);

        // 清除换课
        QPushButton *clearBtn = makeBtn("清除所有换课", "#B3261E");
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

    QPushButton* makeBtn(const QString &text, const QString &bgColor) {
        QPushButton *btn = new QPushButton(text);
        btn->setStyleSheet(
            QString("QPushButton { background-color: %1; color: white; border: none; "
                    "border-radius: 20px; padding: 8px 24px; font-size: 13px; font-weight: bold; }"
                    "QPushButton:hover { background-color: %2; }")
                .arg(bgColor, bgColor == "#B3261E" ? "#8C1D18" : "#0842A0")
        );
        return btn;
    }
};
#endif