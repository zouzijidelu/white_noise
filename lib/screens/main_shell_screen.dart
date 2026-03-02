import 'package:flutter/material.dart';

import '../routes/app_route_path.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'diy_screen.dart';
import 'meditation_screen.dart';
import 'sleep_screen.dart';
import 'wooden_fish_screen.dart';

/// 主壳：底部导航 + 当前 Tab 对应的页面
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  final AppRoutePath currentPath;
  final ValueChanged<AppRoutePath> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentPath.index,
        children: const [
          SleepScreen(),
          DiyScreen(),
          MeditationScreen(),
          WoodenFishScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentPath.index,
        onTap: (index) => onNavigate(AppRoutePath.values[index]),
      ),
    );
  }
}
