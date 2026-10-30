import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../widgets/cv_navigation_drawer.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = AppConfig.instance.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
      ),
      drawer: const CVNavigationDrawer(),
      body: Center(
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
                  ...contacts.map(
                    (contact) => _buildContactCard(context, contact),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ContactEntry contact) {
    final primaryColor = Theme.of(context).colorScheme.primary;

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
              contact.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...contact.emails.map(
              (singleEmail) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: InkWell(
                  onTap: () => _launchEmail(context, singleEmail),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        singleEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final cleanEmail = email.trim();
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: cleanEmail,
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        return;
      }
    } catch (_) {}

    await Clipboard.setData(ClipboardData(text: cleanEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copied to clipboard: $cleanEmail'),
      ),
    );
  }
}
