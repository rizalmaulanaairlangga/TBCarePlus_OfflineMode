import 'package:flutter/material.dart';
import 'core/db/hive_init.dart';
import 'core/theme/app_theme.dart';
import 'core/settings/app_settings.dart';
import 'core/l10n/app_strings.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();
  await AppSettings.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: AppRoutes.navigatorKey,
          title: 'TBCare+',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppSettings.instance.themeMode,
          locale: Locale(AppSettings.instance.locale.code),
          builder: (context, child) {
            final scale = AppSettings.instance.fontScale;
            final mq = MediaQuery.of(context);
            // Apply font scale globally; clamp to avoid extreme overflow
            final clamped = scale.clamp(0.85, 1.5);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(clamped),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (settings) {
            final builder = AppRoutes.routes[settings.name];
            if (builder != null) {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    builder(context),
                transitionDuration: const Duration(milliseconds: 250),
                reverseTransitionDuration: const Duration(milliseconds: 200),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
              );
            }
            return null;
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
