import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureCameraPermission() async {
  var status = await Permission.camera.status;
  if (status.isGranted) return true;
  status = await Permission.camera.request();
  return status.isGranted;
}

Future<bool> ensureGalleryPermission() async {
  var status = await Permission.photos.status;
  if (status.isGranted || status.isLimited) return true;
  status = await Permission.photos.request();
  if (status.isGranted || status.isLimited) return true;

  final storage = await Permission.storage.status;
  if (storage.isGranted) return true;
  final requested = await Permission.storage.request();
  return requested.isGranted;
}
