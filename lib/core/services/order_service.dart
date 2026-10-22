import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createNewOrder({
    required User currentUser,
    required String description,
    String type = "general",
    String? targetChefId,
  }) async {
    try {
      await _db.collection('orders').add({
        'description': description,
        'status': 'pending',
        'type': 'request',
        'location': null,
        'targetChefId': targetChefId,
        'createdAt': FieldValue.serverTimestamp(),
        'creatorId': currentUser.uid,
        'creatorName': currentUser.displayName ?? "Família",
        'authorName': "",
        'authorId': "",
        'isSurprise': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // logic: accept order and assign the chef
  Future<void> acceptOrder(String orderId, User user) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);
      await orderRef.update({
        'status': 'accepted',
        'authorId': user.uid,
        'authorName': user.displayName ?? "Nome do Chef",
      });
    } catch (e) {
      rethrow;
    }
  }

  // Logic: Refactored logic from ModalNewRequest
  Future<void> createFamilyRequest({
    required String currentUserId,
    required String currentUserName,
    required String description,
    String? targetChefId,
  }) async {
    try {
      // Logic: Preserve implicit target mapping
      final String? finalTarget = (targetChefId == null || targetChefId == 'all' || targetChefId.isEmpty)
          ? null
          : targetChefId;

      await _db.collection('orders').add({
        'description': description,
        'status': 'pending',
        'type': 'request',
        'targetChefId': finalTarget,
        'createdAt': FieldValue.serverTimestamp(),
        'creatorId': currentUserId,
        'creatorName': currentUserName,
        'authorName': "",
        'authorId': "",
        'isSurprise': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Logic: Refactored logic from ModalAddVoluntary
  Future<void> createVoluntaryProxyOrder({
    required String currentUserId,
    required String currentUserName,
    required String description,
    required bool isChefInitiative,
    required bool isSurprise,
    String? proxyCreatorId,
    String? proxyCreatorName,
  }) async {
    try {
      final Map<String, dynamic> orderData = {
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': currentUserId,
        'authorName': currentUserName,
        'location': null,
        'isSurprise': isChefInitiative ? isSurprise : false,
      };

      if (isChefInitiative) {
        orderData.addAll({
          'status': 'preparing',
          'type': 'proactive',
          'creatorId': currentUserId,
          'creatorName': currentUserName,
        });
      } else {
        orderData.addAll({
          'status': 'pending',
          'type': 'request',
          'creatorId': proxyCreatorId ?? "proxy_member",
          'creatorName': proxyCreatorName ?? "Membro da Família",
          'proxyCreatedById': currentUserId,
          'proxyCreatedByName': currentUserName,
          'source': 'proxy_manual_entry',
        });
      }

      await _db.collection('orders').add(orderData);
    } catch (e) {
      rethrow;
    }
  }

  // Logic: Automatic reorder when a stock item hits zero quantity
  Future<void> createAutomaticReorder({
    required User currentUser,
    required String description,
  }) async {
    try {
      await _db.collection('orders').add({
        'description': description,
        'status': 'pending',
        'type': 'request',
        'location': null,
        'targetChefId': null, // Open to any available chef
        'createdAt': FieldValue.serverTimestamp(),
        'creatorId': currentUser.uid,
        'creatorName': currentUser.displayName ?? "Família",
        'authorName': "",
        'authorId': "",
        'isSurprise': false,
        'isReorder': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Security Logic: update only specific fields to protect data integrity - edit modal
  Future<void> updateOrderDescription({
    required String orderId,
    required String newDescription,
  }) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);
      await orderRef.update({
        'description': newDescription,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOrder({required String orderId}) async {
    try {
      await _db.collection('orders').doc(orderId).delete();
    } catch (e) {
      rethrow;
    }
  }
}