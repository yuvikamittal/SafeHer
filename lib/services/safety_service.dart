import 'package:flutter/material.dart';

import '../models/safety_alert.dart';

/// Mock safety-data provider for alerts/notifications (unchanged).
/// Nearby places and routes now come from PlacesService / DirectionsService.
class SafetyService {
  SafetyService._();
  static final SafetyService instance = SafetyService._();

  List<SafetyAlert> recentAlerts() => const [
    SafetyAlert(
      type: AlertType.critical,
      title: 'Unsafe area detected nearby',
      body:
          'High-risk zone flagged 0.8 km from your current location. Avoid Sector 14 lane after 9 PM.',
      time: '2 min ago',
      isUnread: true,
      icon: Icons.warning_amber_rounded,
    ),
    SafetyAlert(
      type: AlertType.safety,
      title: 'Safe arrival confirmed',
      body: 'Your trusted contact Priya has confirmed she reached home safely.',
      time: '14 min ago',
      isUnread: true,
      icon: Icons.check_circle_outline_rounded,
    ),
    SafetyAlert(
      type: AlertType.info,
      title: 'Route safety updated',
      body:
          'Your saved route to Office has a new safety score of 92%. Two new CCTV cameras installed.',
      time: '1 hr ago',
      isUnread: true,
      icon: Icons.info_outline_rounded,
    ),
    SafetyAlert(
      type: AlertType.safety,
      title: 'Trusted contact added',
      body: 'Meena has accepted your safety circle request.',
      time: '3 hr ago',
      isUnread: false,
      icon: Icons.person_add_alt_1_rounded,
    ),
    SafetyAlert(
      type: AlertType.info,
      title: 'Night mode activated',
      body:
          'Enhanced safety monitoring is now active. Your location is being tracked every 5 minutes.',
      time: 'Yesterday',
      isUnread: false,
      icon: Icons.nightlight_round,
    ),
    SafetyAlert(
      type: AlertType.critical,
      title: 'SOS alert sent',
      body:
          'Your emergency SOS was sent to 3 contacts and local authorities at 11:52 PM.',
      time: 'Yesterday',
      isUnread: false,
      icon: Icons.sos_rounded,
    ),
  ];

  List<AppNotification> notifications() => const [
    AppNotification(
      icon: Icons.share_location_rounded,
      title: 'Live location active',
      body: 'Sharing location with Priya and Meena.',
      time: 'Now',
      color: Color(0xFFFF6EBF),
    ),
    AppNotification(
      icon: Icons.nightlight_round,
      title: 'Night mode engaged',
      body:
          "Extra monitoring enabled. Contacts will be alerted if you don't check in by midnight.",
      time: '8:00 PM',
      color: Color(0xFF60A5FA),
    ),
    AppNotification(
      icon: Icons.route_rounded,
      title: 'Route saved',
      body: 'Your route to College has been saved and safety-rated.',
      time: 'Yesterday',
      color: Color(0xFF34D399),
    ),
    AppNotification(
      icon: Icons.people_alt_rounded,
      title: 'Safety circle update',
      body: 'You now have 3 trusted contacts in your safety circle.',
      time: 'Yesterday',
      color: Color(0xFFFBBF24),
    ),
    AppNotification(
      icon: Icons.system_update_alt_rounded,
      title: 'App updated',
      body: 'SafeHer v2.1 is live with improved route analysis and faster SOS.',
      time: '2 days ago',
      color: Colors.white54,
    ),
  ];
}
