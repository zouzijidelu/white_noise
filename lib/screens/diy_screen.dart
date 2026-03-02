import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/diy_provider.dart';

/// DIY 白噪音页：最多 3 个音效混合，选中黑框，超限弹窗
class DiyScreen extends StatefulWidget {
  const DiyScreen({super.key});

  @override
  State<DiyScreen> createState() => _DiyScreenState();
}

class _DiyScreenState extends State<DiyScreen> {
  bool _showCategory = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiyProvider>().loadData();
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
                        'DIY白噪音',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '选择多个音频，更改音频中间的音量键可配置自己的组合音效',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<DiyProvider>(
                      builder: (_, diy, __) => Text(
                        '小${diy.currentAudiosCount} 音效',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.black87,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _TabChip(
                          label: '分类',
                          selected: _showCategory,
                          onTap: () => setState(() => _showCategory = true),
                        ),
                        const SizedBox(width: 12),
                        _PlayTabChip(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_showCategory) ...[
                      _CategoryHeader(),
                      const SizedBox(height: 12),
                      _CategoryStrip(),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (_showCategory)
              _DiySoundGrid(onSelectFourth: _showMaxThreeDialog)
            else
              _PlayView(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _showMaxThreeDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('最多混合播放三个音效'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black87 : Colors.transparent,
          border: Border.all(color: Colors.black87, width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PlayTabChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DiyProvider>(
      builder: (_, diy, __) {
        final isPlaying = diy.isPlayingMix;
        final preparing = diy.preparingMix;
        final hasSelection = diy.selectedAudios.isNotEmpty;
        return GestureDetector(
          onTap: (hasSelection && !preparing)
              ? () async {
                  if (isPlaying) {
                    await diy.stopMix();
                  } else {
                    await diy.playMix();
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: hasSelection ? Colors.black87 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preparing)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    isPlaying ? Icons.stop : Icons.play_arrow,
                    color: hasSelection ? Colors.white : Colors.grey,
                    size: 22,
                  ),
                const SizedBox(width: 6),
                Text(
                  preparing ? '加载中…' : '播放',
                  style: TextStyle(
                    color: hasSelection ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DiyProvider>(
      builder: (_, diy, __) {
        int? id = diy.selectedCateId;
        String title = '事物';
        for (final cate in diy.cateDetailList) {
          if (cate['id'] == id) {
            title = cate['title'] as String? ?? title;
            break;
          }
        }
        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.graphic_eq, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DiyProvider>(
      builder: (_, diy, __) {
        final list = diy.cateDetailList;
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final cate = list[i];
              final id = cate['id'] as int?;
              final title = cate['title'] as String? ?? '';
              final selected = diy.selectedCateId == id;
              return GestureDetector(
                onTap: () => id != null ? diy.selectCategory(id) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black12 : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PlayView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DiyProvider>(
      builder: (_, diy, __) {
        final list = diy.selectedAudios;
        if (list.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                '请先在「分类」中选择最多 3 个音效',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ...list.asMap().entries.map((e) {
                final a = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(a.title, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: a.volume,
                          onChanged: (v) => diy.setVolume(a.id, v),
                          activeColor: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: diy.preparingMix
                      ? null
                      : () async {
                          if (diy.isPlayingMix) {
                            await diy.stopMix();
                          } else {
                            await diy.playMix();
                          }
                        },
                  icon: diy.preparingMix
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(diy.isPlayingMix ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    diy.preparingMix ? '加载中…' : (diy.isPlayingMix ? '停止' : '播放混音'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _DiySoundGrid extends StatelessWidget {
  const _DiySoundGrid({required this.onSelectFourth});

  final VoidCallback onSelectFourth;

  @override
  Widget build(BuildContext context) {
    return Consumer<DiyProvider>(
      builder: (_, diy, __) {
        if (diy.loading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (diy.error != null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    diy.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => diy.loadData(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        final audios = diy.currentAudios;
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
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final audio = audios[i];
                final id = audio['id'] as int?;
                final title = audio['title'] as String? ?? '';
                final selected = id != null && diy.isSelected(id);
                return _DiySoundTile(
                  title: title,
                  selected: selected,
                  volume: id != null ? diy.getVolumeFor(id) : 0.5,
                  onTap: () {
                    final ok = diy.toggleSelection(audio);
                    if (!ok) onSelectFourth();
                  },
                  onVolumeChanged: id != null
                      ? (v) => diy.setVolume(id, v)
                      : null,
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

class _DiySoundTile extends StatelessWidget {
  const _DiySoundTile({
    required this.title,
    required this.selected,
    required this.volume,
    required this.onTap,
    this.onVolumeChanged,
  });

  final String title;
  final bool selected;
  final double volume;
  final VoidCallback onTap;
  final void Function(double)? onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.black : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.graphic_eq,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: volume,
            onChanged: onVolumeChanged != null
                ? (v) => onVolumeChanged!(v)
                : null,
            activeColor: Colors.black87,
            inactiveColor: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 2),
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
    );
  }
}
