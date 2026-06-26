# -*- mode: python ; coding: utf-8 -*-
import os
from PyInstaller.utils.hooks import collect_dynamic_libs

pyside6_dir = os.path.dirname(__import__('PySide6').__file__)
qml_src = os.path.join(pyside6_dir, 'qml')

qml_modules = ['Qt', 'QtCore', 'QtQml', 'QtQuick', 'QtMultimedia', 'QtNetwork']

datas = [
    ('main.qml', '.'),
    ('SettingsDialog.qml', '.'),
    ('ClassSwapDialog.qml', '.'),
    ('ClassList.qml', '.'),
    ('ComponentSettingsPage.qml', '.'),
    ('Icon.qml', '.'),
    ('NextClassWidget.qml', '.'),
    ('Settings.qml', '.'),
    ('TimeSection.qml', '.'),
    ('classboard_plugin.py', '.'),
    ('plugin_manager.py', '.'),
    ('PluginIcon.qml', '.'),
    ('PluginSettingsPage.qml', '.'),
    ('plugins', 'plugins'),
    ('md3', 'md3'),
    ('MiSans', 'MiSans'),
    ('icons', 'icons'),
]

for mod in qml_modules:
    src = os.path.join(qml_src, mod)
    if os.path.exists(src):
        datas.append((src, os.path.join('qml', mod)))

for fname in ('builtins.qmltypes', 'jsroot.qmltypes'):
    src = os.path.join(qml_src, fname)
    if os.path.exists(src):
        datas.append((src, 'qml'))

binaries = []
binaries += collect_dynamic_libs('PySide6')

hiddenimports = [
    'PySide6.QtMultimedia',
    'PySide6.QtQml',
    'PySide6.QtQuick',
]

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['tkinter', 'PySide6.QtWebEngineCore', 'PySide6.QtWebEngineWidgets', 'PySide6.QtQuick3D'],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='ClassBoard',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    icon='icons/logo.ico',
)