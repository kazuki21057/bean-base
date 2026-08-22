// T5-B14 受け入れテスト: 画像のローカル保存。
//
// 完了条件: 画像を登録(LocalImageService.saveImage/uploadImage)→サービスの
// 新しいインスタンスを作って同じパスを参照しても画像ファイルが存在し読み込める
// (=「再起動後も表示される」の実質的な検証)。
//
// path_provider はプラットフォームチャネル経由のため、flutter test(Windows実行)
// 環境でも安定して動くよう PathProviderPlatform.instance をテスト用の
// フェイク実装(一時ディレクトリを返すだけ)に差し替える。
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:bean_base/config/app_edition.dart';
import 'package:bean_base/services/image_service.dart';

/// テスト専用: useLocalImages: true を明示したエディション
/// (kPublicEditionは既にtrueだが、依存を明示するためテスト側でも定義する)。
const AppEdition _kLocalImagesTestEdition = AppEdition(
  kind: Edition.public,
  enabledScreens: kAllAppScreens,
  useLocalDb: false,
  useLocalImages: true,
  aiKeyMode: AiKeyMode.proxy,
  showAds: false,
  enableSubscription: false,
  showDebugScreens: false,
);

/// テスト用: getApplicationDocumentsPath() が一時ディレクトリを返すだけの
/// フェイク実装。他のメソッドは本テストでは使わない。
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  group('受け入れ(T5-B14 画像のローカル保存)', () {
    late Directory tempRoot;
    late ProviderContainer container;
    late LocalImageService service;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('t5_b14_docs_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempRoot.path);
      container = ProviderContainer(
        overrides: [
          appEditionProvider.overrideWithValue(_kLocalImagesTestEdition),
        ],
      );
      service = container.read(imageServiceProvider) as LocalImageService;
    });

    tearDown(() async {
      container.dispose();
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    /// テスト用の疑似ファイル(一時ディレクトリに書いたバイト列)を
    /// PlatformFileとして返す。
    Future<PlatformFile> pseudoFile(String name, List<int> bytes) async {
      final srcDir = await Directory.systemTemp.createTemp('t5_b14_src_');
      final srcFile = File('${srcDir.path}${Platform.pathSeparator}$name');
      await srcFile.writeAsBytes(bytes);
      return PlatformFile(path: srcFile.path, name: name, size: bytes.length);
    }

    test('saveImageで保存したファイルが実在し、内容が一致する', () async {
      final bytes = [1, 2, 3, 4, 5];
      final file = await pseudoFile('bean_test.jpg', bytes);

      final savedPath = await service.saveImage(file);

      expect(savedPath, isNotNull);
      final savedFile = File(savedPath!);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsBytes(), equals(bytes));
    });

    test('新しいLocalImageServiceインスタンス(再起動を模す)でも同じパスが読み込める', () async {
      final bytes = [9, 8, 7, 6];
      final file = await pseudoFile('grinder_test.png', bytes);

      final savedPath = await service.uploadImage(file);
      expect(savedPath, isNotNull);

      // 「アプリ再起動」を模して、状態を共有しない新しいインスタンス(別の
      // ProviderContainer由来のLocalImageService)を作る。
      final restartedContainer = ProviderContainer(
        overrides: [
          appEditionProvider.overrideWithValue(_kLocalImagesTestEdition),
        ],
      );
      final restartedService = restartedContainer.read(imageServiceProvider) as LocalImageService;
      addTearDown(restartedContainer.dispose);

      // restartedServiceは状態を持たないが、保存先パス自体が読み込めることを確認する。
      final savedFile = File(savedPath!);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsBytes(), equals(bytes));
      // restartedServiceでも同じ削除処理が問題なく動く(=状態非依存であることの確認)。
      await restartedService.deleteImage(savedPath);
      expect(await savedFile.exists(), isFalse);
    });

    test('deleteImageでファイルが削除される', () async {
      final bytes = [1, 1, 1];
      final file = await pseudoFile('dripper_test.jpg', bytes);
      final savedPath = await service.saveImage(file);
      expect(savedPath, isNotNull);
      final savedFile = File(savedPath!);
      expect(await savedFile.exists(), isTrue);

      await service.deleteImage(savedPath);

      expect(await savedFile.exists(), isFalse);
    });

    test('Drive URL(https)を渡した場合はdeleteImageが何もしない', () async {
      const driveUrl = 'https://drive.google.com/uc?id=dummy_id';
      // 例外が発生しないこと、かつ副作用としてローカルファイル操作をしないことのみ確認する。
      await service.deleteImage(driveUrl);
    });

    // 回帰テスト(adversaryレビュー Critical指摘対応): カメラ撮影・画像リサイズ後は
    // PlatformFile(path: null, bytes: ...)の形で渡される(image_upload_field.dartの
    // pickImageFile参照)。pathが無くbytesのみでも保存できることを確認する。
    test('pathがnullでbytesのみのPlatformFile(カメラ撮影・リサイズ後を模す)でも保存できる', () async {
      final bytes = [42, 43, 44, 45];
      final file = PlatformFile(
        name: 'camera_capture.jpg',
        size: bytes.length,
        bytes: Uint8List.fromList(bytes),
      );

      final uploadedPath = await service.uploadImage(file);
      expect(uploadedPath, isNotNull);
      final uploadedFile = File(uploadedPath!);
      expect(await uploadedFile.exists(), isTrue);
      expect(await uploadedFile.readAsBytes(), equals(bytes));

      final savedPath = await service.saveImage(file);
      expect(savedPath, isNotNull);
      final savedFile = File(savedPath!);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsBytes(), equals(bytes));
    });
  });
}
