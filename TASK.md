# Lugmatic Artist Studio - Alignment Plan

## Current State Assessment
- **Framework**: Flutter (Dart)
- **Branding**: None (Default Flutter assets)
- **Design System**: None (Using standard Material defaults)
- **Structure**: Basic `lib/main.dart`
- **Missing Features**:
    - Custom Launcher Icons
    - Native Splash Screen (matching `#0F172A`)
    - Shared Color Palette (Primary: `#86E560`)
    - Shared Typography (DM Sans, Bebas Neue)

## Proposed Changes

### [Branding]
- Copy `icon.png` and `splash.png` from `lugmatic_flutter`.
- Configure `flutter_launcher_icons` in `pubspec.yaml`.
- Configure `flutter_native_splash` in `pubspec.yaml`.

### [Design System]
- Port `app_colors.dart` with shared brand tokens.
- Port `app_theme.dart` (Material 3 with custom fonts).

### [Structure]
- Create `lib/core/theme`, `lib/core/constants`, `lib/core/network`.

## Task List
- [ ] Install missing dev dependencies (`flutter_launcher_icons`, `flutter_native_splash`)
- [ ] Create `assets/images` directory and copy branding files
- [ ] Port `AppColors` and `AppTheme` classes
- [ ] Update `main.dart` to use `AppTheme.darkTheme`
- [ ] Generate native assets (`flutter pub run ...`)
