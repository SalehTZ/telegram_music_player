import 'package:flutter/foundation.dart';

class Artist {
  final String name;
  final Uint8List? image;
  final int? rating; // Rating out of 5

  Artist({
    required this.name,
    this.image,
    this.rating,
  });
}
