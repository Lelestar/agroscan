import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/splash/agro_splash_view.dart';
import 'core/theme/agro_theme.dart';
import 'router/app_router.dart';

class AgroScanApp extends ConsumerStatefulWidget {
  const AgroScanApp({super.key});

  @override
  ConsumerState<AgroScanApp> createState() => _AgroScanAppState();
}

class _AgroScanAppState extends ConsumerState<AgroScanApp> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await initializeDateFormatting('fr');
    } finally {
      if (mounted) {
        setState(() => _ready = true);
        WidgetsBinding.instance.allowFirstFrame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AgroScan',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AgroTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child != null) child,
            if (!_ready) const AgroSplashView(),
          ],
        );
      },
    );
  }
}
