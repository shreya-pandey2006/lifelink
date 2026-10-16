import 'package:flutter/material.dart';
import '../core/theme.dart';
InputDecoration fieldDecoration({ String? hint, IconData? icon, Widget? suffix, String? prefixText,}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder( borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c));
   const line = Color(0xFFEDE7EA);
  return InputDecoration(
    hintText: hint,hintStyle: const TextStyle(color: Color(0xFFA9A9B3)), prefixIcon: icon == null ? null : Icon(icon, color: kMuted), prefixText: prefixText,
    prefixStyle: const TextStyle(color: kInk, fontWeight: FontWeight.w600), suffixIcon: suffix, filled: true,fillColor: Colors.white,contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: border(line),enabledBorder: border(line), focusedBorder: border(kPrimary), errorBorder: border(Colors.red),focusedErrorBorder: border(Colors.red),
  );
}
class FieldLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  const FieldLabel(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding( padding: const EdgeInsets.only(bottom: 8),
      child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle( fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }
}
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({ super.key, required this.label, this.icon, this.onPressed, this.loading = false});
  @override
  Widget build(BuildContext context) {
    return SizedBox( width: double.infinity,height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom( backgroundColor: kPrimary,foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 3,shadowColor: kPrimary.withValues(alpha: 0.4) ),
        onPressed: loading ? null : onPressed,
        child: loading ? const SizedBox(height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle( fontSize: 16, fontWeight: FontWeight.w700)),
                  if (icon != null) ...[ const SizedBox(width: 8),Icon(icon, size: 20) ],
                ],
              ),
      ),
    );
  }
}
class Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  const Pill(
    this.text, {
    super.key, this.background = kPrimarySoft, this.foreground = kPrimaryDark,
  });
  @override
  Widget build(BuildContext context) {
    return Container( padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration( color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle( fontSize: 11,fontWeight: FontWeight.w800, letterSpacing: 0.5, color: foreground)),
    );
  }
}
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 80});
  @override
  Widget build(BuildContext context) {
    return Container( width: size,height: size, decoration: const BoxDecoration( color: Colors.white,shape: BoxShape.circle,
        boxShadow: [ BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)) ],
      ),
      child: Icon(Icons.water_drop, color: kPrimaryDark, size: size * 0.5),
    );
  }
}
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) {
    return Container( width: double.infinity, padding: padding,
      decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: const [ BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6)) ],
      ),
      child: child,
    );
  }
}