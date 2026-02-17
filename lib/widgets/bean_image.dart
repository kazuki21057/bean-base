import 'package:flutter/material.dart';
import '../utils/image_utils.dart';
import 'bean_image_platform_interface.dart'
    if (dart.library.io) 'bean_image_platform_io.dart'
    if (dart.library.html) 'bean_image_platform_web.dart';

class BeanImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  const BeanImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.coffee,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it's a network URL
    if (imagePath!.startsWith('http') || imagePath!.startsWith('https')) {
      return Image.network(
        ImageUtils.getOptimizedImageUrl(imagePath) ?? imagePath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    // Platform specific local file check
    final platformImage = getInternalImage(
      imagePath!, 
      width, 
      height, 
      fit, 
      (context, error, stackTrace) => _buildPlaceholder()
    );

    if (platformImage != null) {
      return platformImage;
    }
    
    // Fallback if file doesn't exist but path is provided (maybe broken link or web)
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.brown[50],
      child: Icon(placeholderIcon, size: 40, color: Colors.brown[300]),
    );
  }
}
