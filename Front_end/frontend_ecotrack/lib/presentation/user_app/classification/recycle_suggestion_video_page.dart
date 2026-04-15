import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecycleSuggestionVideoPage extends StatefulWidget {
  final String url;
  final String title;

  const RecycleSuggestionVideoPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<RecycleSuggestionVideoPage> createState() =>
      _RecycleSuggestionVideoPageState();
}

class _RecycleSuggestionVideoPageState
    extends State<RecycleSuggestionVideoPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_normalizeVideoUrl(widget.url)));
  }

  String _normalizeVideoUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.contains('youtube.com/watch')) {
      final uri = Uri.tryParse(trimmed);
      final videoId = uri?.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1';
      }
    }

    if (trimmed.contains('youtu.be/')) {
      final uri = Uri.tryParse(trimmed);
      final pathSegments = uri?.pathSegments;
      if (pathSegments != null && pathSegments.isNotEmpty) {
        final videoId = pathSegments.first;
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1';
      }
    }

    if (trimmed.contains('youtube.com/shorts/')) {
      final uri = Uri.tryParse(trimmed);
      final pathSegments = uri?.pathSegments;
      final shortIndex = pathSegments?.indexOf('shorts') ?? -1;
      if (shortIndex >= 0 &&
          pathSegments != null &&
          pathSegments.length > shortIndex + 1) {
        final videoId = pathSegments[shortIndex + 1];
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1';
      }
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF062D2B),
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDEDE8)),
            ),
            clipBehavior: Clip.antiAlias,
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
