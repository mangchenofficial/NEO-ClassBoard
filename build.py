#!/usr/bin/env python3
"""
NEO ClassBoard - 跨平台构建脚本
支持 Windows、Linux、macOS 一键打包
用法: python build.py [clean]
"""

import os
import sys
import shutil
import subprocess
import platform

if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')


PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SPEC_FILE = os.path.join(PROJECT_ROOT, "build.spec")
DIST_DIR = os.path.join(PROJECT_ROOT, "dist")
BUILD_DIR = os.path.join(PROJECT_ROOT, "build_pyinstaller")
ICONS_DIR = os.path.join(PROJECT_ROOT, "icons")


def detect_platform():
    plat = platform.system().lower()
    if plat == 'windows':
        return 'windows'
    elif plat == 'linux':
        return 'linux'
    elif plat == 'darwin':
        return 'macos'
    else:
        print(f"[!] 不支持的平台: {plat}")
        sys.exit(1)


def clean():
    dirs_to_clean = [BUILD_DIR, DIST_DIR]
    for d in dirs_to_clean:
        if os.path.isdir(d):
            print(f"[*] 清理: {d}")
            shutil.rmtree(d)
    spec_backup = os.path.join(PROJECT_ROOT, "build.spec.bak")
    if os.path.isfile(spec_backup):
        os.remove(spec_backup)
    for root, dirs, files in os.walk(PROJECT_ROOT):
        if '__pycache__' in dirs:
            p = os.path.join(root, '__pycache__')
            print(f"[*] 清理: {p}")
            shutil.rmtree(p)


def generate_png_icon():
    png_path = os.path.join(ICONS_DIR, "logo.png")
    if os.path.exists(png_path):
        return
    svg_path = os.path.join(ICONS_DIR, "logo.svg")
    if not os.path.exists(svg_path):
        print("[!] 未找到 logo.svg，无法生成 logo.png")
        return
    try:
        from PySide6.QtGui import QGuiApplication, QImage, QPainter
        from PySide6.QtSvg import QSvgRenderer
        app = QGuiApplication(sys.argv)
        svg = QSvgRenderer(svg_path)
        size = svg.defaultSize()
        if size.width() <= 0:
            size = svg.viewBoxF().size()
            if size.width() <= 0:
                size.setWidth(256)
                size.setHeight(256)
        img = QImage(int(size.width()), int(size.height()), QImage.Format_ARGB32)
        img.fill(0)
        painter = QPainter(img)
        svg.render(painter)
        painter.end()
        img.save(png_path)
        print(f"[*] 已生成: {png_path} ({img.width()}x{img.height()})")
    except Exception as e:
        print(f"[!] 生成 logo.png 失败: {e}")


def generate_icns_icon():
    if sys.platform != 'darwin':
        return
    icns_path = os.path.join(ICONS_DIR, "logo.icns")
    if os.path.exists(icns_path):
        return
    png_path = os.path.join(ICONS_DIR, "logo.png")
    if not os.path.exists(png_path):
        generate_png_icon()
    if not os.path.exists(png_path):
        print("[!] 无法生成 logo.icns：缺少 logo.png")
        return
    try:
        from PIL import Image
        img = Image.open(png_path)
        sizes = [16, 32, 64, 128, 256, 512]
        icon_sizes = []
        for s in sizes:
            icon_sizes.append(img.resize((s, s), Image.LANCZOS))
        icon_sizes[0].save(icns_path, format='ICNS', append_images=icon_sizes[1:])
        print(f"[*] 已生成: {icns_path}")
    except ImportError:
        print("[!] 未安装 Pillow，跳过 logo.icns 生成（PyInstaller 可自动转换）")
    except Exception as e:
        print(f"[!] 生成 logo.icns 失败: {e}")


def check_requirements():
    try:
        import PyInstaller
        print(f"[*] PyInstaller 版本: {PyInstaller.__version__}")
    except ImportError:
        print("[!] 未安装 PyInstaller，请运行: pip install pyinstaller")
        sys.exit(1)

    try:
        import PySide6
        print(f"[*] PySide6 版本: {PySide6.__version__}")
    except ImportError:
        print("[!] 未安装 PySide6，请运行: pip install PySide6>=6.6")
        sys.exit(1)
    except Exception as e:
        print(f"[!] PySide6 导入异常 (headless CI 可忽略): {e}")

    plat = detect_platform()
    if plat == 'linux':
        missing = []
        for lib in ['libxcb-cursor.so.0', 'libxkbcommon-x11.so.0']:
            try:
                import ctypes
                ctypes.cdll.LoadLibrary(lib)
            except OSError:
                missing.append(lib)
        if missing:
            print("[!] Linux 缺少 Qt 运行时依赖:")
            for m in missing:
                print(f"    - {m}")
            print("    请运行: sudo apt-get install libxcb-cursor0 libxcb-icccm4 libxcb-image0 "
                  "libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 "
                  "libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xinerama0 "
                  "libxcb-xkb1 libxkbcommon-x11-0 libgl1 libegl1 libdbus-1-3")


def print_size(path):
    if os.path.isfile(path):
        size_mb = os.path.getsize(path) / (1024 * 1024)
        print(f"    大小: {size_mb:.1f} MB")
    elif os.path.isdir(path):
        total = 0
        for root, dirs, files in os.walk(path):
            for f in files:
                total += os.path.getsize(os.path.join(root, f))
        print(f"    大小: {total / (1024 * 1024):.1f} MB")


def build():
    plat = detect_platform()
    print(f"[*] 目标平台: {plat}")
    print(f"[*] 当前系统: {platform.system()} {platform.release()}")

    if not os.path.isfile(SPEC_FILE):
        print(f"[!] 未找到 spec 文件: {SPEC_FILE}")
        sys.exit(1)

    if plat in ('linux', 'macos'):
        generate_png_icon()
        generate_icns_icon()

    cmd = [
        sys.executable, "-m", "PyInstaller",
        "--clean",
        "--noconfirm",
        "--distpath", DIST_DIR,
        "--workpath", BUILD_DIR,
        SPEC_FILE,
    ]

    print(f"[*] 执行: {' '.join(cmd)}")
    sys.stdout.flush()
    result = subprocess.run(cmd, cwd=PROJECT_ROOT)

    if result.returncode != 0:
        print(f"[!] 构建失败! 退出码: {result.returncode}")
        sys.exit(result.returncode)

    print("\n[✓] 构建成功!")
    print(f"[*] 输出目录: {DIST_DIR}")

    if plat == 'macos':
        app_path = os.path.join(DIST_DIR, "ClassBoard.app")
        if os.path.exists(app_path):
            print(f"[*] macOS App: {app_path}")
            print_size(app_path)
    elif plat == 'windows':
        exe_path = os.path.join(DIST_DIR, "ClassBoard.exe")
        if os.path.exists(exe_path):
            print(f"[*] Windows 可执行文件: {exe_path}")
            print_size(exe_path)
    else:
        exe_path = os.path.join(DIST_DIR, "ClassBoard")
        if os.path.exists(exe_path):
            print(f"[*] Linux 可执行文件: {exe_path}")
            print_size(exe_path)


def main():
    print("=" * 50)
    print("  NEO ClassBoard - 跨平台构建工具")
    print("=" * 50)

    if len(sys.argv) > 1 and sys.argv[1] == 'clean':
        clean()
        print("[✓] 清理完成")
        return

    check_requirements()
    build()


if __name__ == "__main__":
    main()