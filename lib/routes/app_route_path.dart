/// 应用路由路径，对应底部导航的四个 Tab
enum AppRoutePath {
  /// 定时睡眠
  sleep,

  /// DIY 白噪音
  diy,

  /// 冥想列表
  meditationList,

  /// 功德（木鱼）
  woodenFish,
}

extension AppRoutePathExtension on AppRoutePath {
  String get path {
    switch (this) {
      case AppRoutePath.sleep:
        return '/sleep';
      case AppRoutePath.diy:
        return '/diy';
      case AppRoutePath.meditationList:
        return '/meditationList';
      case AppRoutePath.woodenFish:
        return '/wooden_fish';
    }
  }

  static AppRoutePath fromPath(String? path) {
    switch (path) {
      case '/sleep':
        return AppRoutePath.sleep;
      case '/diy':
        return AppRoutePath.diy;
      case '/meditationList':
        return AppRoutePath.meditationList;
      case '/wooden_fish':
        return AppRoutePath.woodenFish;
      default:
        return AppRoutePath.sleep;
    }
  }
}
