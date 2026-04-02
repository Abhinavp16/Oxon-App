import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:shimmer/shimmer.dart';
import 'product_image_placeholder.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final String? blurHash;
  final String category;
  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.blurHash,
    required this.category,
    required this.name,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return ProductImagePlaceholder(category: category, name: name);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) =>
          ProductImagePlaceholder(category: category, name: name),
    );
  }

  Widget _buildPlaceholder() {
    if (blurHash != null && blurHash!.isNotEmpty) {
      return BlurHash(hash: blurHash!);
    }

    // Fallback to Shimmer if no blurHash exists
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }
}
