import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static const _clinicSearchUrl =
      'https://www.google.com/maps/search/klinik+terdekat/';

  static Future<void> launchExternalUrl(
    BuildContext context,
    String urlString,
  ) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka tautan: $urlString')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka tautan: $urlString')),
      );
    }
  }

  static Future<void> launchLinkedIn(
    BuildContext context,
    String url,
  ) =>
      launchExternalUrl(context, url);

  static Future<void> launchNearestClinicMap(BuildContext context) =>
      launchExternalUrl(context, _clinicSearchUrl);
}
