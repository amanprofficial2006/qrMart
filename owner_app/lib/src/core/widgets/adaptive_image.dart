import 'package:flutter/material.dart';

import '../utils/data_url.dart';

class AdaptiveImage extends StatelessWidget {
  const AdaptiveImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (source.isEmpty) {
      child = placeholder ?? const SizedBox.shrink();
    } else {
      final bytes = decodeDataUrl(source);

      if (bytes != null) {
        child = Image.memory(bytes, width: width, height: height, fit: fit);
      } else {
        child = Image.network(
          source,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return placeholder ?? const SizedBox.shrink();
          },
        );
      }
    }

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}

