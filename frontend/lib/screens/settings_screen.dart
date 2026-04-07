import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;

    final bgColor     = isDark ? AppColors.darkBackground     : AppColors.background;
    final surfColor   = isDark ? AppColors.darkSurface        : AppColors.surface;
    final textColor   = isDark ? AppColors.darkText           : AppColors.text;
    final subColor    = isDark ? AppColors.darkTextLight      : AppColors.textLight;
    final borderColor = isDark ? AppColors.darkBorder         : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          app.t('settings'),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance section ────────────────────────────────
          _SectionLabel(label: app.t('appearance'), color: subColor),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              // Dark / Light mode toggle
              _SettingsTile(
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor: const Color(0xFF9B8FFF),
                iconBg: const Color(0xFFEDE9FF),
                title: app.t('dark_mode'),
                titleColor: textColor,
                subtitleColor: subColor,
                trailing: _PastelSwitch(
                  value: isDark,
                  onChanged: (v) => app.setThemeMode(
                    v ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
                isDark: isDark,
                borderColor: borderColor,
                showDivider: true,
              ),
              // Language selector
              _SettingsTile(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF8FD9C8),
                iconBg: const Color(0xFFDFF7F2),
                title: app.t('language'),
                titleColor: textColor,
                subtitleColor: subColor,
                trailing: _LanguageToggle(
                  current: app.language,
                  onChanged: (lang) => app.setLanguage(lang),
                ),
                isDark: isDark,
                borderColor: borderColor,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── General section ───────────────────────────────────
          _SectionLabel(label: app.t('general'), color: subColor),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.notifications_rounded,
                iconColor: const Color(0xFFFFABC8),
                iconBg: const Color(0xFFFFEDF4),
                title: app.t('notifications'),
                titleColor: textColor,
                subtitleColor: subColor,
                trailing: _PastelSwitch(
                  value: app.notificationsEnabled,
                  onChanged: (v) => app.setNotifications(v),
                ),
                isDark: isDark,
                borderColor: borderColor,
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF9B8FFF).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Color titleColor;
  final Color subtitleColor;
  final Widget trailing;
  final bool isDark;
  final Color borderColor;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.titleColor,
    required this.subtitleColor,
    required this.trailing,
    required this.isDark,
    required this.borderColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withOpacity(0.15) : iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 68,
            endIndent: 0,
            color: borderColor,
          ),
      ],
    );
  }
}

class _PastelSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PastelSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: AppColors.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFDDD9F5),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final AppLanguage current;
  final ValueChanged<AppLanguage> onChanged;
  const _LanguageToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangBtn(
            label: 'VI',
            selected: current == AppLanguage.vi,
            onTap: () => onChanged(AppLanguage.vi),
          ),
          _LangBtn(
            label: 'EN',
            selected: current == AppLanguage.en,
            onTap: () => onChanged(AppLanguage.en),
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textLight,
          ),
        ),
      ),
    );
  }
}