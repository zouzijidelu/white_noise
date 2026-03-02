import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/merit_provider.dart';

/// 功德页：电子木鱼，点击累积功德
class WoodenFishScreen extends StatefulWidget {
  const WoodenFishScreen({super.key});

  @override
  State<WoodenFishScreen> createState() => _WoodenFishScreenState();
}

class _WoodenFishScreenState extends State<WoodenFishScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
        _animationController.reset();
      }
    });

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap(MeritProvider merit) {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
    });
    
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    merit.increment();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 主要内容层
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '功德',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '通过敲电子木鱼功能实现心理舒缓',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 150),
                    Consumer<MeritProvider>(
                      builder: (_, merit, __) {
                        return Column(
                          children: [
                            Text(
                              '${merit.sessionCount}',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text('累积功德: ${merit.totalCount}'),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    Consumer<MeritProvider>(
                      builder: (_, merit, __) {
                        return GestureDetector(
                          onTap: _isAnimating ? null : () => _handleTap(merit),
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Opacity(
                              opacity: 1.0,
                              child: Image.asset(
                                'assets/images/muyu_big.png',
                                width: 120,
                                height: 120,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
              
              // 动画层
              if (_isAnimating)
                SlideTransition(
                  position: _positionAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      '功德+1',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
