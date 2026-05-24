import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.deferFirstFrame();
  runApp(const ProviderScope(child: AgroScanApp()));
}
