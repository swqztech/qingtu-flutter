import 'package:path/path.dart' as p;

import '../models/job_result.dart';

class FormatResults {
  static String formatLog(List<JobResult> results) =>
      results.map(_formatLine).join('\n');

  static String _formatLine(JobResult r) {
    final name = p.basename(r.inputPath);
    if (r.outputPath.isEmpty) return '$name → ${r.message}';
    final outName = p.basename(r.outputPath);
    return '$name → $outName (${_humanBytes(r.bytesBefore)} → ${_humanBytes(r.bytesAfter)})';
  }

  static String _humanBytes(int n) {
    if (n < 1024) return '$n B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
