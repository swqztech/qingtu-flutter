import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;

class ImageStitchService {
  static String stitchHorizontal(List<String> inputs, String outputPath) {
    if (inputs.length < 2) {
      throw Exception('拼接至少需要 2 张图片');
    }

    final loaded = <Image>[];
    for (final path in inputs) {
      final bytes = File(path).readAsBytesSync();
      final img = decodeImage(bytes);
      if (img == null) {
        throw Exception('无法打开: ${p.basename(path)}');
      }
      loaded.add(img);
    }

    final targetH = loaded.map((e) => e.height).reduce(min);
    if (targetH <= 0) throw Exception('图片高度无效');

    final pieces = <Image>[];
    for (final bmp in loaded) {
      if (bmp.height == targetH) {
        pieces.add(bmp);
      } else {
        final w = max(1, (bmp.width * targetH / bmp.height).round());
        pieces.add(copyResize(bmp, width: w, height: targetH));
      }
    }

    final totalW = pieces.fold<int>(0, (s, i) => s + i.width);
    final canvas = Image(width: totalW, height: targetH);
    var x = 0;
    for (final piece in pieces) {
      compositeImage(canvas, piece, dstX: x, dstY: 0);
      x += piece.width;
    }

    final dir = p.dirname(outputPath);
    if (dir.isNotEmpty) Directory(dir).createSync(recursive: true);

    File(outputPath).writeAsBytesSync(encodePng(canvas));
    return outputPath;
  }
}
