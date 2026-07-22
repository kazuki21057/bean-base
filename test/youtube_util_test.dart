import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/utils/youtube_util.dart';

void main() {
  const expectedId = 'dQw4w9WgXcQ'; // 11文字のサンプルID

  group('youtubeVideoId', () {
    test('watch形式(https)からIDを抽出', () {
      expect(youtubeVideoId('https://www.youtube.com/watch?v=$expectedId'),
          expectedId);
    });

    test('watch形式の追加クエリ付きでもIDを抽出', () {
      expect(
          youtubeVideoId(
              'https://www.youtube.com/watch?v=$expectedId&t=42s&list=abc'),
          expectedId);
    });

    test('youtu.be短縮URLからIDを抽出', () {
      expect(youtubeVideoId('https://youtu.be/$expectedId'), expectedId);
    });

    test('embed形式からIDを抽出', () {
      expect(youtubeVideoId('https://www.youtube.com/embed/$expectedId'),
          expectedId);
    });

    test('shorts形式からIDを抽出', () {
      expect(youtubeVideoId('https://www.youtube.com/shorts/$expectedId'),
          expectedId);
    });

    test('http:// をhttps://に正規化して抽出', () {
      expect(youtubeVideoId('http://www.youtube.com/watch?v=$expectedId'),
          expectedId);
    });

    test('スキーム無しの手入力URLも救済して抽出', () {
      expect(youtubeVideoId('youtube.com/watch?v=$expectedId'), expectedId);
      expect(youtubeVideoId('youtu.be/$expectedId'), expectedId);
    });

    test('前後の空白をトリムして抽出', () {
      expect(youtubeVideoId('  https://youtu.be/$expectedId  '), expectedId);
    });

    test('YouTube以外のURLはnull', () {
      expect(youtubeVideoId('https://example.com/watch?v=$expectedId'), isNull);
      expect(youtubeVideoId('https://vimeo.com/123456789'), isNull);
    });

    test('null・空文字はnull', () {
      expect(youtubeVideoId(null), isNull);
      expect(youtubeVideoId(''), isNull);
      expect(youtubeVideoId('   '), isNull);
    });
  });

  group('isYoutubeUrl', () {
    test('YouTube URLはtrue、それ以外はfalse', () {
      expect(isYoutubeUrl('https://youtu.be/$expectedId'), isTrue);
      expect(isYoutubeUrl('https://example.com'), isFalse);
      expect(isYoutubeUrl(null), isFalse);
    });
  });
}
