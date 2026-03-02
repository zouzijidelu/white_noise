import 'package:flutter/foundation.dart';

import '../routes/app_route_path.dart';

/// 导航状态，供 Navigator 2.0 与底部导航同步
class NavigationProvider extends ChangeNotifier {
  AppRoutePath _currentPath = AppRoutePath.sleep;

  AppRoutePath get currentPath => _currentPath;

  int get currentIndex {
    switch (_currentPath) {
      case AppRoutePath.sleep:
        return 0;
      case AppRoutePath.diy:
        return 1;
      case AppRoutePath.meditation:
        return 2;
      case AppRoutePath.woodenFish:
        return 3;
    }
  }

  void goTo(AppRoutePath path) {
    if (_currentPath == path) return;
    _currentPath = path;
    notifyListeners();
  }

  void goToIndex(int index) {
    final path = AppRoutePath.values[index];
    goTo(path);
  }
}
