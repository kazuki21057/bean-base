import 'package:flutter/material.dart';
import 'dart:io';

Widget? getInternalImage(
  String path, 
  double? width, 
  double? height, 
  BoxFit fit, 
  Widget Function(BuildContext, Object, StackTrace?) errorBuilder
) {
  try {
    final file = File(path);
    if (file.existsSync()) {
        return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: errorBuilder,
        );
    }
  } catch (e) {
    // Ignore invalid path errors on IO
  }
  return null;
}
