import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OverlayInfo extends StatelessWidget {
  const OverlayInfo({
    super.key,
    required this.lines,
  });

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withOpacity(0.35),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: lines
                .map(
                  (String value) => Text(
                    value,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.2,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
