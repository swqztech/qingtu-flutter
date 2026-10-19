import 'output_format.dart';

class JobOptions {
  JobOptions({
    this.quality = 80,
    this.maxSide = 0,
    this.format = OutputFormat.keepOriginal,
    this.outputDir,
  });

  final int quality;
  final int maxSide;
  final OutputFormat format;
  final String? outputDir;
}
