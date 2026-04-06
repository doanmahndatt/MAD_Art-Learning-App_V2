import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art Studio'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
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