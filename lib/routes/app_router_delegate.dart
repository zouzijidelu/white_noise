import 'package:flutter/material.dart';

import '../providers/navigation_provider.dart';
import '../screens/main_shell_screen.dart';

/// Navigator 2.0 路由委托，根据 [NavigationProvider] 的当前路径构建 Navigator 栈
class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  AppRouterDelegate({
    required this.navigationProvider,
  }) {
    navigationProvider.addListener(_onNavigationChanged);
  }

  final NavigationProvider navigationProvider;

  void _onNavigationChanged() {
    notifyListeners();
  }

  @override
  GlobalKey<NavigatorState>? get navigatorKey => GlobalKey<NavigatorState>();

  @override
  void dispose() {
    navigationProvider.removeListener(_onNavigationChanged);
    super.dispose();
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {
    // 由 RouteInformationParser 解析后的 configuration 可在此处理（当前用 Provider 驱动，可不实现）
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => MainShellScreen(
            currentPath: navigationProvider.currentPath,
            onNavigate: navigationProvider.goTo,
          ),
        );
      },
    );
  }
}
