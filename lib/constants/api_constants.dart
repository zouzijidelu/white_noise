/// 接口 Base URL 与路径常量
class ApiConstants {
  ApiConstants._();

  /// 所有网络请求的 Base URL
  static const String baseUrl = 'https://audio.3dmaxmo.com/index.php';

  /// 分类列表（仅分类）
  static const String cateList = '/jty/index/cateList';

  /// 所有分类及下属音效详情
  static const String cateDetailList = '/jty/cate/list';

  /// 冥想列表
  static const String meditationList = '/jty/Meditation/list';

  /// 冥想详情
  static const String meditationDetail = '/jty/Meditation/detail';

  /// 将相对路径转为完整资源 URL（音频/图片等）
  static String resourceUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http')) return path;
    final base = baseUrl.replaceFirst(RegExp(r'/index\.php.*'), '');
    return '$base$path';
  }
}
