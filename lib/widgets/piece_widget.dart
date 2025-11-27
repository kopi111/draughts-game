import 'package:flutter/material.dart';
import '../models/piece.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;
  final bool isSelected;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.size,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = piece.color == PieceColor.black
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFC41E3A);

    final highlightColor = piece.color == PieceColor.black
        ? const Color(0xFF4A4A4A)
        : const Color(0xFFE84A5F);

    return Container(
      width: size * 0.75,
      height: size * 0.75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [highlightColor, baseColor],
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(3, 3),
          ),
          if (isSelected)
            BoxShadow(
              color: Colors.yellow.withValues(alpha: 0.8),
              blurRadius: 12,
              spreadRadius: 4,
            ),
        ],
        border: Border.all(
          color: isSelected ? Colors.yellow : Colors.black87,
          width: isSelected ? 3 : 2,
        ),
      ),
      child: piece.isKing
          ? Center(
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                    center: Alignment(-0.2, -0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.white,
                  size: size * 0.2,
                ),
              ),
            )
          : null,
    );
  }
}
