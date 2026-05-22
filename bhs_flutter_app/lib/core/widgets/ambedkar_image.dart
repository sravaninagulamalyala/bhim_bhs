import 'package:flutter/material.dart';

class AmbedkarImage extends StatelessWidget {
  const AmbedkarImage({
    super.key,
    this.size = 120,
    this.rounded = true,
    this.showShadow = false,
  });

  final double size;
  final bool rounded;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final radius = rounded ? BorderRadius.circular(size / 2) : BorderRadius.circular(12);
    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/ambedkar.jpg',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.account_balance, size: size * 0.52, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
