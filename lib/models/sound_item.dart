/// 音效项模型，供睡眠/DIY 等列表使用
class SoundItem {
  const SoundItem({
    required this.id,
    required this.name,
    this.assetPath,
    this.category,
  });

  final String id;
  final String name;
  final String? assetPath;
  final String? category;
}
