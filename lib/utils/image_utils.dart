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
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }
    
    return originalUrl;
  }
}
