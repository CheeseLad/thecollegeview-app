import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../providers/page_content_provider.dart';
import '../widgets/cv_navigation_drawer.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PageContentProvider>(context, listen: false).fetchAboutContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      drawer: const CVNavigationDrawer(),
      body: Consumer<PageContentProvider>(
        builder: (context, pageContentProvider, child) {
          if (pageContentProvider.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (pageContentProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading content: ${pageContentProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      pageContentProvider.fetchAboutContent();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final aboutContent = pageContentProvider.aboutContent;
          if (aboutContent == null) {
            return const Center(
              child: Text('No content available'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Card(
                margin: const EdgeInsets.all(12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: SelectionArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          aboutContent.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        HtmlWidget(
                          aboutContent.content,
                          textStyle: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          '© The College View 1999-2026 - Maintained by Jake Farrell',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, String label, IconData icon, String url) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: () => _launchURL(url),
          iconSize: 30,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
