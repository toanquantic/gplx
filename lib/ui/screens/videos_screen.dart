import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../data/practical_content.dart';
import '../app_scope.dart';
import '../theme.dart';
import 'schools_screen.dart' show openExternal;

/// Trình phát YouTube nhúng chạy trên Android, iOS, macOS và web; Windows và
/// Linux mở video bằng trình duyệt.
bool get canEmbedYoutube =>
    kIsWeb ||
    const {
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }.contains(defaultTargetPlatform);

/// Video hướng dẫn thực hành lái xe, gom theo nhóm hợp với hạng đang học.
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  Stream<PracticeVideoList>? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= PracticeVideoList.load(
      DefaultAssetBundle.of(context),
      AppScope.read(context).content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = AppScope.of(context).progress.classCode;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Video thực hành'),
            Text(
              'Hợp với hạng $code',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: c.muted),
            ),
          ],
        ),
      ),
      body: StreamBuilder<PracticeVideoList>(
        stream: _data,
        builder: (context, snap) {
          final data = snap.data;
          if (data == null) {
            return snap.hasError
                ? const Center(child: Text('Không đọc được danh sách video.'))
                : const Center(child: CircularProgressIndicator());
          }
          final groups = data.forClass(code);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Chưa có video thực hành cho hạng $code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: c.muted),
                  ),
                ),
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    group.title,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                  ),
                ),
                for (final v in group.videos) ...[_VideoTile(video: v), const SizedBox(height: 10)],
              ],
              Text(data.note, style: TextStyle(fontSize: 12, color: c.muted)),
            ],
          );
        },
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final PracticeVideo video;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: () => canEmbedYoutube
          ? Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => VideoPlayerScreen(video: video)),
            )
          : openExternal(context, video.watchUrl),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 120,
              height: 68,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: c.tile),
                  ),
                  const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              video.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Xem một video bằng trình phát YouTube nhúng, kèm nút mở trong app YouTube
/// (khi chủ kênh tắt nhúng thì chỉ xem được bằng cách này).
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.video});

  final PracticeVideo video;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.video.id,
    params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true),
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Video thực hành')),
      body: ListView(
        children: [
          YoutubePlayer(controller: _controller),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.title,
                  style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Mở trên YouTube'),
                  onPressed: () => openExternal(context, widget.video.watchUrl),
                ),
                const SizedBox(height: 8),
                Text(
                  'Không phát được thì mở trên YouTube: một số kênh không cho phát video '
                  'trong app khác.',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
