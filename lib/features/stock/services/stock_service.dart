import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kincare/core/services/order_service.dart';
import 'package:kincare/features/stock/domain/stock_item.dart';

class StockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Technical: Move an item out of active stock and safely write it to the historical archive
  Future<void> archiveHistory({
    required StockItem item,
    required String targetStatus,
    required int quantityArchived,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final profile = userDoc.data();
      final String executorName = profile?['name'] ?? "Usuário";

      // Technical Serialization Guard: Using Timestamp.now() instead of serverTimestamp to prevent race condition crashes
      await _db.collection('food_history').add({
        "itemId": item.id,
        "description": item.description,
        "quantity": quantityArchived,
        "status": targetStatus,
        "location": item.location,
        "authorName": item.authorName ?? "Desconhecido",
        "authorId": item.authorId ?? "",
        "creatorName": executorName,
        "creatorId": user.uid,
        "createdAt": Timestamp.now(), // Safe chronological stamp
      });
    } catch (e) {
      // Security: Catch background writes so permission or structural errors don't crash core operations
      debugPrint("Background History Error: $e");
    }
  }

  // Logic: Centralized core routine executing item consumption
  Future<void> processStockConsumption({
    required StockItem item,
    required bool autoReorder,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Step 1: Write to history first safely caught
    await archiveHistory(item: item, targetStatus: "consumption", quantityArchived: 1);

    // Step 2: Perform the structural mutation on active stock
    if (item.quantity > 1) {
      await _db.collection('stock').doc(item.id).update({
        'quantity': item.quantity - 1,
      });
    } else {
      await _db.collection('stock').doc(item.id).delete();

      if (autoReorder) {
        await OrderService().createAutomaticReorder(
          currentUser: user,
          description: item.description,
        );
      }
    }
  }

  // Logic: Handle technical expiry disposal flow
  Future<void> processStockDisposal({required StockItem item}) async {
    await archiveHistory(item: item, targetStatus: "expired", quantityArchived: item.quantity);
    await _db.collection('stock').doc(item.id).delete();
  }
}