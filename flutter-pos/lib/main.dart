import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'services/cart_provider.dart';
import 'services/locale_provider.dart';
import 'screens/pos_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'theme/app_theme.dart';
import 'theme/breakpoints.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const SlicePosApp(),
    ),
  );
}

class SlicePosApp extends StatelessWidget {
  const SlicePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return MaterialApp(
      title: 'Ahmed Fast Food - POS',
      debugShowCheckedModeBanner: false,
      theme: locale.theme,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.ltr,
        child: child!,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final _pages = const [
    PosScreen(),
    OrdersScreen(),
    SalesScreen(),
    DashboardScreen(),
    ProductsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (Breakpoints.isDesktop(width)) return _buildDesktopLayout();
    if (Breakpoints.isTablet(width)) return _buildTabletLayout();
    return _buildPhoneLayout();
  }

  List<_NavItem> _navItems(s) => [
        _NavItem(Icons.point_of_sale_outlined, Icons.point_of_sale_rounded,
            s.navPos, s.navPosLong),
        _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded,
            s.navOrders, s.navOrders),
        _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, s.navSales,
            s.navSalesLong),
        _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded,
            s.navDashboard, s.navDashboard),
        _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded,
            s.navProducts, s.navProductsLong),
      ];

  // ── Desktop ─────────────────────────────────────────────────────
  Widget _buildDesktopLayout() => Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildSidebar(),
            Container(width: 1, color: AppColors.divider),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      );

  Widget _buildSidebar() {
    final locale = context.watch<LocaleProvider>();
    final s = locale.strings;
    final navItems = _navItems(s);
    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Image.asset('assets/images/logo.png',
                height: 48, fit: BoxFit.contain),
          ),
          const SizedBox(height: 28),
          _sidebarItem(0, navItems),
          _sidebarItem(1, navItems),
          _sidebarItem(2, navItems),
          _sidebarItem(3, navItems),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          _sidebarItem(4, navItems),
          const Spacer(),
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.items.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${cart.items.length} ${s.itemsLabel}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _buildLangToggle(locale),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'Developed by TAYYAB',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangToggle(LocaleProvider locale) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: InkWell(
          onTap: locale.toggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.language_rounded,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locale.strings.switchLang,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      );

  Widget _sidebarItem(int index, List<_NavItem> navItems) {
    final item = navItems[index];
    final selected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.longLabel,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tablet ───────────────────────────────────────────────────────
  Widget _buildTabletLayout() {
    final locale = context.watch<LocaleProvider>();
    final s = locale.strings;
    final navItems = _navItems(s);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                Expanded(
                  child: NavigationRail(
                    backgroundColor: AppColors.surface,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) =>
                        setState(() => _selectedIndex = i),
                    selectedIconTheme:
                        const IconThemeData(color: AppColors.primary),
                    selectedLabelTextStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                    unselectedIconTheme:
                        const IconThemeData(color: AppColors.textSecondary),
                    unselectedLabelTextStyle:
                        const TextStyle(color: AppColors.textSecondary),
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Image.asset('assets/images/logo.png',
                          height: 40, fit: BoxFit.contain),
                    ),
                    destinations: navItems
                        .map((item) => NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.activeIcon),
                              label: Text(item.shortLabel),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                            ))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: locale.toggle,
                    tooltip: s.switchLang,
                    icon: const Icon(Icons.language_rounded,
                        color: AppColors.textSecondary),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'Dev: TAYYAB',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Container(width: 1, color: AppColors.divider),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  // ── Phone ────────────────────────────────────────────────────────
  Widget _buildPhoneLayout() {
    final locale = context.watch<LocaleProvider>();
    final s = locale.strings;
    final navItems = _navItems(s);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  indicatorColor: AppColors.primary.withOpacity(0.15),
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: navItems
                      .map((item) => NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.activeIcon,
                                color: AppColors.primary),
                            label: item.shortLabel,
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: locale.toggle,
                  tooltip: s.switchLang,
                  icon: const Icon(Icons.language_rounded,
                      color: AppColors.textSecondary, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String shortLabel;
  final String longLabel;
  const _NavItem(this.icon, this.activeIcon, this.shortLabel, this.longLabel);
}
