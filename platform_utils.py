import os
import sys
import subprocess
import shutil

IS_WINDOWS = sys.platform == 'win32'
IS_MACOS = sys.platform == 'darwin'
IS_LINUX = sys.platform.startswith('linux')


def app_data_dir() -> str:
    if IS_WINDOWS:
        base = os.environ.get('APPDATA', os.path.expanduser('~'))
        return os.path.join(base, 'ClassBoard')
    elif IS_MACOS:
        return os.path.join(os.path.expanduser('~'), 'Library', 'Application Support', 'ClassBoard')
    else:
        xdg = os.environ.get('XDG_DATA_HOME', os.path.join(os.path.expanduser('~'), '.local', 'share'))
        return os.path.join(xdg, 'ClassBoard')


def config_dir() -> str:
    if IS_WINDOWS:
        base = os.environ.get('APPDATA', os.path.expanduser('~'))
        return os.path.join(base, 'ClassBoard')
    elif IS_MACOS:
        return os.path.join(os.path.expanduser('~'), 'Library', 'Preferences', 'ClassBoard')
    else:
        xdg = os.environ.get('XDG_CONFIG_HOME', os.path.join(os.path.expanduser('~'), '.config'))
        return os.path.join(xdg, 'ClassBoard')


def get_autostart_dir() -> str:
    if IS_WINDOWS:
        return os.path.join(os.environ.get('APPDATA', ''), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
    elif IS_MACOS:
        return os.path.join(os.path.expanduser('~'), 'Library', 'LaunchAgents')
    else:
        xdg = os.environ.get('XDG_CONFIG_HOME', os.path.join(os.path.expanduser('~'), '.config'))
        return os.path.join(xdg, 'autostart')


def is_autostart_enabled() -> bool:
    if IS_WINDOWS:
        try:
            import winreg
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                                r"Software\Microsoft\Windows\CurrentVersion\Run") as key:
                winreg.QueryValueEx(key, "ClassBoard")
                return True
        except (FileNotFoundError, OSError):
            return False
    elif IS_MACOS:
        plist = os.path.join(get_autostart_dir(), 'com.neo.classboard.plist')
        return os.path.exists(plist)
    else:
        desktop = os.path.join(get_autostart_dir(), 'classboard.desktop')
        return os.path.exists(desktop)


def set_autostart(enabled: bool) -> None:
    app_path = _get_app_path()
    if not app_path:
        return

    if IS_WINDOWS:
        _set_autostart_windows(enabled, app_path)
    elif IS_MACOS:
        _set_autostart_macos(enabled, app_path)
    else:
        _set_autostart_linux(enabled, app_path)


def _get_app_path() -> str:
    if getattr(sys, 'frozen', False):
        return sys.executable
    return sys.executable


def _set_autostart_windows(enabled: bool, app_path: str) -> None:
    try:
        import winreg
        key_path = r"Software\Microsoft\Windows\CurrentVersion\Run"
        if enabled:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_SET_VALUE) as key:
                winreg.SetValueEx(key, "ClassBoard", 0, winreg.REG_SZ, app_path)
        else:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_SET_VALUE) as key:
                winreg.DeleteValue(key, "ClassBoard")
    except (FileNotFoundError, OSError):
        pass


def _set_autostart_macos(enabled: bool, app_path: str) -> None:
    autostart_dir = get_autostart_dir()
    os.makedirs(autostart_dir, exist_ok=True)
    plist_path = os.path.join(autostart_dir, 'com.neo.classboard.plist')

    if not enabled:
        if os.path.exists(plist_path):
            os.remove(plist_path)
        return

    plist_content = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.neo.classboard</string>
    <key>ProgramArguments</key>
    <array>
        <string>{}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>'''.format(app_path)
    with open(plist_path, 'w', encoding='utf-8') as f:
        f.write(plist_content)


def _set_autostart_linux(enabled: bool, app_path: str) -> None:
    autostart_dir = get_autostart_dir()
    os.makedirs(autostart_dir, exist_ok=True)
    desktop_path = os.path.join(autostart_dir, 'classboard.desktop')

    if not enabled:
        if os.path.exists(desktop_path):
            os.remove(desktop_path)
        return

    desktop_content = '''[Desktop Entry]
Type=Application
Name=NEO ClassBoard
Exec={}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Classroom Schedule Board
'''.format(app_path)
    with open(desktop_path, 'w', encoding='utf-8') as f:
        f.write(desktop_content)


def ensure_single_instance() -> bool:
    if IS_WINDOWS:
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            h_mutex = kernel32.CreateMutexW(None, True, "ClassBoard_SingleInstance_Mutex")
            if kernel32.GetLastError() == 183:
                from PySide6.QtWidgets import QMessageBox
                QMessageBox.warning(None, "ClassBoard", "已有程序正在运行，请勿重复启动。")
                return False
            return True
        except Exception:
            return True
    elif IS_MACOS or IS_LINUX:
        import fcntl
        lock_file = os.path.join(config_dir(), '.classboard.lock')
        os.makedirs(os.path.dirname(lock_file), exist_ok=True)
        global _lock_fd
        try:
            _lock_fd = open(lock_file, 'w')
            fcntl.flock(_lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return True
        except (IOError, OSError):
            from PySide6.QtWidgets import QMessageBox
            QMessageBox.warning(None, "ClassBoard", "已有程序正在运行，请勿重复启动。")
            return False
    return True


def set_window_bottom(hwnd_int: int) -> None:
    if not IS_WINDOWS:
        return
    try:
        import ctypes
        from ctypes import wintypes
        user32 = ctypes.windll.user32
        hwnd = wintypes.HWND(hwnd_int)
        GWL_EXSTYLE = -20
        WS_EX_TOPMOST = 0x00000008
        HWND_BOTTOM = wintypes.HWND(1)
        flags = 0x0001 | 0x0002 | 0x0020
        exstyle = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
        exstyle &= ~WS_EX_TOPMOST
        user32.SetWindowLongW(hwnd, GWL_EXSTYLE, exstyle)
        user32.SetWindowPos(hwnd, HWND_BOTTOM, 0, 0, 0, 0, flags)
        user32.UpdateWindow(hwnd)
    except Exception:
        pass


def set_window_topmost(hwnd_int: int) -> None:
    if not IS_WINDOWS:
        return
    try:
        import ctypes
        from ctypes import wintypes
        user32 = ctypes.windll.user32
        hwnd = wintypes.HWND(hwnd_int)
        GWL_EXSTYLE = -20
        WS_EX_TOPMOST = 0x00000008
        HWND_TOPMOST = wintypes.HWND(-1)
        flags = 0x0001 | 0x0002 | 0x0020
        exstyle = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
        exstyle |= WS_EX_TOPMOST
        user32.SetWindowLongW(hwnd, GWL_EXSTYLE, exstyle)
        user32.SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, flags)
        user32.UpdateWindow(hwnd)
    except Exception:
        pass


def show_error_dialog(title: str, message: str) -> None:
    if IS_WINDOWS:
        try:
            import ctypes
            ctypes.windll.user32.MessageBoxW(0, str(message), str(title), 0x10)
        except Exception:
            print(f"[{title}] {message}")
    else:
        print(f"[{title}] {message}")