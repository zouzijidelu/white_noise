import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes/app_route_path.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'diy_screen.dart';
import 'meditation_list_screen.dart';
import 'sleep_screen.dart';
import 'wooden_fish_screen.dart';

/// 主壳：底部导航 + 当前 Tab 对应的页面
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  final AppRoutePath currentPath;
  final ValueChanged<AppRoutePath> onNavigate;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    // 监听系统返回键事件
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'popRoute') {
        // 拦截返回键，让应用退到后台而不是关闭
        SystemNavigator.pop();
        return Future.value(true);
      }
      return Future.value(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 拦截返回键，让应用退到后台而不是关闭
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: widget.currentPath.index,
          children: const [
            SleepScreen(),
            DiyScreen(),
            MeditationListScreen(),
            WoodenFishScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: widget.currentPath.index,
          onTap: (index) => widget.onNavigate(AppRoutePath.values[index]),
        ),
      ),
    );
  }
}
