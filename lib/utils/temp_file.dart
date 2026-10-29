/// Platforma göre doğru uygulamayı seçer.
///
/// `dart:io` web derlemesinde hata verdiği için doğrudan import edilemiyor;
/// koşullu export Flutter'ın bu durum için standart çözümü.
export 'temp_file_io.dart' if (dart.library.js_interop) 'temp_file_web.dart';
