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
    // Decode path to handle URL-encoded characters (like Japanese or spaces in absolute Linux paths)
    final decodedPath = Uri.decodeFull(path);
    final file = File(decodedPath);
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
