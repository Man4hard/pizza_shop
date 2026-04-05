class Breakpoints {
  static const double phone = 600;
  static const double desktop = 900;

  static bool isPhone(double w) => w < phone;
  static bool isTablet(double w) => w >= phone && w < desktop;
  static bool isDesktop(double w) => w >= desktop;
  static bool isWide(double w) => w >= phone;
}
