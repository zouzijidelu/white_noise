import 'package:flutter/material.dart';

/// 底部导航栏：睡眠、DIY、冥想、木鱼
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.nightlight_round),
          label: '睡眠',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.tune),
          label: 'DIY',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.self_improvement),
          label: '冥想',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: '木鱼',
        ),
      ],
    );
  }
}
