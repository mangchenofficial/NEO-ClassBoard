#ifndef SCHEDULEEDITOR_H
#define SCHEDULEEDITOR_H

#include <QDialog>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QFrame>
#include <QListWidget>
#include <QLineEdit>
#include <QListWidgetItem>
#include <QLineEdit>
#include <QSpinBox>
#include <QTimeEdit>
#include <QComboBox>
#include <QTabWidget>
#include <QTableWidget>
#include <QTableWidgetItem>
#include <QHeaderView>
#include <QMessageBox>
#include <QFileDialog>
#include <QGuiApplication>
#include <QStyleHints>
#include "csesparser.h"

class ScheduleEditor : public QDialog
{
public:
    explicit ScheduleEditor(CsesParser &parser, QWidget *parent = nullptr)
        : QDialog(parent), m_parser(parser)
    {
        bool dark = QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Dark;
        initColors(dark);

        setWindowTitle("课表编辑器");
        setFixedSize(720, 520);
        setStyleSheet(QString(
            "QDialog { background-color: %1; }"
            "QLabel { color: %2; font-size: 13px; }"
            "QLineEdit, QSpinBox, QTimeEdit, QComboBox { padding: 6px 10px; border: 1px solid %3; "
            "border-radius: 8px; background: %4; font-size: 13px; color: %2; }"
            "QPushButton { background-color: %5; color: %6; border: none; "
            "border-radius: 20px; padding: 8px 20px; font-size: 13px; font-weight: bold; }"
            "QPushButton:hover { background-color: %7; }"
            "QPushButton#dangerBtn { background-color: %8; }"
            "QPushButton#dangerBtn:hover { background-color: %9; }"
            "QPushButton#secondaryBtn { background-color: transparent; color: %5; border: 1px solid %10; }"
            "QPushButton#secondaryBtn:hover { background-color: %4; }"
            "QTabWidget::pane { border: 1px solid %3; border-radius: 8px; background: %1; }"
            "QTabBar::tab { padding: 8px 16px; border: 1px solid %3; border-bottom: none; "
            "border-radius: 8px 8px 0 0; background: %4; color: %11; font-size: 12px; }"
            "QTabBar::tab:selected { background: %1; color: %5; font-weight: bold; }"
            "QListWidget { border: 1px solid %3; border-radius: 8px; background: %1; padding: 4px; }"
            "QListWidget::item { padding: 6px; border-radius: 6px; }"
            "QListWidget::item:selected { background: %12; color: %2; }"
            "QTableWidget { border: 1px solid %3; border-radius: 8px; background: %1; "
            "gridline-color: %3; }"
            "QTableWidget::item { padding: 4px; color: %2; }"
            "QHeaderView::section { background: %4; color: %11; border: 1px solid %3; "
            "padding: 6px; font-weight: bold; }"
        ).arg(m_surface, m_onSurface, m_outlineVariant, m_surfaceContainer,
              m_primary, m_onPrimary, m_primaryDark, m_error, m_errorDark,
              m_outline, m_onSurfaceVariant, m_secondaryContainer));

        QVBoxLayout *mainLayout = new QVBoxLayout(this);
        mainLayout->setContentsMargins(16, 16, 16, 16);
        mainLayout->setSpacing(12);

        QLabel *title = new QLabel("课表编辑器");
        title->setStyleSheet(QString("font-size: 22px; font-weight: bold; color: %1;").arg(m_onSurface));
        mainLayout->addWidget(title);

        QTabWidget *tabs = new QTabWidget;
        tabs->addTab(createSubjectsTab(), "科目");
        tabs->addTab(createTimelineTab(), "时间线");
        tabs->addTab(createScheduleTab(), "课程表");
        mainLayout->addWidget(tabs, 1);

        QHBoxLayout *bottomRow = new QHBoxLayout;
        bottomRow->addStretch();
        QPushButton *exportBtn = new QPushButton("导出课表");
        connect(exportBtn, &QPushButton::clicked, this, &ScheduleEditor::onExport);
        bottomRow->addWidget(exportBtn);
        mainLayout->addLayout(bottomRow);
    }

private:
    CsesParser &m_parser;
    QListWidget *m_subjectList = nullptr;
    QTableWidget *m_scheduleTable = nullptr;
    QComboBox *m_dayCombo = nullptr;

    QString m_surface, m_onSurface, m_surfaceContainer, m_onSurfaceVariant;
    QString m_primary, m_onPrimary, m_primaryDark, m_primaryContainer;
    QString m_secondaryContainer, m_outline, m_outlineVariant, m_error, m_errorDark;

