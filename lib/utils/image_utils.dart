class ImageUtils {
  static String? getOptimizedImageUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;
    
    // Handle Google Drive URLs
    // Convert https://drive.google.com/file/d/FILE_ID/view... to https://drive.google.com/uc?export=view&id=FILE_ID
    if (originalUrl.contains('drive.google.com')) {
      String? id;
      
      // Pattern 1: /file/d/ID
      final fileIdRegExp = RegExp(r'/file/d/([^/]+)');
      final match = fileIdRegExp.firstMatch(originalUrl);
      if (match != null) {
        id = match.group(1);
      }
      
      // Pattern 2: id=ID
      if (id == null) {
        final idRegExp = RegExp(r'id=([^&]+)');
        final idMatch = idRegExp.firstMatch(originalUrl);
        if (idMatch != null) {
          id = idMatch.group(1);
        }
      }

      if (id != null) {
        // 'uc?export=view' はCORSヘッダーを返さないため、Flutter Web(CanvasKit)の
        // Image.network がバイト取得時にCORSエラーで失敗し画像が表示されない
        // (placeholderにフォールバックするため一見エラーが出ないように見える)。
        // lh3.googleusercontent.com のサムネイル配信はCORS対応済みのため代替する。
        return 'https://lh3.googleusercontent.com/d/$id';
      }
    }
    
    return originalUrl;
  }
}
