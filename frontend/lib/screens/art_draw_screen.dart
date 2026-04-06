import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'tutorials_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

class ArtDrawScreen extends StatefulWidget {
  const ArtDrawScreen({super.key});

  @override
  State<ArtDrawScreen> createState() => _ArtDrawScreenState();
}

class _ArtDrawScreenState extends State<ArtDrawScreen> {
  List<DrawPoint> _points = [];
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;
  final ApiService _api = ApiService();
  int _currentIndex = 2; // màn Vẽ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Studio'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveDrawing),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _points.add(DrawPoint(
                    offset: details.localPosition,
                    color: _isEraser ? Colors.white : _currentColor,
                    strokeWidth: _strokeWidth,
                  ));
                });
              },
              child: CustomPaint(painter: DrawingPainter(_points), size: Size.infinite),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._colorPalette.map((color) => GestureDetector(
                        onTap: () => setState(() {
                          _currentColor = color;
                          _isEraser = false;
                        }),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: _currentColor == color ? Border.all(color: Colors.black, width: 2) : null),
                        ),
                      )),
                      GestureDetector(
                        onTap: () => _pickColor(),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                          child: const Icon(Icons.color_lens),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.brush, color: !_isEraser ? AppColors.primary : null), onPressed: () => setState(() => _isEraser = false)),
                    IconButton(icon: Icon(Icons.cleaning_services, color: _isEraser ? AppColors.primary : null), onPressed: () => setState(() => _isEraser = true)),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                    Text('${_strokeWidth.toInt()}px'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorialsScreen()));
              break;
            case 2:
            // đang ở đây
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
              break;
            case 4:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              break;
          }
        },
      ),
    );
  }

  void _undo() {
    setState(() {
      if (_points.isNotEmpty) _points.removeLast();
    });
  }

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(child: ColorPicker(pickerColor: _currentColor, onColorChanged: (c) => setState(() => _currentColor = c))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _saveDrawing() async {
    if (_points.isEmpty) {
      NotificationService.showError('Chưa có nét vẽ nào');
      return;
    }

    // Chụp canvas thành ảnh
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = MediaQuery.of(context).size;
    final painter = DrawingPainter(_points);
    painter.paint(canvas, Size(size.width, size.height - 200));
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), (size.height - 200).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Upload lên server (base64)
    final base64Image = 'data:image/png;base64,${base64Encode(pngBytes)}';
    try {
      final res = await _api.post('/artworks', {
        'title': 'Bức vẽ mới',
        'description': 'Được tạo từ Art Studio',
        'image_url': base64Image,
        'is_public': true,
        'source_type': 'drawing',
      });
      if (res.statusCode == 201) {
        NotificationService.showSuccess('Đã lưu vào thư viện cá nhân');
        Navigator.pop(context);
      } else {
        NotificationService.showError('Lưu thất bại');
      }
    } catch (e) {
      NotificationService.showError('Lỗi: $e');
    }
  }

  final List<Color> _colorPalette = [
    Colors.black, Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple, Colors.pink, Colors.brown, Colors.cyan,
  ];
}

class DrawPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  DrawPoint({required this.offset, required this.color, required this.strokeWidth});
}

class DrawingPainter extends CustomPainter {
  final List<DrawPoint> points;
  DrawingPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < points.length - 1; i++) {
      paint.color = points[i].color;
      paint.strokeWidth = points[i].strokeWidth;
      canvas.drawLine(points[i].offset, points[i + 1].offset, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}