import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analysis/analysis_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/capture/scanner_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/advice/advice_screen.dart';
import '../features/explanation/explanation_screen.dart';
import '../features/result/result_screen.dart';
import '../shared/widgets/bottom_nav_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Observes when full-screen routes (e.g. capture) become visible again.
final agroRouteObserver = RouteObserver<ModalRoute<void>>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    observers: [agroRouteObserver],
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scanner',
                builder: (context, state) => const ScannerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/capture',
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/analysis',
        builder: (context, state) => const AnalysisScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/result/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ResultScreen(diagnosisId: id);
        },
        routes: [
          GoRoute(
            path: 'explanation',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ExplanationScreen(diagnosisId: id);
            },
          ),
          GoRoute(
            path: 'advice',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdviceScreen(diagnosisId: id);
            },
          ),
        ],
      ),
    ],
  );
});
