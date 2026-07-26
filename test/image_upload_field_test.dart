import 'package:bean_base/widgets/image_upload_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageUploadField (T3-41)', () {
    testWidgets('アップロードアイコンをタップするとファイル/カメラの選択ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageUploadField(onImageUploaded: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Upload Image'));
      await tester.pumpAndSettle();

      expect(find.text('画像の取得方法'), findsOneWidget);
      expect(find.text('ファイルから選択'), findsOneWidget);
      expect(find.text('カメラで撮影'), findsOneWidget);
    });
  });
}
