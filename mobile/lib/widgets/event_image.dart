import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/event_theme.dart';

class EventImage extends StatelessWidget {
  final Event event;
  final double? height;
  final double? width;
  final BoxFit fit;

  const EventImage({
    super.key,
    required this.event,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final image = event.image;
    if (image == null || image.isEmpty) {
      return _placeholder(context);
    }

    final theme = EventTheme.fromAsset(image);
    if (theme != null) {
      return Image.asset(
        theme.asset,
        height: height,
        width: width,
        fit: fit,
      );
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.6)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          color: Colors.white,
          size: height != null && height! > 100 ? 48 : 32,
        ),
      ),
    );
  }
}
