import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaIcon extends StatelessWidget {
  final FaIconData icon;
  final String url;

  const SocialMediaIcon({super.key, required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _launchURL(context, url);
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FaIcon(icon, size: 28),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }
}
