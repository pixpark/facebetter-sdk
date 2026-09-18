import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facebetter_flutter/facebetter_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facebetter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BeautyPage(),
    );
  }
}

class _BodyItem {
  const _BodyItem(this.param, this.label);
  final FBBodyReshape param;
  final String label;
}

class _BodyGroup {
  const _BodyGroup(this.title, this.items);
  final String title;
  final List<_BodyItem> items;
}

const _bodyGroups = [
  _BodyGroup('身形', [
    _BodyItem(FBBodyReshape.bodySlim, '瘦身'),
    _BodyItem(FBBodyReshape.torsoLong, '修长'),
    _BodyItem(FBBodyReshape.waistSlim, '瘦腰'),
    _BodyItem(FBBodyReshape.bustEnhance, '美胸'),
  ]),
  _BodyGroup('肩臂', [
    _BodyItem(FBBodyReshape.shoulderSlim, '瘦肩'),
    _BodyItem(FBBodyReshape.armSlim, '瘦胳膊'),
  ]),
  _BodyGroup('腿部', [
    _BodyItem(FBBodyReshape.legSlim, '瘦腿'),
    _BodyItem(FBBodyReshape.legLong, '长腿'),
    _BodyItem(FBBodyReshape.legStretch, '拉伸长腿'),
  ]),
];

class BeautyPage extends StatefulWidget {
  const BeautyPage({super.key});

  @override
  State<BeautyPage> createState() => _BeautyPageState();
}

class _BeautyPageState extends State<BeautyPage> {
  FBEngine? _engine;
  Uint8List? _jpegBytes;
  ui.Image? _processedImage;

  double _smoothing = 0.0;
  double _whitening = 0.0;
  double _faceThin = 0.0;
  double _lipstick = 0.0;
  final Map<FBBodyReshape, double> _body = {
    for (final group in _bodyGroups)
      for (final item in group.items) item.param: 0.0,
  };

  bool _isProcessing = false;
  String _statusText = '初始化中...';

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      FBEngine.setLogConfig(console: true, level: FBLogLevel.debug);
      _engine = await FBEngine.create(
        const FBEngineConfig(
          appId: '06badf4873d72dd335b2f8a922d58ae2',
          appKey: '--HvaY_jZ538D1AxYkj7SgbxtlG7BzYC3WaJLDN2eT0',
          externalContext: false,
          enableLandmarks: true,
        ),
      );

      final byteData = await rootBundle.load('assets/demo.jpg');
      _jpegBytes = byteData.buffer.asUint8List();
      await _showOriginal();
      setState(() => _statusText = '就绪 - 拖动滑块调整美颜参数');
    } catch (e) {
      setState(() => _statusText = '初始化失败: $e');
    }
  }

  Future<void> _showOriginal() async {
    final bytes = _jpegBytes;
    if (bytes == null) {
      return;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() => _processedImage = frame.image);
  }

  Future<void> _processImage() async {
    final engine = _engine;
    final bytes = _jpegBytes;
    if (engine == null || bytes == null || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      engine.setSmoothing(_smoothing);
      engine.setWhitening(_whitening);
      engine.setReshape(FBReshape.faceThin, _faceThin);
      engine.setLipstick(_lipstick);
      for (final entry in _body.entries) {
        engine.setBodyReshape(entry.key, entry.value);
      }

      final image = await engine.processImageToUiImage(bytes);
      setState(() {
        _processedImage = image;
        _statusText = '处理完成';
      });
    } catch (e) {
      setState(() => _statusText = '处理出错: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facebetter Demo')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: _processedImage != null
                  ? RawImage(image: _processedImage, fit: BoxFit.contain)
                  : const CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _statusText,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildSliderRow('磨皮', _smoothing, (v) {
                  _smoothing = v;
                  _processImage();
                }),
                _buildSliderRow('美白', _whitening, (v) {
                  _whitening = v;
                  _processImage();
                }),
                _buildSliderRow('瘦脸', _faceThin, (v) {
                  _faceThin = v;
                  _processImage();
                }),
                _buildSliderRow('口红', _lipstick, (v) {
                  _lipstick = v;
                  _processImage();
                }),
                for (final group in _bodyGroups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final item in group.items)
                    _buildSliderRow(item.label, _body[item.param] ?? 0, (v) {
                      _body[item.param] = v;
                      _processImage();
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
      String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
