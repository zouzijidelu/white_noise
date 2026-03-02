import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:white_noise/screens/sleep_screen.dart';

void main() {
  testWidgets('SleepScreen shows title and description', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SleepScreen(),
      ),
    );

    expect(find.text('定时睡眠'), findsOneWidget);
    expect(find.text('环境音播放会在倒计时结束后自动停止'), findsOneWidget);
  });
}
