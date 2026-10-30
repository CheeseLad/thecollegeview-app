import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_urls.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import 'article_detail_screen.dart';

class DeepLinkArticleScreen extends StatefulWidget {
  final String urlOrPath;

  const DeepLinkArticleScreen({
    super.key,
    required this.urlOrPath,
  });

  @override
  State<DeepLinkArticleScreen> createState() => _DeepLinkArticleScreenState();
}

class _DeepLinkArticleScreenState extends State<DeepLinkArticleScreen> {
  Article? _article;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveDeepLink();
  }

  Future<void> _resolveDeepLink() async {
    final provider = Provider.of<ArticleProvider>(context, listen: false);
    final resolved = await provider.fetchArticleBySlugOrUrl(widget.urlOrPath);
    if (!mounted) return;
    setState(() {
      _article = resolved;
      _loading = false;
    });
  }

  Uri _buildExternalUri() {
    final raw = widget.urlOrPath.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return Uri.parse(raw);
    }
    final cleanPath = raw.startsWith('/') ? raw : '/$raw';
    return Uri.parse('${AppUrls.website}$cleanPath');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Article...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_article != null) {
      return ArticleDetailScreen(
        article: _article!,
        categoryName: 'All Articles',
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Article Not Found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not open this link inside the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
                onPressed: () async {
                  final uri = _buildExternalUri();
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

