import 'package:flutter/material.dart';

/// A nearby place that can provide help (police, hospital, safe zone, shelter).
class HelpPlace {
  final String name;
  final String category;
  final String distance;
  final String eta;
  final String address;
  final String? phone;
  final bool isOpen;
  final IconData icon;
  final Color color;
  final double? rating;
  final double lat;
  final double lng;
  final String? placeId;

  const HelpPlace({
    required this.name,
    required this.category,
    required this.distance,
    required this.eta,
    required this.address,
    required this.phone,
    required this.isOpen,
    required this.icon,
    required this.color,
    required this.rating,
    this.lat = 0,
    this.lng = 0,
    this.placeId,
  });
}
