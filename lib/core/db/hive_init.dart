import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveInit {
  static const String boxHistories = 'histories';
  static const String boxMeta = 'meta';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxHistories);
    await Hive.openBox(boxMeta);
  }

  static Box get historiesBox => Hive.box(boxHistories);
  static Box get metaBox => Hive.box(boxMeta);
}