    void initColors(bool dark) {
        if (dark) {
            m_surface = "#1C1B1F";
            m_onSurface = "#E6E1E5";
            m_surfaceContainer = "#2B2930";
            m_onSurfaceVariant = "#CAC4D0";
            m_primary = "#D0BCFF";
            m_onPrimary = "#381E72";
            m_primaryDark = "#B89FFF";
            m_primaryContainer = "#4F378B";
            m_secondaryContainer = "#4A4458";
            m_outline = "#938F99";
            m_outlineVariant = "#49454F";
            m_error = "#F2B8B5";
            m_errorDark = "#D9A29F";
        } else {
            m_surface = "#FEF7FF";
            m_onSurface = "#1C1B1F";
            m_surfaceContainer = "#F3EDF7";
            m_onSurfaceVariant = "#49454F";
            m_primary = "#6750A4";
            m_onPrimary = "#FFFFFF";
            m_primaryDark = "#4F378B";
            m_primaryContainer = "#E8DEF8";
            m_secondaryContainer = "#E8DEF8";
            m_outline = "#79747E";
            m_outlineVariant = "#CAC4D0";
            m_error = "#B3261E";
            m_errorDark = "#8C1D18";
        }
    }

    QWidget* createSubjectsTab() {
        QWidget *tab = new QWidget;
        QHBoxLayout *layout = new QHBoxLayout(tab);
        layout->setSpacing(12);

        m_subjectList = new QListWidget;
        refreshSubjectList();
        layout->addWidget(m_subjectList, 1);

        QWidget *editPanel = new QWidget;
        QVBoxLayout *editLayout = new QVBoxLayout(editPanel);
        editLayout->setSpacing(8);

        QLabel *nameLbl = new QLabel("科目名称:");
        nameLbl->setStyleSheet(QString("font-size: 13px; color: %1;").arg(m_onSurface));
        editLayout->addWidget(nameLbl);
        QLineEdit *nameEdit = new QLineEdit;
        editLayout->addWidget(nameEdit);

        QLabel *simplifiedLbl = new QLabel("简称:");
        simplifiedLbl->setStyleSheet(QString("font-size: 13px; color: %1;").arg(m_onSurface));
        editLayout->addWidget(simplifiedLbl);
        QLineEdit *simplifiedEdit = new QLineEdit;
        editLayout->addWidget(simplifiedEdit);

        QLabel *teacherLbl = new QLabel("教师:");
        teacherLbl->setStyleSheet(QString("font-size: 13px; color: %1;").arg(m_onSurface));
        editLayout->addWidget(teacherLbl);
        QLineEdit *teacherEdit = new QLineEdit;
        editLayout->addWidget(teacherEdit);

        QLabel *roomLbl = new QLabel("教室:");
        roomLbl->setStyleSheet(QString("font-size: 13px; color: %1;").arg(m_onSurface));
        editLayout->addWidget(roomLbl);
        QLineEdit *roomEdit = new QLineEdit;
        editLayout->addWidget(roomEdit);

        editLayout->addStretch();

        QPushButton *addBtn = new QPushButton("添加科目");
        connect(addBtn, &QPushButton::clicked, this, [=]() {
            if (nameEdit->text().isEmpty()) return;
            QVariantMap subj;
            subj["name"] = nameEdit->text();
            subj["simplified_name"] = simplifiedEdit->text().isEmpty() ? nameEdit->text().left(1) : simplifiedEdit->text();
            subj["teacher"] = teacherEdit->text();
            subj["room"] = roomEdit->text();
            m_parser.addSubject(subj);
            refreshSubjectList();
            nameEdit->clear(); simplifiedEdit->clear(); teacherEdit->clear(); roomEdit->clear();
        });
        editLayout->addWidget(addBtn);

        QPushButton *delBtn = new QPushButton("删除选中");
        delBtn->setObjectName("dangerBtn");
        connect(delBtn, &QPushButton::clicked, this, [=]() {
            int row = m_subjectList->currentRow();
            if (row >= 0) {
                m_parser.removeSubject(row);
                refreshSubjectList();
            }
        });
        editLayout->addWidget(delBtn);

        layout->addWidget(editPanel, 1);
        return tab;
    }

    QWidget* createTimelineTab() {
        QWidget *tab = new QWidget;
        QVBoxLayout *layout = new QVBoxLayout(tab);
        layout->setSpacing(8);

        QHBoxLayout *topRow = new QHBoxLayout;
        QLabel *dayLbl = new QLabel("选择星期:");
        dayLbl->setStyleSheet(QString("font-size: 13px; color: %1;").arg(m_onSurface));
        topRow->addWidget(dayLbl);

        m_dayCombo = new QComboBox;
        m_dayCombo->addItems({"周一", "周二", "周三", "周四", "周五", "周六", "周日"});
        connect(m_dayCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &ScheduleEditor::onDayChanged);
        topRow->addWidget(m_dayCombo);
        topRow->addStretch();
        layout->addLayout(topRow);

        m_scheduleTable = new QTableWidget(0, 4);
        m_scheduleTable->setHorizontalHeaderLabels({"科目", "开始时间", "结束时间", "类型"});
        m_scheduleTable->horizontalHeader()->setStretchLastSection(true);
        m_scheduleTable->setSelectionBehavior(QTableWidget::SelectRows);
        layout->addWidget(m_scheduleTable, 1);

        QHBoxLayout *btnRow = new QHBoxLayout;
        QPushButton *addEntryBtn = new QPushButton("添加课程");
        connect(addEntryBtn, &QPushButton::clicked, this, &ScheduleEditor::onAddEntry);
        btnRow->addWidget(addEntryBtn);

        QPushButton *delEntryBtn = new QPushButton("删除选中行");
        delEntryBtn->setObjectName("dangerBtn");
        connect(delEntryBtn, &QPushButton::clicked, this, [=]() {
            int row = m_scheduleTable->currentRow();
            if (row >= 0) {
                m_parser.removeClassEntry(m_dayCombo->currentIndex() + 1, row);
                onDayChanged(m_dayCombo->currentIndex());
            }
        });
        btnRow->addWidget(delEntryBtn);
        btnRow->addStretch();
        layout->addLayout(btnRow);

        onDayChanged(0);
        return tab;
    }

