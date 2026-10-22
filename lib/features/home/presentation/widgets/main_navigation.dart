import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/account/presentation/pages/account_screen.dart';
import 'package:kincare/features/orders/presentation/screens/orders_screen.dart';
import 'package:kincare/features/stock/presentation/pages/stock_screen.dart';

class MainNavigation extends StatefulWidget {
  final String? initialRoute;

  const MainNavigation({super.key, this.initialRoute});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const StockScreen(),
    const OrdersScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _resolveIndexFromRoute(widget.initialRoute);

    // Technical: Listen for background push postMessage events when tab is already alive
    if (kIsWeb) {
      _setupServiceWorkerMessageListener();
    }
  }

  @override
  void didUpdateWidget(covariant MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Technical: Switch active tab dynamically when parent passes an updated route
    if (widget.initialRoute != null && widget.initialRoute != oldWidget.initialRoute) {
      _applyRoute(widget.initialRoute);
    }
  }

  // Technical: Captures NAVIGATE_TAB event from Service Worker to switch tabs smoothly
  void _setupServiceWorkerMessageListener() {
    web.window.navigator.serviceWorker.addEventListener(
      'message',
      ((web.Event event) {
        final messageEvent = event as web.MessageEvent;
        final data = messageEvent.data;
        if (data != null && data.isA<JSObject>()) {
          final jsObj = data as JSObject;
          final msgType = jsObj.getProperty<JSString?>('type'.toJS)?.toDart;
          if (msgType == 'NAVIGATE_TAB') {
            final route = jsObj.getProperty<JSString?>('route'.toJS)?.toDart;
            _applyRoute(route);
          }
        }
      }).toJS,
    );
  }

  void _applyRoute(String? route) {
    final targetIndex = _resolveIndexFromRoute(route);
    if (targetIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = targetIndex;
      });
    }
  }

  // Technical: Maps known routes to the corresponding IndexedStack position
  int _resolveIndexFromRoute(String? route) {
    if (route == null) return 0;
    if (route.contains('/orders')) return 1;
    if (route.contains('/account')) return 2;
    return 0; // Default: /stock
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBgColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.transparent, width: 0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          backgroundColor: scaffoldBgColor,
          selectedItemColor: KinColors.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Estoque',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Conta',
            ),
          ],
        ),
      ),
    );
  }
}