import 'package:flutter/material.dart';

import '../data/asset.dart';

const _seed = Color(0xFF1F5FA8);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final radius = BorderRadius.circular(16);
  final text = Typography.material2021(platform: TargetPlatform.android)
      .englishLike
      .merge(
        brightness == Brightness.light
            ? Typography.material2021().black
            : Typography.material2021().white,
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFF6F7FA)
        : scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      // Filled fields with no outline; the label sits inside the fill.
      border: const UnderlineInputBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: UnderlineInputBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
    ),
  );
}

/// Category colours, one per asset type in a fixed order so a category keeps
/// its colour everywhere (chart, legend, list avatar). Values come from a
/// colour-blind-checked palette, stepped separately for dark mode.
Color categoryColor(AssetType type, Brightness brightness) {
  final light = brightness == Brightness.light;
  return switch (type) {
    AssetType.lifeInsurance =>
      light ? const Color(0xFF2A78D6) : const Color(0xFF3987E5),
    AssetType.metal =>
      light ? const Color(0xFFEB6834) : const Color(0xFFD95926),
    AssetType.fixedDeposit =>
      light ? const Color(0xFF1BAF7A) : const Color(0xFF199E70),
    AssetType.bankAccount =>
      light ? const Color(0xFFEDA100) : const Color(0xFFC98500),
    AssetType.realEstate =>
      light ? const Color(0xFFE87BA4) : const Color(0xFFD55181),
    AssetType.other => const Color(0xFF008300),
    AssetType.healthInsurance =>
      light ? const Color(0xFF4A3AA7) : const Color(0xFF9085E9),
    AssetType.termInsurance =>
      light ? const Color(0xFFE34948) : const Color(0xFFE66767),
  };
}

IconData iconFor(AssetType type) => switch (type) {
  AssetType.lifeInsurance => Icons.shield_outlined,
  AssetType.healthInsurance => Icons.health_and_safety_outlined,
  AssetType.termInsurance => Icons.verified_user_outlined,
  AssetType.metal => Icons.diamond_outlined,
  AssetType.fixedDeposit => Icons.savings_outlined,
  AssetType.bankAccount => Icons.account_balance_outlined,
  AssetType.realEstate => Icons.home_work_outlined,
  AssetType.other => Icons.category_outlined,
};

/// Round icon in the category's colour, used in lists and the add sheet.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar(this.type, {super.key, this.size = 40});

  final AssetType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(type, Theme.of(context).brightness);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(iconFor(type), color: color, size: size * 0.55),
    );
  }
}

/// Card with an optional title row, the building block of each screen.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
