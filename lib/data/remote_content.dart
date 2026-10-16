import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Nơi tải bản mới nhất của các file dữ liệu sửa được mà không cần build lại
/// app (danh sách video thực hành, trung tâm dạy lái).
abstract class ContentSource {
  /// Nội dung file [file] (tên trong `assets/data/`), hoặc null nếu không tải được.
  Future<String?> fetch(String file);
}

/// Không tải gì, chỉ dùng dữ liệu đóng gói sẵn trong app.
class NoRemoteContent implements ContentSource {
  const NoRemoteContent();

  @override
  Future<String?> fetch(String file) async => null;
}

/// Đọc file từ nhánh `main` của repo trên GitHub: sửa và commit file trong
/// `assets/data/` là app đã cài nhận được ở lần mở sau.
class GithubContentSource implements ContentSource {
  GithubContentSource({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = 'https://raw.githubusercontent.com/toanquantic/gplx/main/assets/data/';

  final http.Client _client;

  @override
  Future<String?> fetch(String file) async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl$file')).timeout(const Duration(seconds: 8));
      return res.statusCode == 200 ? utf8.decode(res.bodyBytes) : null;
    } catch (_) {
      return null;
    }
  }
}

/// Phát ra dữ liệu dùng được ngay (bản đã tải lần trước, không có thì bản
/// đóng gói sẵn), rồi phát thêm bản mới nhất nếu tải được và đọc được.
/// Bản tải về đọc lỗi thì bỏ qua, giữ bản đang có.
Stream<T> loadContent<T>({
  required AssetBundle bundle,
  required ContentSource source,
  required String file,
  required T Function(String json) parse,
}) async* {
  final key = 'noi_dung_$file';
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}
  final cached = prefs?.getString(key);
  T? local;
  if (cached != null) {
    try {
      local = parse(cached);
    } catch (_) {}
  }
  yield local ?? parse(await bundle.loadString('assets/data/$file'));

  final fresh = await source.fetch(file);
  if (fresh == null || fresh == cached) return;
  final T value;
  try {
    value = parse(fresh);
  } catch (_) {
    return;
  }
  await prefs?.setString(key, fresh);
  yield value;
}
