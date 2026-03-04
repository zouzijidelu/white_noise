import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sleep_provider.dart';

/// 定时睡眠页：环境音播放 + 倒计时
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SleepProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        '定时睡眠',
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    _TimerSection(),
                    const SizedBox(height: 24),
                    _CategoryBar(),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _SoundGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _TimerSection extends StatelessWidget {
  static String _formatRemaining(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (_, sleep, __) {
        // 倒计时进行中显示剩余时间，否则显示设定的时长
        final display = sleep.remainingSeconds > 0
            ? _formatRemaining(sleep.remainingSeconds)
            : '${sleep.timerMinutes.toString().padLeft(2, '0')}:00';
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PlaceholderIcon(size: 64),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showTimerPicker(context, sleep),
              child: Text(
                display,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTimerPicker(BuildContext context, SleepProvider sleep) {
    final options = [5, 10, 15, 30, 60];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择定时时长', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...options.map((m) => ListTile(
                  title: Text('$m 分钟'),
                  onTap: () {
                    sleep.setTimerMinutes(m);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (_, sleep, __) {
        final list = sleep.cateDetailList;
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, i) {
              final cate = list[i];
              final id = cate['id'] as int?;
              final title = cate['title'] as String? ?? '';
              final selected = sleep.selectedCateId == id;
              return GestureDetector(
                onTap: () => id != null ? sleep.selectCategory(id) : null,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? Colors.black87 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 3,
                      width: 24,
                      decoration: BoxDecoration(
                        color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SoundGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SleepProvider>(
      builder: (_, sleep, __) {
        if (sleep.loading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (sleep.error != null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(sleep.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => sleep.loadData(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        final audios = sleep.currentAudios;
        if (audios.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('暂无音效')),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final audio = audios[i];
                final id = audio['id'] as int?;
                final title = audio['title'] as String? ?? '';
                final isPlaying = sleep.playingAudioId == id;
                return _SoundItem(
                  title: title,
                  isPlaying: isPlaying,
                  isLoading: sleep.loadingAudioId == id,
                  onTap: () => sleep.toggleAudio(audio),
                );
              },
              childCount: audios.length,
            ),
          ),
        );
      },
    );
  }
}

class _SoundItem extends StatelessWidget {
  const _SoundItem({
    required this.title,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _PlaceholderIcon(
                      size: 36,
                      accent: isPlaying ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                ),
                if (isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}

/// 占位图标：黑底白纹（四叶草/螺旋样式）
class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.size, this.accent});

  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.black87;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.graphic_eq,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}
