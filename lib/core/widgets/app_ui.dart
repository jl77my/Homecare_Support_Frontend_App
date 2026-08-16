import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppPageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppPageTitle({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 28)),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(subtitle!, style: const TextStyle(fontSize: 15, color: AppTheme.textMuted, height: 1.35)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const AppSectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy))),
          if (trailing != null) trailing!,
        ]),
      );
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppTheme.borderLight),
        boxShadow: const [BoxShadow(color: Color(0x0A071B42), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: child,
    );
    if (onTap == null) return surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: surface),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  const AppPrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(icon ?? Icons.arrow_forward_rounded, size: 20),
          label: Text(label),
          style: color == null ? null : ElevatedButton.styleFrom(backgroundColor: color),
        ),
      );
}

class InitialAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const InitialAvatar({super.key, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE4F2FF),
      child: Text(initials.isEmpty ? 'HC' : initials, style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700, fontSize: radius * .72)),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusPill({super.key, required this.label, this.color = AppTheme.primaryGreen, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withOpacity(.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon ?? Icons.circle, size: icon == null ? 9 : 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(width: 54, height: 5, margin: const EdgeInsets.only(top: 10, bottom: 14), decoration: BoxDecoration(color: const Color(0xFFB5BDC9), borderRadius: BorderRadius.circular(3))),
      );
}
