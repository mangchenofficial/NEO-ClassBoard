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
        setFixedSize(820, 600);
        setStyleSheet(QString("QDialog { background-color: %1; }").arg(m_surface));

        QVBoxLayout *mainLayout = new QVBoxLayout(this);
        mainLayout->setContentsMargins(20, 20, 20, 16);
        mainLayout->setSpacing(16);

        QLabel *title = new QLabel("课表编辑器");
        title->setStyleSheet(QString("font-size: 24px; font-weight: bold; color: %1;").arg(m_onSurface));
        mainLayout->addWidget(title);

        QTabWidget *tabs = new QTabWidget;
        tabs->setStyleSheet(tabStyle());
        tabs->addTab(createSubjectsTab(), "科目");
        tabs->addTab(createTimelineTab(), "时间线");
        tabs->addTab(createScheduleTab(), "课程表");
        mainLayout->addWidget(tabs, 1);

        QHBoxLayout *bottomRow = new QHBoxLayout;
        bottomRow->addStretch();
        QPushButton *exportBtn = new QPushButton("导出课表");
        exportBtn->setMinimumHeight(36);
        exportBtn->setStyleSheet(primaryBtnStyle());
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

    QString tabStyle() {
        return QString(
            "QTabWidget::pane { border: none; background: %1; padding: 4px 0 0 0; }"
            "QTabBar::tab { padding: 12px 24px; border: none; border-bottom: 3px solid transparent; "
            "background: transparent; color: %2; font-size: 14px; font-weight: 500; min-width: 80px; }"
            "QTabBar::tab:selected { color: %3; border-bottom: 3px solid %3; }"
            "QTabBar::tab:hover { background: %4; border-radius: 12px 12px 0 0; }"
        ).arg(m_surface, m_onSurfaceVariant, m_primary, m_primaryContainer);
    }

    QString inputStyle() {
        return QString(
            "QLineEdit { padding: 10px 14px; border: 1px solid %1; border-radius: 8px; "
            "background: %2; font-size: 14px; color: %3; min-height: 20px; }"
            "QLineEdit:focus { border-color: %4; border-width: 2px; padding: 9px 13px; }"
        ).arg(m_outlineVariant, m_surfaceContainer, m_onSurface, m_primary);
    }

    QString comboStyle() {
        return QString(
            "QComboBox { padding: 10px 14px; border: 1px solid %1; border-radius: 8px; "
            "background: %2; font-size: 14px; color: %3; min-height: 20px; }"
            "QComboBox:focus { border-color: %4; border-width: 2px; padding: 9px 13px; }"
            "QComboBox::drop-down { width: 28px; border: none; subcontrol-position: center right; "
            "subcontrol-origin: padding; }"
            "QComboBox::down-arrow { width: 12px; height: 12px; }"
            "QComboBox QAbstractItemView { background: %2; color: %3; border: 1px solid %1; "
            "border-radius: 8px; padding: 6px; selection-background-color: %5; outline: none; }"
            "QComboBox QAbstractItemView::item { min-height: 36px; padding: 8px 12px; }"
        ).arg(m_outlineVariant, m_surfaceContainer, m_onSurface, m_primary, m_primaryContainer);
    }

    QString listStyle() {
        return QString(
            "QListWidget { border: 1px solid %1; border-radius: 12px; background: %2; "
            "padding: 6px; font-size: 14px; color: %3; outline: none; }"
            "QListWidget::item { padding: 12px 14px; border-radius: 8px; min-height: 22px; }"
            "QListWidget::item:selected { background: %4; color: %5; }"
            "QListWidget::item:hover { background: %6; }"
        ).arg(m_outlineVariant, m_surface, m_onSurface, m_primaryContainer, m_primary, m_surfaceContainer);
    }

    QString tableStyle() {
        return QString(
            "QTableWidget { border: 1px solid %1; border-radius: 12px; background: %2; "
            "gridline-color: %1; outline: none; }"
            "QTableWidget::item { padding: 8px 12px; color: %3; }"
            "QTableWidget::item:selected { background: %4; color: %3; }"
            "QHeaderView::section { background: %5; color: %6; border: none; border-bottom: 2px solid %1; "
            "padding: 12px 14px; font-weight: bold; font-size: 13px; min-height: 20px; }"
            "QTableWidget QComboBox, QTableWidget QLineEdit { border: none; background: transparent; "
            "padding: 8px; font-size: 14px; color: %3; min-height: 22px; }"
            "QTableWidget QComboBox::drop-down { width: 24px; }"
            "QTableWidget QComboBox::down-arrow { width: 10px; height: 10px; }"
        ).arg(m_outlineVariant, m_surface, m_onSurface, m_primaryContainer, m_surfaceContainer, m_onSurface);
    }

    QString primaryBtnStyle() {
        return QString(
            "QPushButton { background-color: %1; color: %2; border: none; "
            "border-radius: 20px; padding: 10px 28px; font-size: 14px; font-weight: bold; min-height: 20px; }"
            "QPushButton:hover { background-color: %3; }"
        ).arg(m_primary, m_onPrimary, m_primaryContainer);
    }

    QString dangerBtnStyle() {
        return QString(
            "QPushButton { background-color: %1; color: %2; border: none; "
            "border-radius: 20px; padding: 10px 28px; font-size: 14px; font-weight: bold; min-height: 20px; }"
            "QPushButton:hover { background-color: %3; }"
        ).arg(m_error, m_onError, m_primaryContainer);
    }

    QLabel* makeLabel(const QString &text, const QString &color) {
        QLabel *lbl = new QLabel(text);
        lbl->setStyleSheet(QString("font-size: 14px; color: %1; padding: 0;").arg(color));
        return lbl;
    }

    QWidget* createSubjectsTab() {
        QWidget *tab = new QWidget;
        QHBoxLayout *layout = new QHBoxLayout(tab);
        layout->setSpacing(20);
        layout->setContentsMargins(4, 8, 4, 8);

        m_subjectList = new QListWidget;
        m_subjectList->setStyleSheet(listStyle());
        m_subjectList->setMinimumWidth(280);
        refreshSubjectList();
        layout->addWidget(m_subjectList, 1);

        QWidget *editPanel = new QWidget;
        editPanel->setStyleSheet(QString("background-color: %1; border-radius: 12px;").arg(m_surfaceContainer));
        QVBoxLayout *editLayout = new QVBoxLayout(editPanel);
        editLayout->setContentsMargins(16, 16, 16, 16);
        editLayout->setSpacing(8);

        editLayout->addWidget(makeLabel("科目名称", m_onSurface));
        QLineEdit *nameEdit = new QLineEdit;
        nameEdit->setStyleSheet(inputStyle());
        nameEdit->setPlaceholderText("如：语文");
        editLayout->addWidget(nameEdit);

        editLayout->addWidget(makeLabel("简称", m_onSurface));
        QLineEdit *simplifiedEdit = new QLineEdit;
        simplifiedEdit->setStyleSheet(inputStyle());
        simplifiedEdit->setPlaceholderText("如：语");
        editLayout->addWidget(simplifiedEdit);

        editLayout->addWidget(makeLabel("教师", m_onSurface));
        QLineEdit *teacherEdit = new QLineEdit;
        teacherEdit->setStyleSheet(inputStyle());
        teacherEdit->setPlaceholderText("可选");
        editLayout->addWidget(teacherEdit);

        editLayout->addWidget(makeLabel("教室", m_onSurface));
        QLineEdit *roomEdit = new QLineEdit;
        roomEdit->setStyleSheet(inputStyle());
        roomEdit->setPlaceholderText("可选");
        editLayout->addWidget(roomEdit);

        editLayout->addSpacing(4);

        QPushButton *addBtn = new QPushButton("添加科目");
        addBtn->setMinimumHeight(36);
        addBtn->setStyleSheet(primaryBtnStyle());
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
        delBtn->setMinimumHeight(36);
        delBtn->setStyleSheet(dangerBtnStyle());
        connect(delBtn, &QPushButton::clicked, this, [=]() {
            int row = m_subjectList->currentRow();
            if (row >= 0) {
                m_parser.removeSubject(row);
                refreshSubjectList();
            }
        });
        editLayout->addWidget(delBtn);

        editLayout->addStretch();
        layout->addWidget(editPanel, 1);
        return tab;
    }

    QWidget* createTimelineTab() {
        QWidget *tab = new QWidget;
        QVBoxLayout *layout = new QVBoxLayout(tab);
        layout->setSpacing(16);
        layout->setContentsMargins(4, 8, 4, 8);

        QHBoxLayout *topRow = new QHBoxLayout;
        topRow->setSpacing(12);
        topRow->addWidget(makeLabel("选择星期", m_onSurface));
        m_dayCombo = new QComboBox;
        m_dayCombo->addItems({"周一", "周二", "周三", "周四", "周五", "周六", "周日"});
        m_dayCombo->setStyleSheet(comboStyle());
        m_dayCombo->setFixedWidth(150);
        connect(m_dayCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &ScheduleEditor::onDayChanged);
        topRow->addWidget(m_dayCombo);
        topRow->addStretch();
        layout->addLayout(topRow);

        m_scheduleTable = new QTableWidget(0, 4);
        m_scheduleTable->setHorizontalHeaderLabels({"科目", "开始时间", "结束时间", "类型"});
        m_scheduleTable->horizontalHeader()->setStretchLastSection(true);
        m_scheduleTable->horizontalHeader()->setSectionResizeMode(0, QHeaderView::Stretch);
        m_scheduleTable->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Fixed);
        m_scheduleTable->horizontalHeader()->setSectionResizeMode(2, QHeaderView::Fixed);
        m_scheduleTable->setColumnWidth(1, 120);
        m_scheduleTable->setColumnWidth(2, 120);
        m_scheduleTable->verticalHeader()->setVisible(false);
        m_scheduleTable->verticalHeader()->setDefaultSectionSize(46);
        m_scheduleTable->setSelectionBehavior(QTableWidget::SelectRows);
        m_scheduleTable->setAlternatingRowColors(false);
        m_scheduleTable->setShowGrid(true);
        m_scheduleTable->setStyleSheet(tableStyle());
        layout->addWidget(m_scheduleTable, 1);

        QHBoxLayout *btnRow = new QHBoxLayout;
        btnRow->setSpacing(12);
        QPushButton *addEntryBtn = new QPushButton("添加课程");
        addEntryBtn->setMinimumHeight(36);
        addEntryBtn->setStyleSheet(primaryBtnStyle());
        connect(addEntryBtn, &QPushButton::clicked, this, &ScheduleEditor::onAddEntry);
        btnRow->addWidget(addEntryBtn);

        QPushButton *delEntryBtn = new QPushButton("删除选中行");
        delEntryBtn->setMinimumHeight(36);
        delEntryBtn->setStyleSheet(dangerBtnStyle());
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
        layout->setContentsMargins(60, 80, 60, 80);
        layout->setSpacing(16);

        QLabel *hint = new QLabel("在「时间线」标签页中按星期编辑课程\n在「科目」标签页中管理科目信息\n\n编辑完成后点击下方「导出课表」保存为 CSES 文件");
        hint->setStyleSheet(QString("font-size: 15px; color: %1; line-height: 1.8;").arg(m_onSurfaceVariant));
        hint->setWordWrap(true);
        hint->setAlignment(Qt::AlignCenter);
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
            subjCombo->setStyleSheet(
                "QComboBox { border: none; background: transparent; font-size: 14px; color: " + m_onSurface + "; padding: 8px; }"
                "QComboBox QAbstractItemView { background: " + m_surfaceContainer + "; color: " + m_onSurface + "; "
                "border: 1px solid " + m_outlineVariant + "; border-radius: 8px; padding: 6px; "
                "selection-background-color: " + m_primaryContainer + "; }"
                "QComboBox QAbstractItemView::item { min-height: 36px; padding: 8px 12px; }"
                "QComboBox::drop-down { width: 24px; border: none; }"
                "QComboBox::down-arrow { width: 10px; height: 10px; }"
            );
            m_scheduleTable->setCellWidget(row, 0, subjCombo);

            QLineEdit *startEdit = new QLineEdit;
            startEdit->setText(cls["start_time"].toString());
            startEdit->setStyleSheet("border: none; background: transparent; font-size: 14px; color: " + m_onSurface + "; padding: 8px;");
            m_scheduleTable->setCellWidget(row, 1, startEdit);

            QLineEdit *endEdit = new QLineEdit;
            endEdit->setText(cls["end_time"].toString());
            endEdit->setStyleSheet("border: none; background: transparent; font-size: 14px; color: " + m_onSurface + "; padding: 8px;");
            m_scheduleTable->setCellWidget(row, 2, endEdit);

            QComboBox *typeCombo = new QComboBox;
            typeCombo->addItems({"class", "break", "activity", "free"});
            typeCombo->setCurrentText(cls.contains("type") ? cls["type"].toString() : "class");
            typeCombo->setStyleSheet(
                "QComboBox { border: none; background: transparent; font-size: 14px; color: " + m_onSurface + "; padding: 8px; }"
                "QComboBox QAbstractItemView { background: " + m_surfaceContainer + "; color: " + m_onSurface + "; "
                "border: 1px solid " + m_outlineVariant + "; border-radius: 8px; padding: 6px; "
                "selection-background-color: " + m_primaryContainer + "; }"
                "QComboBox QAbstractItemView::item { min-height: 36px; padding: 8px 12px; }"
                "QComboBox::drop-down { width: 24px; border: none; }"
                "QComboBox::down-arrow { width: 10px; height: 10px; }"
            );
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