from PySide6.QtCore import QObject, Signal, Slot, Property, Qt
from PySide6.QtGui import QColor, QGuiApplication

LIGHT_SCHEME = {
    "primary": "#6750A4", "onPrimaryColor": "#FFFFFF",
    "primaryContainer": "#EADDFF", "onPrimaryContainerColor": "#21005D",
    "secondary": "#625B71", "onSecondaryColor": "#FFFFFF",
    "secondaryContainer": "#E8DEF8", "onSecondaryContainerColor": "#1D192B",
    "tertiary": "#7D5260", "onTertiaryColor": "#FFFFFF",
    "tertiaryContainer": "#FFD8E4", "onTertiaryContainerColor": "#31111D",
    "error": "#B3261E", "onErrorColor": "#FFFFFF",
    "errorContainer": "#F9DEDC", "onErrorContainerColor": "#410E0B",
    "background": "#FFFBFE", "onBackgroundColor": "#1C1B1F",
    "surface": "#FFFBFE", "onSurfaceColor": "#1C1B1F",
    "surfaceVariant": "#E7E0EC", "onSurfaceVariantColor": "#49454F",
    "outline": "#79747E", "outlineVariant": "#CAC4D0",
    "shadow": "#000000", "scrim": "#000000",
    "inverseSurface": "#313033", "inverseOnSurface": "#F4EFF4",
    "inversePrimary": "#D0BCFF",
    "surfaceDim": "#DED8E1", "surfaceBright": "#FEF7FF",
    "surfaceContainerLowest": "#FFFFFF", "surfaceContainerLow": "#F7F2FA",
    "surfaceContainer": "#F3EDF7", "surfaceContainerHigh": "#ECE6F0",
    "surfaceContainerHighest": "#E6E0E9",
}

DARK_SCHEME = {
    "primary": "#D0BCFF", "onPrimaryColor": "#381E72",
    "primaryContainer": "#4F378B", "onPrimaryContainerColor": "#EADDFF",
    "secondary": "#CCC2DC", "onSecondaryColor": "#332D41",
    "secondaryContainer": "#4A4458", "onSecondaryContainerColor": "#E8DEF8",
    "tertiary": "#EFB8C8", "onTertiaryColor": "#492532",
    "tertiaryContainer": "#633B48", "onTertiaryContainerColor": "#FFD8E4",
    "error": "#F2B8B5", "onErrorColor": "#601410",
    "errorContainer": "#8C1D18", "onErrorContainerColor": "#F9DEDC",
    "background": "#1C1B1F", "onBackgroundColor": "#E6E1E5",
    "surface": "#1C1B1F", "onSurfaceColor": "#E6E1E5",
    "surfaceVariant": "#49454F", "onSurfaceVariantColor": "#CAC4D0",
    "outline": "#938F99", "outlineVariant": "#49454F",
    "shadow": "#000000", "scrim": "#000000",
    "inverseSurface": "#E6E0E9", "inverseOnSurface": "#322F35",
    "inversePrimary": "#6750A4",
    "surfaceDim": "#141218", "surfaceBright": "#3B383E",
    "surfaceContainerLowest": "#0F0D13", "surfaceContainerLow": "#1C1B1F",
    "surfaceContainer": "#211F26", "surfaceContainerHigh": "#2B2930",
    "surfaceContainerHighest": "#36343B",
}


class StyleManager(QObject):
    isDarkThemeChanged = Signal()
    seedColorChanged = Signal()
    currentSchemeChanged = Signal()
    lightSchemeChanged = Signal()
    darkSchemeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._is_dark_theme = False
        self._seed_color = QColor("#6750a4")
        self._current_scheme = dict(LIGHT_SCHEME)
        self._light_scheme = dict(LIGHT_SCHEME)
        self._dark_scheme = dict(DARK_SCHEME)

        app = QGuiApplication.instance()
        if app:
            style_hints = app.styleHints()
            self._is_dark_theme = style_hints.colorScheme() == Qt.ColorScheme.Dark
            style_hints.colorSchemeChanged.connect(self._on_color_scheme_changed)
        self._update_scheme()

    def _on_color_scheme_changed(self, scheme):
        self.setIsDarkTheme(scheme == Qt.ColorScheme.Dark)

    @Property(bool, notify=isDarkThemeChanged)
    def isDarkTheme(self):
        return self._is_dark_theme

    def setIsDarkTheme(self, is_dark: bool):
        if self._is_dark_theme != is_dark:
            self._is_dark_theme = is_dark
            self.isDarkThemeChanged.emit()
            self._update_scheme()

    @Property('QColor', notify=seedColorChanged)
    def seedColor(self):
        return self._seed_color

    def setSeedColor(self, color):
        color = QColor(color)
        if self._seed_color != color:
            self._seed_color = color
            self.seedColorChanged.emit()
            self._update_scheme()

    @Property(float, notify=seedColorChanged)
    def hctHue(self):
        return self._seed_color.hueF()

    @Property(float, notify=seedColorChanged)
    def hctChroma(self):
        return self._seed_color.saturationF()

    @Property(float, notify=seedColorChanged)
    def hctTone(self):
        return self._seed_color.lightnessF()

    @Property(dict, notify=currentSchemeChanged)
    def currentScheme(self):
        return self._current_scheme

    @Property(dict, notify=lightSchemeChanged)
    def lightScheme(self):
        return self._light_scheme

    @Property(dict, notify=darkSchemeChanged)
    def darkScheme(self):
        return self._dark_scheme

    @Slot(float, float, float)
    def setSeedColorHct(self, hue: float, chroma: float, tone: float):
        color = QColor.fromHslF(hue % 1.0, chroma, tone)
        self.setSeedColor(color)

    @Slot('QUrl')
    def setSourceImage(self, file_url):
        pass

    def _update_scheme(self):
        self._current_scheme = dict(DARK_SCHEME if self._is_dark_theme else LIGHT_SCHEME)
        self.lightSchemeChanged.emit()
        self.darkSchemeChanged.emit()
        self.currentSchemeChanged.emit()