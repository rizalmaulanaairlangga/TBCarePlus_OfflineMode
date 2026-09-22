import 'package:flutter/material.dart';
import 'app_strings.dart';
import '../settings/app_settings.dart';

class L10n {
  static AppLocale localeOf(BuildContext context) {
    // Use settings notifier; fallback to id
    return AppSettings.instance.locale;
  }

  static String t(BuildContext context, String key, [Map<String, String>? params]) {
    final loc = localeOf(context);
    return AppStrings.tr(key, loc, params);
  }
}

extension L10nContext on BuildContext {
  String tr(String key, [Map<String, String>? params]) => L10n.t(this, key, params);
  AppLocale get appLocale => L10n.localeOf(this);
}
