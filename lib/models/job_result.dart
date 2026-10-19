class JobResult {
  JobResult({
    required this.inputPath,
    this.outputPath = '',
    this.bytesBefore = 0,
    this.bytesAfter = 0,
    this.message = '',
  });

  final String inputPath;
  final String outputPath;
  final int bytesBefore;
  final int bytesAfter;
  final String message;
}
