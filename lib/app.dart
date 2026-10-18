import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/history/history_screen.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'ui/screens/add_expense/add_expense_screen.dart';

class LexspenseApp extends ConsumerStatefulWidget {
  const LexspenseApp({super.key});

  @override
  ConsumerState<LexspenseApp> createState() => _LexspenseAppState();
}

class _LexspenseAppState extends ConsumerState<LexspenseApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleWidgetLaunch();
    _listenToWidgetClicks();
  }

  /// Handle cold start from home widget.
  Future<void> _handleWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null && uri.host == 'add') {
      // Wait for the navigator to be ready, then push Add screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const AddExpenseScreen(fromWidget: true),
          ),
        );
      });
    }
  }

  /// Handle tap on widget while app is already running.
  void _listenToWidgetClicks() {
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null && uri.host == 'add') {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const AddExpenseScreen(fromWidget: true),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Lexspense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}

/// Bottom navigation shell with 3 tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh widget data when app comes to foreground.
      // Widget sync is handled via afterMutation and lifecycle.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
