import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/page_content_provider.dart';
import '../widgets/cv_navigation_drawer.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PageContentProvider>(context, listen: false).fetchContactInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
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
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading content: ${pageContentProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      pageContentProvider.fetchContactInfo();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final contactInfo = pageContentProvider.contactInfo;
          if (contactInfo == null) {
            return const Center(
              child: Text('No contact information available'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please email press releases to the appropriate section only.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildContactSection(
                      'Editor-in-Chief: ${contactInfo.editorInChief}',
                      contactInfo.editorInChiefEmail,
                    ),
                    _buildContactSection(
                      'Deputy Chief Editor: ${contactInfo.deputyEditor}',
                      contactInfo.deputyEditorEmail,
                    ),
                    _buildContactSection(
                      'News: ${contactInfo.newsEditors}',
                      contactInfo.newsEmail,
                    ),
                    _buildContactSection(
                      'Opinions & Features: ${contactInfo.opinionFeaturesEditors}',
                      '${contactInfo.opinionEmail}\n${contactInfo.featuresEmail}',
                    ),
                    _buildContactSection(
                      'Sports: ${contactInfo.sportsEditors}',
                      contactInfo.sportsEmail,
                    ),
                    _buildContactSection(
                      'Lifestyle: ${contactInfo.lifestyleEditors}',
                      contactInfo.lifestyleEmail,
                    ),
                    _buildContactSection(
                      'The Hype: ${contactInfo.hypeEditors}',
                      contactInfo.hypeEmail,
                    ),
                    _buildContactSection(
                      'Satire & Cartoons: ${contactInfo.satireEditors}',
                      contactInfo.satireEmail,
                    ),
                    _buildContactSection(
                      'Irish & Lang: ${contactInfo.irishEditors}',
                      contactInfo.irishEmail,
                    ),
                    _buildContactSection(
                      'E-paper Layout Editors and Sub-editors', contactInfo.productionEmail
                    ),
                    /*const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contactInfo.productionEmail,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              '(e-paper layout editors and sub-editors)',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),*/
                    _buildContactSection(
                      'Webmaster: ${contactInfo.webmaster}',
                      contactInfo.webmasterEmail,
                    ),
                    /*const SizedBox(height: 30),
                    const Text(
                      '© The College View 1999-2026 - Maintained by Jake Farrell',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),*/
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactSection(String title, String email) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launchEmail(email),
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  // decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
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

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
