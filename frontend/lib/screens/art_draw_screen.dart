import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/colors.dart';

class ArtDrawScreen extends StatefulWidget {
  const ArtDrawScreen({super.key});
  @override State<ArtDrawScreen> createState() => _ArtDrawScreenState();
}

class _ArtDrawScreenState extends State<ArtDrawScreen> {
  final List<List<DrawPoint>> _strokes = [];
  List<DrawPoint> _currentStroke = [];
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;
  final ApiService _api = ApiService();
  bool _saving = false;

  final List<Color> _palette = [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple, Colors.pink, Colors.brown, Colors.cyan];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final surfColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: surfColor, elevation: 0,
        title: Text(app.t('art_studio'), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: Icon(Icons.undo, color: textColor), onPressed: () => setState(_undoLastStroke)),
          IconButton(icon: Icon(Icons.clear, color: textColor), onPressed: () => setState(() { _currentStroke = []; _strokes.clear(); })),
          IconButton(icon: Icon(Icons.save_rounded, color: AppColors.primary), onPressed: () => _saveDrawing(app)),
        ],
      ),
      body: _saving
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : Column(children: [
        Expanded(
          child: Container(
            color: Colors.white,
            child: GestureDetector(
              onPanStart: (d) => setState(() {
                _currentStroke = [
                  DrawPoint(
                    offset: d.localPosition,
                    color: _isEraser ? Colors.white : _currentColor,
                    strokeWidth: _strokeWidth,
                  ),
                ];
              }),
              onPanUpdate: (d) => setState(() {
                _currentStroke.add(
                  DrawPoint(
                    offset: d.localPosition,
                    color: _isEraser ? Colors.white : _currentColor,
                    strokeWidth: _strokeWidth,
                  ),
                );
              }),
              onPanEnd: (_) => setState(() {
                if (_currentStroke.isNotEmpty) {
                  _strokes.add(List<DrawPoint>.from(_currentStroke));
                  _currentStroke = [];
                }
              }),
              onPanCancel: () => setState(() {
                if (_currentStroke.isNotEmpty) {
                  _strokes.add(List<DrawPoint>.from(_currentStroke));
                  _currentStroke = [];
                }
              }),
              child: CustomPaint(
                painter: DrawingPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        Container(
          color: surfColor,
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ..._palette.map((c) => GestureDetector(
                  onTap: () => setState(() {
                    _currentColor = c;
                    _isEraser = false;
                  }),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _currentColor == c && !_isEraser
                          ? Border.all(color: AppColors.primary, width: 2.5)
                          : null,
                    ),
                  ),
                )),
                GestureDetector(
                  onTap: _pickColor,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.color_lens, size: 18),
                  ),
                ),
              ]),
            ),
            Row(children: [
              IconButton(
                icon: Icon(Icons.brush, color: !_isEraser ? AppColors.primary : (isDark ? AppColors.darkTextLight : AppColors.textLight)),
                onPressed: () => setState(() => _isEraser = false),
              ),
              IconButton(
                icon: Icon(Icons.cleaning_services, color: _isEraser ? AppColors.primary : (isDark ? AppColors.darkTextLight : AppColors.textLight)),
                onPressed: () => setState(() => _isEraser = true),
              ),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 20,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                ),
              ),
              Text('${_strokeWidth.toInt()}px', style: TextStyle(color: textColor, fontSize: 12)),
            ]),
          ]),
        ),
      ]),
      bottomNavigationBar: BottomNavBar(currentIndex: 2, onTap: (i) {
        if (i == 2) return;
        if (i == 0) Navigator.pushReplacementNamed(context, '/');
        else if (i == 1) Navigator.pushReplacementNamed(context, '/tutorials');
        else if (i == 3) Navigator.pushReplacementNamed(context, '/explore');
        else if (i == 4) Navigator.pushReplacementNamed(context, '/profile');
      }),
    );
  }

  void _undoLastStroke() {
    if (_currentStroke.isNotEmpty) {
      _currentStroke = [];
      return;
    }
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
    }
  }

  void _pickColor() {
    final app = Provider.of<AppProvider>(context, listen: false);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(app.t('language') == 'Language' ? 'Pick a color' : 'Chọn màu'),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: _currentColor, onColorChanged: (c) => setState(() => _currentColor = c))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  Future<void> _saveDrawing(AppProvider app) async {
    if (_strokes.isEmpty && _currentStroke.isEmpty) {
      NotificationService.showError(app.t('no_strokes'));
      return;
    }

    final strokesToSave = <List<DrawPoint>>[
      ..._strokes,
      if (_currentStroke.isNotEmpty) List<DrawPoint>.from(_currentStroke),
    ];

    setState(() => _saving = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = MediaQuery.of(context).size;
      DrawingPainter(strokes: strokesToSave).paint(canvas, Size(size.width, size.height - 200));
      final img = await recorder.endRecording().toImage(size.width.toInt(), (size.height - 200).toInt());
      final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final res = await _api.post('/artworks', {
        'title': app.language == AppLanguage.en ? 'New Drawing' : 'Bức vẽ mới',
        'description': app.language == AppLanguage.en ? 'Created in Art Studio' : 'Được tạo từ Art Studio',
        'image_url': 'data:image/png;base64,${base64Encode(bytes)}',
        'is_public': true,
        'source_type': 'drawing'
      });
      if (res.statusCode == 201) {
        NotificationService.showSuccess(app.t('saved_artwork'));
        Navigator.pushReplacementNamed(context, '/');
      } else {
        NotificationService.showError(app.t('save_failed'));
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    } finally {
      setState(() => _saving = false);
    }
  }
}

class DrawPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;

  DrawPoint({required this.offset, required this.color, required this.strokeWidth});
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawPoint>> strokes;
  final List<DrawPoint> currentStroke;

  DrawingPainter({required this.strokes, this.currentStroke = const []});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in [...strokes, if (currentStroke.isNotEmpty) currentStroke]) {
      if (stroke.isEmpty) {
        continue;
      }

      if (stroke.length == 1) {
        final point = stroke.first;
        paint
          ..color = point.color
          ..strokeWidth = point.strokeWidth
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point.offset, point.strokeWidth / 2, paint);
        continue;
      }

      for (int i = 0; i < stroke.length - 1; i++) {
        paint
          ..color = stroke[i].color
          ..strokeWidth = stroke[i].strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(stroke[i].offset, stroke[i + 1].offset, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.currentStroke != currentStroke;
  }
}
