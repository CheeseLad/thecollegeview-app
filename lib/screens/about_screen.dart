import 'package:material_ui/material_ui.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/deep_link_handler.dart';
import '../widgets/cv_navigation_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      drawer: const CVNavigationDrawer(),
      body: Center(
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
                      Semantics(
                        header: true,
                        child: const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      HtmlWidget(
                        config.aboutHtml,
                        textStyle:
                            const TextStyle(fontSize: 16, height: 1.5),
                        customStylesBuilder: (element) =>
                            AppTheme.editorialHtmlStyles(
                                context, element.localName),
                        onTapUrl: (url) =>
                            DeepLinkHandler.handleTappedUrl(context, url),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      Semantics(
                        button: true,
                        link: true,
                        label: 'Privacy Policy (opens in external browser)',
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              DeepLinkHandler.launchExternalUrl(
                            config.privacyPolicyUrl,
                          ),
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(minHeight: 44),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCopyrightNotice(context, config.copyrightNotice),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyrightNotice(BuildContext context, String copyrightNotice) {
    const baseStyle = TextStyle(
      fontSize: 14,
      fontStyle: FontStyle.italic,
    );

    final linkMatch = RegExp(
      r'''<a\s+[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>''',
      caseSensitive: false,
    ).firstMatch(copyrightNotice);

    if (linkMatch == null) {
      return Text(copyrightNotice, style: baseStyle);
    }

    final rawPrefix = copyrightNotice.substring(0, linkMatch.start);
    final prefix =
        rawPrefix.endsWith(' ') ? rawPrefix.substring(0, rawPrefix.length - 1) : rawPrefix;
    final href = linkMatch.group(1)!.trim();
    final linkText = linkMatch.group(2)!.trim();
    final suffix = copyrightNotice.substring(linkMatch.end);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Semantics(
              button: true,
              link: true,
              label: '$linkText (opens in external browser)',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => DeepLinkHandler.launchExternalUrl(href),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 6.0,
                  ),
                  child: Text(
                    linkText,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (suffix.isNotEmpty) TextSpan(text: suffix),
        ],
      ),
    );
  }
}
