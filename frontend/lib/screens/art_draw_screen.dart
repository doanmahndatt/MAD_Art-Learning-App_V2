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
  List<DrawPoint> _points = [];
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
    final textColor = isDark ? AppColors.darkText    : AppColors.text;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: surfColor, elevation: 0,
        title: Text(app.t('art_studio'), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: Icon(Icons.undo, color: textColor), onPressed: () => setState(() { if (_points.isNotEmpty) _points.removeLast(); })),
          IconButton(icon: Icon(Icons.clear, color: textColor), onPressed: () => setState(() => _points.clear())),
          IconButton(icon: Icon(Icons.save_rounded, color: AppColors.primary), onPressed: () => _saveDrawing(app)),
        ],
      ),
      body: _saving ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : Column(children: [
        Expanded(child: Container(
          // Drawing canvas always white
          color: Colors.white,
          child: GestureDetector(
            onPanUpdate: (d) => setState(() => _points.add(DrawPoint(offset: d.localPosition, color: _isEraser ? Colors.white : _currentColor, strokeWidth: _strokeWidth))),
            child: CustomPaint(painter: DrawingPainter(_points), size: Size.infinite),
          ),
        )),
        Container(color: surfColor, padding: const EdgeInsets.all(8), child: Column(children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            ..._palette.map((c) => GestureDetector(
              onTap: () => setState(() { _currentColor = c; _isEraser = false; }),
              child: Container(margin: const EdgeInsets.all(4), width: 36, height: 36,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                      border: _currentColor == c && !_isEraser ? Border.all(color: AppColors.primary, width: 2.5) : null)),
            )),
            GestureDetector(onTap: _pickColor, child: Container(margin: const EdgeInsets.all(4), width: 36, height: 36,
                decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceVariant : Colors.grey[200], shape: BoxShape.circle),
                child: const Icon(Icons.color_lens, size: 18))),
          ])),
          Row(children: [
            IconButton(icon: Icon(Icons.brush, color: !_isEraser ? AppColors.primary : (isDark ? AppColors.darkTextLight : AppColors.textLight)), onPressed: () => setState(() => _isEraser = false)),
            IconButton(icon: Icon(Icons.cleaning_services, color: _isEraser ? AppColors.primary : (isDark ? AppColors.darkTextLight : AppColors.textLight)), onPressed: () => setState(() => _isEraser = true)),
            Expanded(child: Slider(value: _strokeWidth, min: 1, max: 20, activeColor: AppColors.primary, onChanged: (v) => setState(() => _strokeWidth = v))),
            Text('${_strokeWidth.toInt()}px', style: TextStyle(color: textColor, fontSize: 12)),
          ]),
        ])),
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

  void _pickColor() {
    final app = Provider.of<AppProvider>(context, listen: false);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(app.t('language') == 'Language' ? 'Pick a color' : 'Chọn màu'),
      content: SingleChildScrollView(child: ColorPicker(pickerColor: _currentColor, onColorChanged: (c) => setState(() => _currentColor = c))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ));
  }

  Future<void> _saveDrawing(AppProvider app) async {
    if (_points.isEmpty) { NotificationService.showError(app.t('no_strokes')); return; }
    setState(() => _saving = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = MediaQuery.of(context).size;
      DrawingPainter(_points).paint(canvas, Size(size.width, size.height - 200));
      final img = await recorder.endRecording().toImage(size.width.toInt(), (size.height - 200).toInt());
      final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final res = await _api.post('/artworks', {'title': app.language == AppLanguage.en ? 'New Drawing' : 'Bức vẽ mới', 'description': app.language == AppLanguage.en ? 'Created in Art Studio' : 'Được tạo từ Art Studio', 'image_url': 'data:image/png;base64,${base64Encode(bytes)}', 'is_public': true, 'source_type': 'drawing'});
      if (res.statusCode == 201) { NotificationService.showSuccess(app.t('saved_artwork')); Navigator.pushReplacementNamed(context, '/'); }
      else NotificationService.showError(app.t('save_failed'));
    } catch (e) { NotificationService.showError('Error: $e'); }
    finally { setState(() => _saving = false); }
  }
}

class DrawPoint { final Offset offset; final Color color; final double strokeWidth; DrawPoint({required this.offset, required this.color, required this.strokeWidth}); }

class DrawingPainter extends CustomPainter {
  final List<DrawPoint> points; DrawingPainter(this.points);
  @override void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    final p = Paint()..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < points.length - 1; i++) { p.color = points[i].color; p.strokeWidth = points[i].strokeWidth; canvas.drawLine(points[i].offset, points[i+1].offset, p); }
  }
  @override bool shouldRepaint(covariant CustomPainter _) => true;
}