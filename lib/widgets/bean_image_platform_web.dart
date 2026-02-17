import 'package:flutter/material.dart';

Widget? getInternalImage(
  String path, 
  double? width, 
  double? height, 
  BoxFit fit, 
  Widget Function(BuildContext, Object, StackTrace?) errorBuilder
) {
  return null; // Local paths not supported on web
}
