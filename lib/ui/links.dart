import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cách mở một liên kết.
enum LinkTarget {
  /// Trang web mở ngay trong app (Safari View Controller trên iOS, Custom Tabs
  /// trên Android), có nút Xong/đóng để quay lại.
  inApp,

  /// Trang mở bằng WebView của app, không bao giờ chuyển sang app khác. Dùng
  /// cho YouTube: mở bằng app YouTube thì nút quay lại của YouTube không đưa
  /// người dùng về app này.
  inAppWebView,

  /// App ngoài: gọi điện, Google Maps.
  external,
}

/// Mở [url]; máy không có Custom Tabs thì thử WebView của app, cách mở trong
/// app không được hỗ trợ (Windows, Linux) thì mở bằng app ngoài, vẫn không
/// được thì báo bằng SnackBar.
Future<void> openLink(BuildContext context, Uri url, {LinkTarget target = LinkTarget.inApp}) async {
  final messenger = ScaffoldMessenger.of(context);
  final web = url.scheme == 'http' || url.scheme == 'https';
  final modes = [
    if (web && target == LinkTarget.inApp) LaunchMode.inAppBrowserView,
    if (web && target != LinkTarget.external) LaunchMode.inAppWebView,
    LaunchMode.externalApplication,
  ];
  for (final mode in modes) {
    try {
      if (mode != LaunchMode.externalApplication && !await supportsLaunchMode(mode)) continue;
      if (await launchUrl(url, mode: mode)) return;
    } catch (_) {}
  }
  messenger.showSnackBar(const SnackBar(content: Text('Không mở được liên kết trên máy này.')));
}
