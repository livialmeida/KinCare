import 'package:cloud_firestore/cloud_firestore.dart';

class TimeHelper {
  // Rule: Standard edit/action window is strictly 2 hours (120 min)
  static const int editWindowMinutes = 120;
  static const int editWindowSeconds = editWindowMinutes * 60;

  // Logic: Check if a timestamp is still within the allowed operational window
  static bool isWithinWindow(Timestamp? createdAtTimestamp) {
    if (createdAtTimestamp == null) return false;

    final DateTime createdAt = createdAtTimestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdAt);

    return difference.inMinutes < editWindowMinutes;
  }

  // Logic: Calculate exact remaining seconds until expiration (useful for UI Timers)
  static int getRemainingSeconds(Timestamp? createdAtTimestamp) {
    if (createdAtTimestamp == null) return 0;

    final DateTime createdAt = createdAtTimestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdAt);

    final int remaining = editWindowSeconds - difference.inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}