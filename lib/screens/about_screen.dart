import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../config/app_config.dart';
import '../services/wp_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/deep_link_handler.dart';
import '../widgets/cv_navigation_drawer.dart';
import '../widgets/skeleton.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<String> _aboutHtmlFuture = WpApiService.fetchAboutHtml();

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      drawer: const CVNavigationDrawer(),
      body: FutureBuilder<String>(
        future: _aboutHtmlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AboutScreenSkeleton();
          }

          final htmlContent = snapshot.data ?? config.aboutHtml;

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
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          HtmlWidget(
                            htmlContent,
                            textStyle:
                                const TextStyle(fontSize: 16, height: 1.5),
                            customStylesBuilder: (element) =>
                                AppTheme.editorialHtmlStyles(
                                    context, element.localName),
                            onTapUrl: (url) =>
                                DeepLinkHandler.handleTappedUrl(context, url),
                          ),
                          // const SizedBox(height: 24),
                          /*InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => DeepLinkHandler.launchExternalUrl(
                              config.privacyPolicyUrl,
                            ),
                             child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${config.appName} Mobile App Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ), 
                          ),*/
                          const SizedBox(height: 20),
                          Text(
                            config.copyrightNotice,
                            style: const TextStyle(
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
}
