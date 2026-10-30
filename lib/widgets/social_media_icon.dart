import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/deep_link_handler.dart';

class SocialMediaIcon extends StatelessWidget {
  final FaIconData icon;
  final String url;

  const SocialMediaIcon({super.key, required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => DeepLinkHandler.launchExternalUrl(
        url,
        context: context,
        showErrorSnackBar: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FaIcon(icon, size: 28),
      ),
    );
  }
}
