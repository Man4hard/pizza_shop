class Breakpoints {
  static const double phone = 600;

  static bool isPhone(double w) => w < phone;
  static bool isDesktop(double w) => w >= phone;
  static bool isWide(double w) => w >= phone;
}
