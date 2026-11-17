import 'package:flutter/material.dart';

/// Colour palette. NOTE: the master plan (section 14) was not available when
/// this was written; adjust these values there if the plan differs. Screens
/// must read colours from here or from Theme, never hard-code them.
class AppColors {
  static const Color primary = Color(0xFF283593); // indigo 800
  static const Color secondary = Color(0xFF00897B); // teal 600

  // Attendance statuses (used by the attendance chips and reports).
  static const Color present = Color(0xFF2E7D32);
  static const Color absent = Color(0xFFC62828);
  static const Color late = Color(0xFFEF6C00);
  static const Color excused = Color(0xFF546E7A);
}
