import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/weather_palette.dart';

class ShellSectionTitle extends StatelessWidget {
  final String title;

  const ShellSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: MausamPalette.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
