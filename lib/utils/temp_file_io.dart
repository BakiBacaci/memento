import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// PNG'yi geçici klasöre yazar ve yolunu döner.
Future<String?> writeTempPng(Uint8List bytes, String name) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
