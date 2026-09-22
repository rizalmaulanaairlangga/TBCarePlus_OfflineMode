import 'package:flutter/material.dart';
import '../features/splash/pages/splash_page.dart';
import '../features/home/pages/home_page.dart';
import '../features/assessment/pages/full_assessment_page.dart';
import '../features/result/pages/result_page.dart';
import '../features/history/pages/history_page.dart';
import '../features/history/pages/history_detail_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/about/pages/about_page.dart';
import '../features/settings/pages/settings_page.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String splash = '/splash';
  static const String home = '/';
  static const String fullAssessment = '/full-assessment';
  static const String result = '/result';
  static const String history = '/history';
  static const String historyDetail = '/history-detail';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String about = '/about';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashPage(),
    home: (context) => const HomePage(),
    fullAssessment: (context) => const FullAssessmentPage(),
    result: (context) => const ResultPage(),
    history: (context) => const HistoryPage(),
    historyDetail: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final detail = args['detailData'] as Map<String, dynamic>?;
      return HistoryDetailPage(item: args, detail: detail);
    },
    profile: (context) => const ProfilePage(),
    about: (context) => const AboutPage(),
    settings: (context) => const SettingsPage(),
  };
}
