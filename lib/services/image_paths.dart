import 'package:path/path.dart' as p;

class ImagePaths {
  static const _exts = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'};

  static bool isImageFile(String path) => _exts.contains(p.extension(path).toLowerCase());

  static String defaultOutputDir(String inputFile) {
    final dir = p.dirname(inputFile);
    return p.join(dir, 'compressed');
  }
}
