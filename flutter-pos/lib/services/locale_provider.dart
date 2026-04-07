import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  bool _isUrdu = false;

  bool get isUrdu => _isUrdu;
  AppStrings get strings => AppStrings(isUrdu: _isUrdu);

  TextStyle? get urduFontStyle =>
      _isUrdu ? GoogleFonts.notoNastaliqUrdu() : null;

  ThemeData get theme {
    if (_isUrdu) {
      final urduTextTheme =
          GoogleFonts.notoNastaliqUrduTextTheme(AppTheme.dark.textTheme);
      return AppTheme.dark.copyWith(textTheme: urduTextTheme);
    }
    return AppTheme.dark;
  }

  void toggle() {
    _isUrdu = !_isUrdu;
    notifyListeners();
  }
}
