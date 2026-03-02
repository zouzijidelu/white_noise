import 'package:flutter/material.dart';

/// 放松冥想页：冥想引导课程列表
class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '放松冥想',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '环境音播放会在倒计时结束后自动停止',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '冥想课程列表将在此展示',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
