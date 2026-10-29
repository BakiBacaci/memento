import 'dart:typed_data';

/// Web'de dosya sistemi yok. null dönünce çağıran taraf metin paylaşımına
/// düşüyor.
Future<String?> writeTempPng(Uint8List bytes, String name) async => null;
