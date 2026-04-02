import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Fill width for easier access
      height: 100, // Large height for shaky hands (cite: 300, 305)
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}