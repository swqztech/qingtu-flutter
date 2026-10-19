import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 将相册/文档选中的文件落到可读写的本地路径（Android 部分 URI 无 path）
Future<String> materializePickedFile(PlatformFile file) async {
  if (file.path != null && file.path!.isNotEmpty) {
    final f = File(file.path!);
    if (await f.exists()) return file.path!;
  }
  final bytes = await file.readAsBytes();
  final dir = await getTemporaryDirectory();
  final name = file.name.isNotEmpty ? file.name : 'image_${DateTime.now().millisecondsSinceEpoch}';
  final path = p.join(dir.path, name);
  await File(path).writeAsBytes(bytes);
  return path;
}
