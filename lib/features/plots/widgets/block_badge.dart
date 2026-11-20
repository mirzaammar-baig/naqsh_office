import 'package:flutter/material.dart';

// Block ka badge: naam lamba ho to dabba chora ho jata hai, toot'ta nahi.
class BlockBadge extends StatelessWidget {
  const BlockBadge({
    super.key,
    required this.code,
    required this.color,
    this.size = 46,
    this.filled = false,
    this.radius = 14,
  });

  final String code;
  final Color color;

  // Chhote naam par dabba size x size ka rehta hai.
  final double size;

  // true ho to rang ka bhara dabba aur safed text.
  final bool filled;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fontSize = code.length <= 3
        ? size * 0.43
        : (code.length <= 6 ? size * 0.32 : size * 0.27);

    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
        maxWidth: size * 2.6,
      ),
      padding: EdgeInsets.symmetric(horizontal: size * 0.2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        code,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}