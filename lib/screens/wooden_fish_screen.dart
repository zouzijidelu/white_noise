import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/merit_provider.dart';

/// 功德页：电子木鱼，点击累积功德
class WoodenFishScreen extends StatelessWidget {
  const WoodenFishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '功德',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '通过敲电子木鱼功能实现心理舒缓',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 48),
              Consumer<MeritProvider>(
                builder: (_, merit, __) {
                  return Column(
                    children: [
                      Text(
                        '${merit.count}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text('累积功德: ${merit.count}'),
                    ],
                  );
                },
              ),
              const Spacer(),
              Consumer<MeritProvider>(
                builder: (_, merit, __) {
                  return GestureDetector(
                    onTap: merit.increment,
                    child: Icon(
                      Icons.pets,
                      size: 120,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
