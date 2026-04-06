import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'services/cart_provider.dart';
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
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const SlicePosApp(),
    ),
  );
}

class SlicePosApp extends StatelessWidget {
  const SlicePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahmed Fast Food - POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
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

  static const _navItems = [
    _NavItem(Icons.point_of_sale_outlined, Icons.point_of_sale_rounded, 'POS', 'Point of Sale'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders', 'Orders'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Sales', 'Sales History'),
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard', 'Dashboard'),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Products', 'Manage Products'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (Breakpoints.isDesktop(width)) return _buildDesktopLayout();
    if (Breakpoints.isTablet(width))  return _buildTabletLayout();
    return _buildPhoneLayout();
  }

  // ── Desktop (≥ 900px) — full sidebar ────────────────────────────

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

  Widget _buildSidebar() => Container(
    width: 240,
    color: AppColors.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Image.asset(
            'assets/images/logo.png',
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 28),
        _sidebarItem(0),
        _sidebarItem(1),
        _sidebarItem(2),
        _sidebarItem(3),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Divider(color: AppColors.divider, height: 1),
        ),
        _sidebarItem(4),
        const Spacer(),
        Consumer<CartProvider>(
          builder: (_, cart, __) => cart.items.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${cart.itemCount} in cart',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _sidebarItem(int index) {
    final item = _navItems[index];
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: AppColors.primary.withOpacity(0.25)) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              item.longLabel,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: selected ? 1 : 0);
  }

  // ── Tablet (600–900px) — navigation rail ────────────────────────

  Widget _buildTabletLayout() => Scaffold(
    backgroundColor: AppColors.background,
    body: Row(
      children: [
        _buildNavigationRail(),
        Container(width: 1, color: AppColors.divider),
        Expanded(child: _pages[_selectedIndex]),
      ],
    ),
  );

  Widget _buildNavigationRail() => SafeArea(
    right: false,
    child: NavigationRail(
      backgroundColor: AppColors.surface,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      labelType: NavigationRailLabelType.all,
      minWidth: 72,
      minExtendedWidth: 160,
      useIndicator: true,
      indicatorColor: AppColors.primary.withOpacity(0.18),
      selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 22),
      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted, size: 22),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
      ),
      leading: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Image.asset(
          'assets/images/logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      destinations: _navItems.map((item) => NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.activeIcon),
        label: Text(item.shortLabel),
        padding: const EdgeInsets.symmetric(vertical: 2),
      )).toList(),
    ),
  );

  // ── Phone (< 600px) — bottom navigation bar ──────────────────────

  Widget _buildPhoneLayout() => Scaffold(
    backgroundColor: AppColors.background,
    body: _pages[_selectedIndex],
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: _navItems.map((item) => NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon, color: AppColors.primary),
            label: item.shortLabel,
          )).toList(),
        ),
      ),
    ),
  );
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String shortLabel;
  final String longLabel;
  const _NavItem(this.icon, this.activeIcon, this.shortLabel, this.longLabel);
}
