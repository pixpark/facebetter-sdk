import 'dart:async';
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

/// 美颜演示页面：加载图片 → 调整参数 → 实时处理并显示
class BeautyPage extends StatefulWidget {
  const BeautyPage({super.key});

  @override
  State<BeautyPage> createState() => _BeautyPageState();
}

class _BeautyPageState extends State<BeautyPage> {
  FBBeautyEffectEngine? _engine;

  /// 原始图片 RGBA 像素数据
  Uint8List? _originalRgba;
  int _imageWidth = 0;
  int _imageHeight = 0;

  /// 处理后的 ui.Image 用于渲染
  ui.Image? _processedImage;

  /// 美颜参数
  double _smoothing = 0.0;
  double _whitening = 0.0;
  double _faceThin = 0.0;
  double _lipstick = 0.0;

  bool _isProcessing = false;
  String _statusText = '初始化中...';

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  /// 初始化引擎并加载图片
  Future<void> _initEngine() async {
    try {
      // 初始化美颜引擎
      await FBBeautyEffectEngine.init(
        const FBEngineConfig(appId: '06badf4873d72dd335b2f8a922d58ae2', appKey: '--HvaY_jZ538D1AxYkj7SgbxtlG7BzYC3WaJLDN2eT0'),
      );
      _engine = FBBeautyEffectEngine.sharedInstance;

      // 开启控制台日志
      await FBBeautyEffectEngine.setLogConfig(
        const FBLogConfig(consoleEnabled: true, level: FBLogLevel.debug),
      );

      // 加载 JPEG 图片并解码为 RGBA
      final byteData = await rootBundle.load('assets/demo.jpg');
      final jpegBytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(jpegBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      _imageWidth = image.width;
      _imageHeight = image.height;

      final rgbaData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgbaData == null) {
        setState(() => _statusText = '图片解码失败');
        return;
      }

      _originalRgba = rgbaData.buffer.asUint8List();

      // 显示原图
      await _updateProcessedImage(_originalRgba!);
      setState(() => _statusText = '就绪 - 拖动滑块调整美颜参数');
    } catch (e) {
      setState(() => _statusText = '初始化失败: $e');
    }
  }

  /// 根据当前参数处理图像
  Future<void> _processImage() async {
    if (_engine == null || _originalRgba == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // 设置美颜参数
      await _engine!.setBasicParam(FBBasicParam.smoothing, _smoothing);
      await _engine!.setBasicParam(FBBasicParam.whitening, _whitening);
      await _engine!.setReshapeParam(FBReshapeParam.faceThin, _faceThin);
      await _engine!.setMakeupParam(FBMakeupParam.lipstick, _lipstick);

      // 创建 RGBA ImageFrame 并处理
      final inputFrame = FBImageFrame(
        width: _imageWidth,
        height: _imageHeight,
        stride: _imageWidth * 4,
        data: _originalRgba!,
        format: FBImageFormat.rgba,
        frameType: FBFrameType.image,
      );

      final outputFrame = await _engine!.processImage(inputFrame);

      if (outputFrame != null && outputFrame.data != null) {
        await _updateProcessedImage(outputFrame.data!);
        setState(() => _statusText = '处理完成');
      } else {
        setState(() => _statusText = '处理失败');
      }
    } catch (e) {
      setState(() => _statusText = '处理出错: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// 将 RGBA 数据转为 ui.Image 并刷新界面
  Future<void> _updateProcessedImage(Uint8List rgbaData) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgbaData,
      _imageWidth,
      _imageHeight,
      ui.PixelFormat.rgba8888,
      (image) => completer.complete(image),
    );
    final image = await completer.future;
    setState(() => _processedImage = image);
  }

  @override
  void dispose() {
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facebetter Demo')),
      body: Column(
        children: [
          // 图片展示区域
          Expanded(
            flex: 3,
            child: Center(
              child: _processedImage != null
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _imageWidth.toDouble(),
                        height: _imageHeight.toDouble(),
                        child: CustomPaint(
                          painter: _ImagePainter(_processedImage!),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),

          // 状态信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _statusText,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),

          // 美颜参数控制滑块
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单行滑块控件
  Widget _buildSliderRow(
      String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label)),
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

/// 自定义绘制器，将 ui.Image 绘制到 Canvas
class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) =>
      oldDelegate.image != image;
}
