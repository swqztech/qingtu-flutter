import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_paths.dart';

class QingtuPaths {
  /// 压缩/拼接输出目录
  static Future<String> outputDirectory({
    String? firstInputPath,
    String? customDir,
  }) async {
    if (customDir != null && customDir.trim().isNotEmpty) {
      return customDir.trim();
    }
    if (!kIsWeb &&
        Platform.isWindows &&
        firstInputPath != null &&
        firstInputPath.isNotEmpty) {
      return ImagePaths.defaultOutputDir(firstInputPath);
    }
    final doc = await getApplicationDocumentsDirectory();
    return p.join(doc.path, 'qingtu', 'output');
  }
}
