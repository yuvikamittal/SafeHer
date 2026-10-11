import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

extension _EmptyFallback on String {
  String ifEmptyThen(String fallback) => trim().isEmpty ? fallback : this;
}

enum AlertType { critical, safety, info }

/// A safety alert shown in the Alerts tab.
class SafetyAlert {
  final AlertType type;
  final String title;
  final String body;
  final String time;
  final bool isUnread;
  final IconData icon;

  const SafetyAlert({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.icon,
  });

  /// Builds a SafetyAlert from a Firestore `sos_alerts` document.
  factory SafetyAlert.fromSos(Map<String, dynamic> d) {
    final status = (d['status'] as String?) ?? 'active';
    final message = (d['message'] as String?)?.trim();
    final label = (d['location'] as Map<String, dynamic>?)?['label'] as String?;
    final ts = d['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : null;

    final isActive = status == 'active';
    return SafetyAlert(
      type: isActive ? AlertType.critical : AlertType.safety,
      title: switch (status) {
        'active' => 'SOS alert active',
        'resolved' => 'SOS alert resolved',
        'cancelled' => 'SOS alert cancelled',
        _ => 'SOS alert',
      },
      body: [
        if (message != null && message.isNotEmpty) message,
        if (label != null && label.isNotEmpty) 'Location: $label',
      ].join(' · ').ifEmptyThen('Emergency SOS was dispatched to your contacts.'),
      time: _timeAgo(createdAt),
      isUnread: isActive,
      icon: isActive
          ? Icons.warning_amber_rounded
          : Icons.check_circle_outline_rounded,
    );
  }

  static String _timeAgo(DateTime? t) {
    if (t == null) return 'just now';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} hr ago';
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays} days ago';
  }
}

/// A general notification shown in the Notifications tab.
class AppNotification {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color color;

  const AppNotification({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
  });
}
