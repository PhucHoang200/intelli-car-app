import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/services/home_load_trace.dart';

/// Observe the existing image stream. No prefetch or extra HTTP request.
class HomeMeasuredImage extends StatelessWidget {
  const HomeMeasuredImage({super.key, required this.image, this.trace});

  final ImageProvider image;
  final HomeLoadTrace? trace;

  @override
  Widget build(BuildContext context) {
    trace?.mark('first_thumbnail_widget_built');
    return Image(
      image: image,
      width: double.infinity,
      height: 70,
      fit: BoxFit.cover,
      frameBuilder: trace == null
          ? null
          : (context, child, frame, synchronous) {
              if (frame != null && !trace!.isClosed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    trace!.thumbnailReady(synchronous: synchronous);
                  }
                });
              }
              return child;
            },
      // Preserve Flutter's default image error handling. A failed image remains
      // pending in the trace and is reported as timeout rather than ready.
    );
  }
}
