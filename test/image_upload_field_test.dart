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

  group('ImageUploadField (T3-44)', () {
    testWidgets('画像取得に失敗すると日本語メッセージのSnackBarがfloatingで(登録ボタンと重ならずに)表示される', (tester) async {
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
      // テスト環境にはfile_pickerのプラットフォームチャンネルが無いため、
      // 「ファイルから選択」を選ぶとMissingPluginExceptionが送出され
      // _pickImageのcatch節経由でエラーSnackBarが表示される(実ファイル選択なしで検証可能)。
      await tester.tap(find.text('ファイルから選択'));
      await tester.pumpAndSettle();

      expect(find.textContaining('画像の取得に失敗しました'), findsOneWidget);
      expect(find.textContaining('Error picking image'), findsNothing);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });
  });
}
