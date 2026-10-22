import 'package:flutter/material.dart';
import 'package:kincare/core/theme/app_theme.dart';

class StockItem {
  final String id;
  final String description;  // Source of Truth: Item/Dish name
  final int quantity;       // Unit count
  final String status;      // pending, preparing, accepted, in_stock
  final String location;    // Freezer, Fridge, Pantry (Strictly English)
  final DateTime expiryDate; // Timestamp
  final int? daysValid;     // Technical shelf life (Number)

  // Collaborative Fields
  final String? authorName; // The Chef's name
  final String? authorId;   // The Chef's UID
  final String? creatorName; // Requester's name
  final String? creatorId;   // Requester's UID
  final DateTime? createdAt; // Registration timestamp
  final bool wasFrozen;
  final int thawCycles;
  final DateTime? thawStartedAt;
  final DateTime? originalExpiryDate;

  StockItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.status,
    required this.location,
    required this.expiryDate,
    required this.wasFrozen,
    required this.thawCycles,
    this.daysValid,
    this.authorName,
    this.authorId,
    this.creatorName,
    this.creatorId,
    this.createdAt,
    this.thawStartedAt,
    this.originalExpiryDate,
  });

  // Technical Logic: Internal color mapping based on location string
  Color get ambientColor {
    switch (location.toLowerCase()) {
      case 'freezer':
        return KinColors.freezer;
      case 'fridge':
        return KinColors.fridge;
      case 'pantry':
        return KinColors.pantry; // Buttercream Yellow
      default:
        return KinColors.secondary;
    }
  }

  // Logic: Calculate remaining shelf life days
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }
}