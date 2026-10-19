import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;

import '../models/job_options.dart';
import '../models/job_result.dart';
import '../models/output_format.dart';
import 'image_paths.dart';

class ImageCompressService {
  static List<JobResult> runJobs(List<String> paths, JobOptions opts) =>
      paths.map((path) => compressOne(path, opts)).toList();

  static JobResult compressOne(String input, JobOptions opts) {
    try {
      if (!File(input).existsSync()) {
        return _fail(input, '不是有效文件');
      }

      final bytesBefore = File(input).lengthSync();
      final fmt = _targetFormat(input, opts.format);
      final outDir = (opts.outputDir?.trim().isNotEmpty ?? false)
          ? opts.outputDir!.trim()
          : ImagePaths.defaultOutputDir(input);
      Directory(outDir).createSync(recursive: true);

      final bitmap = _loadAndResize(input, opts.maxSide);
      final outPath = p.join(
        outDir,
        '${p.basenameWithoutExtension(input)}.${_extFor(fmt)}',
      );
      _save(bitmap, outPath, fmt, opts.quality);

      final bytesAfter = File(outPath).lengthSync();
      return JobResult(
        inputPath: input,
        outputPath: outPath,
        bytesBefore: bytesBefore,
        bytesAfter: bytesAfter,
        message: '完成',
      );
    } catch (e) {
      return _fail(input, e.toString());
    }
  }

  static JobResult _fail(String input, String message) =>
      JobResult(inputPath: input, message: message);

  static Image _loadAndResize(String path, int maxSide) {
    final bytes = File(path).readAsBytesSync();
    final src = decodeImage(bytes);
    if (src == null) throw Exception('无法解码图片');

    if (maxSide <= 0) return src;

    final w = src.width;
    final h = src.height;
    final longest = max(w, h);
    if (longest <= maxSide) return src;

    final scale = maxSide / longest;
    final nw = max(1, (w * scale).round());
    final nh = max(1, (h * scale).round());
    return copyResize(src, width: nw, height: nh);
  }

  static void _save(Image bitmap, String path, _EncodeFormat fmt, int quality) {
    final q = quality.clamp(1, 100);
    final List<int> data;
    switch (fmt) {
      case _EncodeFormat.jpeg:
        data = encodeJpg(bitmap, quality: q);
      case _EncodeFormat.png:
        data = encodePng(bitmap, level: _pngLevel(q));
      case _EncodeFormat.webp:
        data = encodeWebP(bitmap, lossless: false, quality: q);
      case _EncodeFormat.gif:
        data = encodeGif(bitmap);
      case _EncodeFormat.bmp:
        data = encodeBmp(bitmap);
    }
    File(path).writeAsBytesSync(data);
  }

  static int _pngLevel(int q) {
    if (q >= 85) return 6;
    if (q >= 50) return 4;
    return 2;
  }

  static _EncodeFormat _targetFormat(String path, OutputFormat choice) {
    switch (choice) {
      case OutputFormat.jpeg:
        return _EncodeFormat.jpeg;
      case OutputFormat.png:
        return _EncodeFormat.png;
      case OutputFormat.webp:
        return _EncodeFormat.webp;
      case OutputFormat.keepOriginal:
        return _detectFormat(path);
    }
  }

  static _EncodeFormat _detectFormat(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return _EncodeFormat.jpeg;
      case '.webp':
        return _EncodeFormat.webp;
      case '.gif':
        return _EncodeFormat.gif;
      case '.bmp':
        return _EncodeFormat.bmp;
      default:
        return _EncodeFormat.png;
    }
  }

  static String _extFor(_EncodeFormat fmt) {
    switch (fmt) {
      case _EncodeFormat.jpeg:
        return 'jpg';
      case _EncodeFormat.webp:
        return 'webp';
      case _EncodeFormat.gif:
        return 'gif';
      case _EncodeFormat.bmp:
        return 'bmp';
      case _EncodeFormat.png:
        return 'png';
    }
  }
}

enum _EncodeFormat { jpeg, png, webp, gif, bmp }
