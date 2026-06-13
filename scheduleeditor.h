#ifndef SCHEDULEEDITOR_H
#define SCHEDULEEDITOR_H

#include <QDialog>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QFrame>
#include <QListWidget>
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
#include "csesparser.h"

class ScheduleEditor : public QDialog
{
public:
    explicit ScheduleEditor(CsesParser &parser, QWidget *parent = nullptr)
        : QDialog(parent), m_parser(parser)
    {
        setWindowTitle("课表编辑器");
        setFixedSize(720, 520);
        setStyleSheet(
            "QDialog { background-color: #FEF7FF; }"
            "QLabel { color: #1C1B1F; font-size: 13px; }"
            "QLineEdit, QSpinBox, QTimeEdit, QComboBox { padding: 6px 10px; border: 1px solid #CAC4D0; "
            "border-radius: 8px; background: #F3EDF7; font-size: 13px; }"
            "QPushButton { background-color: #0B57D0; color: white; border: none; "
            "border-radius: 20px; padding: 8px 20px; font-size: 13px; font-weight: bold; }"
            "QPushButton:hover { background-color: #0842A0; }"
            "QPushButton#dangerBtn { background-color: #B3261E; }"
            "QPushButton#dangerBtn:hover { background-color: #8C1D18; }"
            "QPushButton#secondaryBtn { background-color: transparent; color: #6750A4; border: 1px solid #79747E; }"
            "QPushButton#secondaryBtn:hover { background-color: #F3EDF7; }"
            "QTabWidget::pane { border: 1px solid #CAC4D0; border-radius: 8px; background: #FEF7FF; }"
            "QTabBar::tab { padding: 8px 16px; border: 1px solid #CAC4D0; border-bottom: none; "
            "border-radius: 8px 8px 0 0; background: #F3EDF7; color: #49454F; font-size: 12px; }"
            "QTabBar::tab:selected { background: #FEF7FF; color: #6750A4; font-weight: bold; }"
            "QListWidget { border: 1px solid #CAC4D0; border-radius: 8px; background: #FEF7FF; padding: 4px; }"
            "QListWidget::item { padding: 6px; border-radius: 6px; }"
            "QListWidget::item:selected { background: #D3E3FD; color: #0B57D0; }"
            "QTableWidget { border: 1px solid #CAC4D0; border-radius: 8px; background: #FEF7FF; "
            "gridline-color: #CAC4D0; }"
            "QTableWidget::item { padding: 4px; }"
            "QHeaderView::section { background: #F3EDF7; color: #49454F; border: 1px solid #CAC4D0; "
            "padding: 6px; font-weight: bold; }"
        );

        QVBoxLayout *mainLayout = new QVBoxLayout(this);
        mainLayout->setContentsMargins(16, 16, 16, 16);
        mainLayout->setSpacing(12);

        QLabel *title = new QLabel("课表编辑器");
        title->setStyleSheet("font-size: 22px; font-weight: bold; color: #1C1B1F;");
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

        editLayout->addWidget(new QLabel("科目名称:"));
        QLineEdit *nameEdit = new QLineEdit;
        editLayout->addWidget(nameEdit);

        editLayout->addWidget(new QLabel("简称:"));
        QLineEdit *simplifiedEdit = new QLineEdit;
        editLayout->addWidget(simplifiedEdit);

        editLayout->addWidget(new QLabel("教师:"));
        QLineEdit *teacherEdit = new QLineEdit;
        editLayout->addWidget(teacherEdit);

        editLayout->addWidget(new QLabel("教室:"));
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
        topRow->addWidget(new QLabel("选择星期:"));
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
        hint->setStyleSheet("font-size: 14px; color: #49454F; padding: 20px;");
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

            QTimeEdit *startEdit = new QTimeEdit;
            startEdit->setDisplayFormat("HH:mm:ss");
            startEdit->setTime(QTime::fromString(cls["start_time"].toString(), "HH:mm:ss"));
            m_scheduleTable->setCellWidget(row, 1, startEdit);

            QTimeEdit *endEdit = new QTimeEdit;
            endEdit->setDisplayFormat("HH:mm:ss");
            endEdit->setTime(QTime::fromString(cls["end_time"].toString(), "HH:mm:ss"));
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
            QTimeEdit *startEdit = qobject_cast<QTimeEdit*>(m_scheduleTable->cellWidget(row, 1));
            QTimeEdit *endEdit = qobject_cast<QTimeEdit*>(m_scheduleTable->cellWidget(row, 2));
            QComboBox *typeCombo = qobject_cast<QComboBox*>(m_scheduleTable->cellWidget(row, 3));
            cls["subject"] = subjCombo ? subjCombo->currentText() : "";
            cls["start_time"] = startEdit ? startEdit->time().toString("HH:mm:ss") : "08:00:00";
            cls["end_time"] = endEdit ? endEdit->time().toString("HH:mm:ss") : "08:40:00";
            cls["type"] = typeCombo ? typeCombo->currentText() : "class";
            classes.append(cls);
        }
        m_parser.updateDayClasses(day, classes);
    }
};

#endif
