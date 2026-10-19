import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../models/job_options.dart';
import '../models/job_result.dart';
import '../models/output_format.dart';
import '../services/format_results.dart';
import '../services/image_compress_service.dart';
import '../services/image_paths.dart';
import '../services/image_stitch_service.dart';
import '../services/picked_file_util.dart';
import '../services/qingtu_paths.dart';
import '../utils/platform_util.dart';

class QingtuHomePage extends StatefulWidget {
  const QingtuHomePage({super.key});

  @override
  State<QingtuHomePage> createState() => _QingtuHomePageState();
}

class _QingtuHomePageState extends State<QingtuHomePage> {
  final List<String> _files = [];
  bool _compressTab = true;
  bool _busy = false;
  double _quality = 80;
  final _maxSideCtrl = TextEditingController(text: '0');
  final _outDirCtrl = TextEditingController();
  bool _customOut = false;
  OutputFormat _format = OutputFormat.keepOriginal;
  String _log = '';

  static const _teal = Color(0xFF0D9488);
  static const _orange = Color(0xFFF97316);
  static const _muted = Color(0xFF64748B);

  @override
  void dispose() {
    _maxSideCtrl.dispose();
    _outDirCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final picked = isDesktop
        ? await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
          )
        : await FilePicker.pickFiles(type: FileType.image);
    if (picked.isEmpty) return;
    final paths = <String>[];
    for (final f in picked) {
      paths.add(await materializePickedFile(f));
    }
    _addFiles(paths);
  }

  Future<void> _pickOutDir() async {
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null) return;
    setState(() {
      _outDirCtrl.text = dir;
      _customOut = true;
    });
  }

  void _addFiles(Iterable<String> paths) {
    for (final path in paths) {
      if (!ImagePaths.isImageFile(path) || _files.contains(path)) continue;
      _files.add(path);
    }
    setState(() {});
  }

  JobOptions _buildOptions({String? outputDir}) {
    final maxSide = int.tryParse(_maxSideCtrl.text.trim()) ?? 0;
    String? dir = outputDir;
    if (dir == null && _customOut && _outDirCtrl.text.trim().isNotEmpty) {
      dir = _outDirCtrl.text.trim();
    }
    return JobOptions(
      quality: _quality.round(),
      maxSide: maxSide < 0 ? 0 : maxSide,
      format: _format,
      outputDir: dir,
    );
  }

  Future<void> _shareFiles(List<String> paths) async {
    if (paths.isEmpty || isDesktop) return;
    await SharePlus.instance.share(
      ShareParams(files: paths.map(XFile.new).toList(), text: '轻图导出'),
    );
  }

  Future<void> _run() async {
    if (_busy) return;
    if (_files.isEmpty) {
      setState(() => _log = '请先添加图片');
      return;
    }

    setState(() => _busy = true);
    try {
      final outDir = await QingtuPaths.outputDirectory(
        firstInputPath: _files.isNotEmpty ? _files.first : null,
        customDir: _customOut && _outDirCtrl.text.trim().isNotEmpty
            ? _outDirCtrl.text.trim()
            : null,
      );
      if (_compressTab) {
        final opts = _buildOptions(outputDir: outDir);
        final results = await Future(
          () => ImageCompressService.runJobs(_files, opts),
        );
        final log = FormatResults.formatLog(results);
        setState(() => _log = log);
        await _shareFiles(_outputPaths(results));
      } else {
        if (_files.length < 2) {
          setState(() => _log = '拼接需要至少 2 张图');
          return;
        }
        final outPath = await Future(() {
          final path = p.join(outDir, 'stitched.png');
          return ImageStitchService.stitchHorizontal(_files, path);
        });
        setState(() => _log = '拼接完成 → $outPath');
        await _shareFiles([outPath]);
      }
    } catch (e) {
      setState(() => _log = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  List<String> _outputPaths(List<JobResult> results) =>
      results.map((r) => r.outputPath).where((p) => p.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final runLabel = _compressTab
        ? '开始压缩 (${_files.length})'
        : '开始拼接 (${_files.length})';

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      appBar: AppBar(
        title: const Text('轻图', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0FDFA),
        foregroundColor: _teal,
        elevation: 0,
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '把体积压下去，细节留住',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF134E4A)),
              ),
              const SizedBox(height: 4),
              const Text(
                '本地处理 · 不上传 · PNG / JPG / WebP',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _tabButton('压缩', _compressTab, () => setState(() => _compressTab = true)),
                  const SizedBox(width: 8),
                  _tabButton('拼接', !_compressTab, () => setState(() => _compressTab = false)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _teal),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _files.isEmpty ? '点击下方选择图片' : '已选 ${_files.length} 个文件',
                      style: TextStyle(color: _files.isEmpty ? _muted : _teal),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _orange),
                      onPressed: _busy ? null : _pickFiles,
                      child: const Text('选择图片'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (_, i) => Text(
                    p.basename(_files[i]),
                    style: const TextStyle(color: Color(0xFF134E4A)),
                  ),
                ),
              ),
              if (_compressTab) ...[
                const SizedBox(height: 12),
                _compressPanel(),
              ] else ...[
                const SizedBox(height: 8),
                const Text('按列表顺序横向拼接，高度对齐最短边', style: TextStyle(color: _muted)),
              ],
              if (isDesktop) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _customOut,
                  onChanged: (v) => setState(() => _customOut = v ?? false),
                  title: const Text('自定义输出目录'),
                  contentPadding: EdgeInsets.zero,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _outDirCtrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFECFDF5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _pickOutDir, child: const Text('浏览…')),
                  ],
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '移动端：结果保存在应用文档/qingtu/output，处理后可分享保存',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _orange),
                    onPressed: _busy ? null : _run,
                    child: Text(runLabel),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _files.clear();
                            _log = '';
                          }),
                    child: const Text('清空列表'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  _log,
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? _teal : _muted,
        backgroundColor: active ? const Color(0xFFECFDF5) : Colors.white,
        side: BorderSide(color: active ? _teal : const Color(0xFFCBD5E1)),
      ),
      child: Text(label, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _compressPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 56, child: Text('质量', style: TextStyle(color: _muted))),
              Expanded(
                child: Slider(
                  value: _quality,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (v) => setState(() => _quality = v),
                ),
              ),
              SizedBox(width: 36, child: Text(_quality.round().toString())),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 56, child: Text('最长边', style: TextStyle(color: _muted))),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _maxSideCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text('px（0 = 不缩放）', style: TextStyle(color: _muted))),
            ],
          ),
          const SizedBox(height: 8),
          const Text('输出格式', style: TextStyle(color: _muted)),
          Wrap(
            spacing: 8,
            children: [
              _formatChip('保持原格式', OutputFormat.keepOriginal),
              _formatChip('JPEG', OutputFormat.jpeg),
              _formatChip('PNG', OutputFormat.png),
              _formatChip('WebP', OutputFormat.webp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formatChip(String label, OutputFormat value) {
    final selected = _format == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _format = value),
    );
  }
}