    QWidget* createScheduleTab() {
        QWidget *tab = new QWidget;
        QVBoxLayout *layout = new QVBoxLayout(tab);

        QLabel *hint = new QLabel("在「时间线」标签页中按星期编辑课程。\n"
                                   "在「科目」标签页中管理科目信息。\n\n"
                                   "编辑完成后点击下方「导出课表」保存为 CSES 文件。");
        hint->setStyleSheet(QString("font-size: 14px; color: %1; padding: 20px;").arg(m_onSurfaceVariant));
        hint->setWordWrap(true);
        layout->addWidget(hint);
        layout->addStretch();

        return tab;
    }

    void refreshSubjectList() {
        m_subjectList->clear();
        for (const auto &s : m_parser.subjects()) {
            QVariantMap subj = s.toMap();
            QString text = subj["name"].toString();
            if (!subj["simplified_name"].toString().isEmpty())
                text += " (" + subj["simplified_name"].toString() + ")";
            if (!subj["teacher"].toString().isEmpty())
                text += " - " + subj["teacher"].toString();
            m_subjectList->addItem(text);
        }
    }

    void onDayChanged(int index) {
        m_scheduleTable->setRowCount(0);
        QVariantList classes = m_parser.getClassesForDay(index + 1);
        for (int i = 0; i < classes.size(); i++) {
            QVariantMap cls = classes[i].toMap();
            int row = m_scheduleTable->rowCount();
            m_scheduleTable->insertRow(row);

            QComboBox *subjCombo = new QComboBox;
            for (const auto &s : m_parser.subjects()) {
                subjCombo->addItem(s.toMap()["name"].toString());
            }
            subjCombo->setCurrentText(cls["subject"].toString());
            m_scheduleTable->setCellWidget(row, 0, subjCombo);

            QLineEdit *startEdit = new QLineEdit;
            startEdit->setText(cls["start_time"].toString());
            m_scheduleTable->setCellWidget(row, 1, startEdit);

            QLineEdit *endEdit = new QLineEdit;
            endEdit->setText(cls["end_time"].toString());
            m_scheduleTable->setCellWidget(row, 2, endEdit);

            QComboBox *typeCombo = new QComboBox;
            typeCombo->addItems({"class", "break", "activity", "free"});
            typeCombo->setCurrentText(cls.contains("type") ? cls["type"].toString() : "class");
            m_scheduleTable->setCellWidget(row, 3, typeCombo);
        }
    }

    void onAddEntry() {
        int day = m_dayCombo->currentIndex() + 1;
        QVariantMap cls;
        cls["subject"] = m_parser.subjects().isEmpty() ? "未命名" : m_parser.subjects().first().toMap()["name"].toString();
        cls["start_time"] = "08:00:00";
        cls["end_time"] = "08:40:00";
        cls["type"] = "class";
        m_parser.addClassEntry(day, cls);
        onDayChanged(m_dayCombo->currentIndex());
    }

    void onExport() {
        saveCurrentEdits();
        QString path = QFileDialog::getSaveFileName(this, "导出课表", "", "CSES 文件 (*.yml *.yaml)");
        if (path.isEmpty()) return;
        if (m_parser.exportToFile(path)) {
            QMessageBox::information(this, "成功", "课表已导出！");
        } else {
            QMessageBox::warning(this, "失败", "导出失败。");
        }
    }

    void saveCurrentEdits() {
        int day = m_dayCombo->currentIndex() + 1;
        QVariantList classes;
        for (int row = 0; row < m_scheduleTable->rowCount(); row++) {
            QVariantMap cls;
            QComboBox *subjCombo = qobject_cast<QComboBox*>(m_scheduleTable->cellWidget(row, 0));
            QLineEdit *startEdit = qobject_cast<QLineEdit*>(m_scheduleTable->cellWidget(row, 1));
            QLineEdit *endEdit = qobject_cast<QLineEdit*>(m_scheduleTable->cellWidget(row, 2));
            QComboBox *typeCombo = qobject_cast<QComboBox*>(m_scheduleTable->cellWidget(row, 3));
            cls["subject"] = subjCombo ? subjCombo->currentText() : "";
            cls["start_time"] = startEdit ? startEdit->text() : "08:00:00";
            cls["end_time"] = endEdit ? endEdit->text() : "08:40:00";
            cls["type"] = typeCombo ? typeCombo->currentText() : "class";
            classes.append(cls);
        }
        m_parser.updateDayClasses(day, classes);
    }
};

#endif