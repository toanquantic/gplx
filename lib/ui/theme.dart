import 'package:flutter/material.dart';

/// Bảng màu theo mockup "Mockup app Ôn thi GPLX" (xanh lá, nền ngà nhạt).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.borderStrong,
    required this.track,
    required this.accent,
    required this.onAccent,
    required this.onAccentMuted,
    required this.accentSoft,
    required this.tile,
    required this.danger,
    required this.dangerSoft,
    required this.onDangerSoft,
    required this.warnSoft,
    required this.warnIcon,
    required this.onWarnSoft,
    required this.partial,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color borderStrong;

  /// Nền thanh tiến độ, nền nút chọn hạng.
  final Color track;
  final Color accent;
  final Color onAccent;
  final Color onAccentMuted;
  final Color accentSoft;

  /// Ô số liệu nhỏ (số câu, phút) trong thẻ trắng.
  final Color tile;
  final Color danger;
  final Color dangerSoft;
  final Color onDangerSoft;
  final Color warnSoft;
  final Color warnIcon;
  final Color onWarnSoft;

  /// Thanh điểm của nhóm câu chưa đúng hết.
  final Color partial;

  static const light = AppColors(
    background: Color(0xFFF3F6F1),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF142019),
    muted: Color(0xFF4A5A4F),
    border: Color(0xFFDCE5DA),
    borderStrong: Color(0xFFC9D6C7),
    track: Color(0xFFE3EBE1),
    accent: Color(0xFF1B6E3A),
    onAccent: Color(0xFFFFFFFF),
    onAccentMuted: Color(0xFFE2F1E5),
    accentSoft: Color(0xFFDCEEDF),
    tile: Color(0xFFEEF4EC),
    danger: Color(0xFFA8231B),
    dangerSoft: Color(0xFFFBE3E0),
    onDangerSoft: Color(0xFF7E1A14),
    warnSoft: Color(0xFFFBEBD2),
    warnIcon: Color(0xFFF5D6A6),
    onWarnSoft: Color(0xFF6B3A00),
    partial: Color(0xFFC8812A),
  );

  static const dark = AppColors(
    background: Color(0xFF0F1712),
    surface: Color(0xFF18231C),
    text: Color(0xFFE6EEE7),
    muted: Color(0xFFA9B8AD),
    border: Color(0xFF2A3A30),
    borderStrong: Color(0xFF3A4D41),
    track: Color(0xFF243229),
    accent: Color(0xFF3FA866),
    onAccent: Color(0xFF06140B),
    onAccentMuted: Color(0xFF0F2B18),
    accentSoft: Color(0xFF1D3A27),
    tile: Color(0xFF203027),
    danger: Color(0xFFF07A70),
    dangerSoft: Color(0xFF3D1C19),
    onDangerSoft: Color(0xFFF7C1BB),
    warnSoft: Color(0xFF3A2A12),
    warnIcon: Color(0xFF5A421D),
    onWarnSoft: Color(0xFFF3D3A3),
    partial: Color(0xFFE0A050),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 || other == null ? this : other;
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

const appFont = 'BeVietnamPro';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.light.accent, brightness: brightness)
      .copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.background,
        onSurface: c.text,
        error: c.danger,
        errorContainer: c.dangerSoft,
        onErrorContainer: c.onDangerSoft,
        outline: c.borderStrong,
        outlineVariant: c.border,
      );
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: appFont,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
  );
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const buttonText = TextStyle(fontFamily: appFont, fontSize: 15, fontWeight: FontWeight.w600);
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: appFont,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: c.text,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: buttonShape,
        backgroundColor: c.surface,
        foregroundColor: c.text,
        side: BorderSide(color: c.borderStrong),
        textStyle: buttonText,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.borderStrong),
      ),
    ),
  );
}

/// Thẻ trắng viền mảnh dùng khắp app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  /// Null là viền mặc định; [Colors.transparent] là không viền.
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == Colors.transparent
          ? BorderSide.none
          : BorderSide(color: borderColor ?? c.border),
    );
    return Material(
      color: color ?? c.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Ô vuông bo góc chứa icon, như ở đầu các thẻ menu.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 40,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.3)),
    child: Icon(icon, color: foreground, size: size * 0.55),
  );
}

/// Thanh tiến độ mảnh bo tròn.
class ThinBar extends StatelessWidget {
  const ThinBar({super.key, required this.value, this.color, this.height = 6});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: c.track,
        color: color ?? c.accent,
      ),
    );
  }
}
