import 'package:flutter/material.dart';

/// Màn xem hình toàn màn hình: chụm hai ngón để phóng to, kéo để di chuyển,
/// chạm hai lần để phóng to nhanh hoặc trở về cỡ ban đầu.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.path, this.title});

  final String path;
  final String? title;

  /// Mở hình [path] trong màn xem phóng to.
  static Future<void> open(BuildContext context, String path, {String? title}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ImageViewerScreen(path: path, title: title),
        ),
      );

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  static const _doubleTapScale = 2.5;

  final _controller = TransformationController();
  TapDownDetails? _doubleTap;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_controller.value.getMaxScaleOnAxis() > 1.01) {
      _controller.value = Matrix4.identity();
      return;
    }
    final p = _doubleTap?.localPosition ?? Offset.zero;
    _controller.value = Matrix4.diagonal3Values(_doubleTapScale, _doubleTapScale, 1)
      ..setTranslationRaw(-p.dx * (_doubleTapScale - 1), -p.dy * (_doubleTapScale - 1), 0);
  }

  @override
  Widget build(BuildContext context) {
    // Nền trắng để hình sa hình và biển báo (nền trong suốt) hiện rõ như trong câu hỏi.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: widget.title == null ? null : Text(widget.title!),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onDoubleTapDown: (d) => _doubleTap = d,
          onDoubleTap: _toggleZoom,
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: 1,
            maxScale: 6,
            child: SizedBox.expand(
              child: Image.asset(widget.path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
