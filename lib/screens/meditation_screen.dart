import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:white_noise/constants/api_constants.dart';

import '../providers/meditation_provider.dart';

/// 放松冥想页：冥想引导课程列表
class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  @override
  void initState() {
    super.initState();
    // 页面初始化时加载冥想列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeditationProvider>().loadMeditationList();
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
                        '放松冥想',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '环境音播放会在倒计时结束后自动停止',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // 冥想课程列表
            Consumer<MeditationProvider>(
              builder: (context, meditationProvider, child) {
                if (meditationProvider.loadingList) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (meditationProvider.error != null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            meditationProvider.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                meditationProvider.loadMeditationList(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final courses = meditationProvider.meditationList;
                if (courses.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('暂无冥想课程')),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final course = courses[index];
                      return _MeditationCourseCard(
                        course: course,
                        isSelected:
                            meditationProvider.selectedCourse?.id == course.id,
                        isPlaying:
                            meditationProvider.isPlaying &&
                            meditationProvider.selectedCourse?.id == course.id,
                        preparing: meditationProvider.preparing,
                        onTap: () => _onCourseTap(meditationProvider, course),
                        onPlay: () => _onPlayTap(meditationProvider, course),
                      );
                    }, childCount: courses.length),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _onCourseTap(MeditationProvider provider, MeditationCourse course) {
    provider.selectCourse(course);
    provider.loadMeditationDetail(course.id);
  }

  void _onPlayTap(MeditationProvider provider, MeditationCourse course) {
    if (provider.selectedCourse?.id == course.id) {
      provider.togglePlay();
    } else {
      provider.selectCourse(course);
      provider.play();
    }
  }
}

/// 冥想课程卡片组件
class _MeditationCourseCard extends StatelessWidget {
  const _MeditationCourseCard({
    required this.course,
    required this.isSelected,
    required this.isPlaying,
    required this.preparing,
    required this.onTap,
    required this.onPlay,
  });

  final MeditationCourse course;
  final bool isSelected;
  final bool isPlaying;
  final bool preparing;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 2,
      color: isSelected ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 缩略图占位符
              SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    course.fullThumbnailUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.graphic_eq,
                        color: Colors.white,
                        size: 30,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 课程信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.intro,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(course.duration ~/ 60).toString().padLeft(2, '0')}:${(course.duration % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
