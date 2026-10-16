import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/practical_content.dart';
import '../theme.dart';

/// Mở [url] bằng app ngoài (trình duyệt, gọi điện, bản đồ, YouTube); không mở
/// được thì báo bằng SnackBar.
Future<void> openExternal(BuildContext context, Uri url) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) {
    messenger.showSnackBar(const SnackBar(content: Text('Không mở được liên kết trên máy này.')));
  }
}

/// Giới thiệu các trung tâm dạy lái xe: tên, địa chỉ, nút gọi, website và bản đồ.
class SchoolsScreen extends StatefulWidget {
  const SchoolsScreen({super.key});

  @override
  State<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends State<SchoolsScreen> {
  Future<DrivingSchoolList>? _data;
  String? _province;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= DrivingSchoolList.load(DefaultAssetBundle.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Trung tâm dạy lái xe')),
      body: FutureBuilder<DrivingSchoolList>(
        future: _data,
        builder: (context, snap) {
          final data = snap.data;
          if (data == null) {
            return snap.hasError
                ? const Center(child: Text('Không đọc được danh sách trung tâm.'))
                : const Center(child: CircularProgressIndicator());
          }
          final schools = data.schools
              .where((s) => _province == null || s.province == _province)
              .toList();

          Widget chip(String? province, String label) {
            final on = _province == province;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: on,
                showCheckmark: false,
                onSelected: (_) => setState(() => _province = province),
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [chip(null, 'Tất cả'), for (final p in data.provinces) chip(p, p)],
                ),
              ),
              const SizedBox(height: 12),
              for (final s in schools) ...[_SchoolCard(school: s), const SizedBox(height: 10)],
              Text(data.note, style: TextStyle(fontSize: 12, color: c.muted)),
            ],
          );
        },
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.school});

  final DrivingSchool school;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = school;
    final mapUrl = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${s.name}, ${s.address}',
    });
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 6),
                child: Icon(Icons.place_outlined, size: 16, color: c.muted),
              ),
              Expanded(
                child: Text(
                  s.address,
                  style: TextStyle(fontSize: 13, height: 1.45, color: c.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (s.phone != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Gọi'),
                  onPressed: () => openExternal(context, Uri(scheme: 'tel', path: s.phone)),
                ),
              if (s.website != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.language, size: 18),
                  label: const Text('Website'),
                  onPressed: () => openExternal(context, Uri.parse(s.website!)),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Bản đồ'),
                onPressed: () => openExternal(context, mapUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
