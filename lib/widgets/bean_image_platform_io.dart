// ignore_for_file: avoid_catches_without_on_clauses
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
    // Decode path to handle URL-encoded characters (like Japanese or spaces in absolute Linux paths)。
    // パス中に単独の'%'(正しいパーセントエンコーディングの一部でない)が含まれる場合、
    // Uri.decodeFullはFormatExceptionを投げるため、その場合は無変換の元パスにフォールバックする。
    String decodedPath = path;
    try {
      decodedPath = Uri.decodeFull(path);
    } catch (_) {
      decodedPath = path;
    }
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
