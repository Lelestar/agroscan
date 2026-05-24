import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/permissions.dart';
import '../../core/theme/agro_colors.dart';
import '../../providers/scan_session_provider.dart';
import '../../router/app_router.dart';
import '../../router/navigation_helpers.dart';
import '../../shared/widgets/agro_detail_app_bar.dart';
import '../../shared/widgets/scan_frame_overlay.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with RouteAware, WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _bootstrapped = false;
  bool _routeSubscribed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && !_routeSubscribed) {
      agroRouteObserver.subscribe(this, route);
      _routeSubscribed = true;
    }
    if (!_bootstrapped) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
    }
  }

  bool get _openGallery =>
      GoRouterState.of(context).uri.queryParameters['gallery'] == '1';

  Future<void> _bootstrap() async {
    if (_openGallery) {
      if (mounted) setState(() => _initializing = false);
      await _pickFromGallery();
      return;
    }
    await _initCamera();
  }

  /// Called when this route is removed (back, close, or replace).
  @override
  void didPop() {
    unawaited(_releaseCamera());
  }

  /// Called when analysis/result (or another route) is popped off capture.
  @override
  void didPopNext() {
    unawaited(_resumeAfterChildRoute());
  }

  Future<void> _closeCapture() async {
    await _releaseCamera();
    if (!mounted) return;
    leaveCaptureScreen(context, ref);
  }

  Future<void> _resumeAfterChildRoute() async {
    if (!mounted || _error != null) return;
    if (_openGallery) {
      if (mounted) setState(() => _initializing = false);
      await _pickFromGallery();
      return;
    }
    setState(() => _initializing = true);
    await _initCamera();
  }

  Future<void> _releaseCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (mounted) {
      setState(() => _initializing = true);
    }
    try {
      await controller.dispose();
    } catch (_) {
      // Already disposed or hardware busy.
    }
  }

  bool get _canShowCameraPreview =>
      !_initializing &&
      _controller != null &&
      _controller!.value.isInitialized;

  Future<void> _initCamera() async {
    await _releaseCamera();
    final granted = await ensureCameraPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _error = 'Permission caméra refusée.';
        _initializing = false;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _error = 'Aucune caméra disponible.';
          _initializing = false;
        });
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible d\'ouvrir la caméra.';
        _initializing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final granted = await ensureGalleryPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission galerie refusée.')),
        );
        await _closeCapture();
      }
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (file == null) {
      await _closeCapture();
      return;
    }
    await _startAnalysis(file.path);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      // Hide preview before dispose; keep [_controller] until [_releaseCamera].
      if (mounted) setState(() => _initializing = true);
      await _startAnalysis(photo.path);
    } catch (_) {
      if (!mounted) return;
      if (_error == null &&
          (_controller == null || !_controller!.value.isInitialized)) {
        setState(() => _initializing = true);
        await _initCamera();
      } else if (_initializing && _canShowCameraPreview) {
        setState(() => _initializing = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la capture.')),
      );
    }
  }

  Future<void> _startAnalysis(String path) async {
    await _releaseCamera();
    if (!mounted) return;
    ref.read(pendingImagePathProvider.notifier).set(path);
    await context.push('/analysis');
    // Camera / gallery resume is handled in [didPopNext] when this route
    // becomes current again (including after result is popped or deleted).
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_releaseCamera());
    } else if (state == AppLifecycleState.resumed &&
        mounted &&
        _error == null &&
        _controller == null &&
        !_initializing &&
        !_openGallery &&
        ModalRoute.of(context)?.isCurrent == true) {
      unawaited(_initCamera());
    }
  }

  @override
  void dispose() {
    if (_routeSubscribed) {
      agroRouteObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_releaseCamera());
    super.dispose();
  }

  Widget _wrapExit(Widget child) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_closeCapture());
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return _wrapExit(
        const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (_error != null) {
      return _wrapExit(
        Scaffold(
          appBar: AgroDetailAppBar(
            title: 'Capture',
            onBack: () => unawaited(_closeCapture()),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _pickFromGallery,
                    child: const Text('Importer depuis la galerie'),
                  ),
                  TextButton(
                    onPressed: () => unawaited(_closeCapture()),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final preview = _canShowCameraPreview
        ? CameraPreview(_controller!)
        : const ColoredBox(color: Colors.black);

    return _wrapExit(
      Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          preview,
          const ScanFrameOverlay(showScanLine: false),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QualityChip(icon: Icons.wb_sunny_outlined, label: 'Bonne lumière'),
                    SizedBox(width: 8),
                    _QualityChip(icon: Icons.center_focus_strong, label: 'Feuille nette'),
                  ],
                ),
                const SizedBox(height: 8),
                const _QualityChip(
                  icon: Icons.crop_free,
                  label: 'Remplir le cadre',
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleButton(
                        icon: Icons.photo_outlined,
                        onTap: _pickFromGallery,
                      ),
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      _CircleButton(
                        icon: Icons.close,
                        onTap: () => unawaited(_closeCapture()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AgroColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AgroColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
