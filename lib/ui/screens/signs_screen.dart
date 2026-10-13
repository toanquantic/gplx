import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../app_scope.dart';
import '../theme.dart';

const _signGroups = {
  'bien_cam': 'Biển cấm',
  'bien_nguy_hiem': 'Nguy hiểm',
  'bien_hieu_lenh': 'Hiệu lệnh',
  'bien_chi_dan': 'Chỉ dẫn',
  'bien_phu': 'Biển phụ',
  'vach_ke': 'Vạch kẻ',
};

const _signGroupTitles = {
  'bien_cam': 'Biển báo cấm',
  'bien_hieu_lenh': 'Biển hiệu lệnh',
  'bien_nguy_hiem': 'Biển báo nguy hiểm và cảnh báo',
  'bien_chi_dan': 'Biển chỉ dẫn',
  'bien_phu': 'Biển phụ',
  'vach_ke': 'Vạch kẻ đường',
};

/// Danh mục biển báo theo QCVN 41:2024: mã, tên và ý nghĩa (chưa có hình riêng từng biển).
class SignsScreen extends StatefulWidget {
  const SignsScreen({super.key});

  @override
  State<SignsScreen> createState() => _SignsScreenState();
}

class _SignsScreenState extends State<SignsScreen> {
  String _query = '';
  String? _group;

  @override
  Widget build(BuildContext context) {
    final signs = AppScope.of(context).bank.signs;
    final q = _query.trim().toLowerCase();
    final filtered = signs
        .where((s) => _group == null || s.group == _group)
        .where(
          (s) =>
              q.isEmpty ||
              s.code.toLowerCase().contains(q) ||
              s.name.toLowerCase().contains(q) ||
              (s.meaning?.toLowerCase().contains(q) ?? false),
        )
        .toList();
    final c = context.colors;

    Widget chip(String? group, String label) {
      final on = _group == group;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          showCheckmark: false,
          onSelected: (_) => setState(() => _group = group),
          labelStyle: TextStyle(
            fontFamily: appFont,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: on ? c.onAccent : c.text,
          ),
          selectedColor: c.accent,
          backgroundColor: c.surface,
          side: on ? BorderSide.none : BorderSide(color: c.borderStrong),
          shape: const StadiumBorder(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biển báo'),
            Text(
              '${signs.length} biển · QCVN 41:2024',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: c.muted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: c.muted),
                hintText: 'Tìm theo tên, mã hoặc ý nghĩa',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                chip(null, 'Tất cả'),
                for (final MapEntry(:key, :value) in _signGroups.entries) chip(key, value),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('Không tìm thấy biển nào.', style: TextStyle(color: c.muted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      final header = i == 0 || filtered[i - 1].group != s.group;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (header)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
                              child: Text(
                                _signGroupTitles[s.group] ?? s.group,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.muted,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _SignTile(sign: s),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Một biển: mã, tên và ý nghĩa (rút gọn 2 dòng, chạm để xem đủ).
class _SignTile extends StatefulWidget {
  const _SignTile({required this.sign});

  final TrafficSign sign;

  @override
  State<_SignTile> createState() => _SignTileState();
}

class _SignTileState extends State<_SignTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sign = widget.sign;
    final c = context.colors;
    return AppCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: sign.meaning == null ? null : () => setState(() => _expanded = !_expanded),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignGroupGlyph(group: sign.group),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sign.code,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.accent),
                ),
                Text(
                  sign.name,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                ),
                if (sign.meaning != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sign.meaning!,
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: c.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hình dáng chung của nhóm biển (tròn viền đỏ, tam giác vàng...), chưa phải hình
/// từng biển.
class SignGroupGlyph extends StatelessWidget {
  const SignGroupGlyph({super.key, required this.group, this.size = 44});

  final String group;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _GlyphPainter(group)),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.group);

  final String group;

  static const _red = Color(0xFFC8211B);
  static const _yellow = Color(0xFFF6C51B);
  static const _blue = Color(0xFF1D5BB5);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, w / 2);
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    switch (group) {
      case 'bien_cam':
        canvas.drawCircle(center, w * 0.44, fill..color = Colors.white);
        canvas.drawCircle(
          center,
          w * 0.44,
          stroke
            ..color = _red
            ..strokeWidth = w * 0.1,
        );
      case 'bien_nguy_hiem':
        final path = Path()
          ..moveTo(w / 2, w * 0.08)
          ..lineTo(w * 0.94, w * 0.88)
          ..lineTo(w * 0.06, w * 0.88)
          ..close();
        canvas.drawPath(path, fill..color = _yellow);
        canvas.drawPath(
          path,
          stroke
            ..color = _red
            ..strokeWidth = w * 0.08,
        );
      case 'bien_hieu_lenh':
        canvas.drawCircle(center, w * 0.46, fill..color = _blue);
      case 'bien_chi_dan':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.06, w * 0.06, w * 0.88, w * 0.88),
            Radius.circular(w * 0.1),
          ),
          fill..color = _blue,
        );
      case 'bien_phu':
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.06, w * 0.24, w * 0.88, w * 0.52),
          Radius.circular(w * 0.06),
        );
        canvas.drawRRect(r, fill..color = Colors.white);
        canvas.drawRRect(
          r,
          stroke
            ..color = Colors.black87
            ..strokeWidth = w * 0.05,
        );
      default:
        // Vạch kẻ đường: nền xám mặt đường với vạch trắng đứt quãng.
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, w), Radius.circular(w * 0.18)),
          fill..color = const Color(0xFF5E6862),
        );
        final line = Paint()..color = Colors.white;
        for (var y = 0.1; y < 0.9; y += 0.3) {
          canvas.drawRect(Rect.fromLTWH(w * 0.44, w * y, w * 0.12, w * 0.18), line);
        }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.group != group;
}
