import 'dart:io';

import 'package:flutter/foundation.dart';

/// 桌面端（Windows / macOS / Linux）
bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
