import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

// Technical: Standardizing Modals Imports
import '../widgets/delivery_modal.dart';
import '../widgets/modal_add_voluntary.dart';
import '../widgets/modal_new_request.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Logic: Triggering DeliveryModal safely ensuring mounting state validation
  void _handleCheckOrder(Map<String, dynamic> order, String orderId) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => DeliveryModal(
        order: order,
        orderId: orderId,
      ),
    );
  }

  // Technical Helper: Mirrors the fallback logic (description||item, creatorName||name)
  void _prepareData(Map<String, dynamic> data, String id) {
    data['id'] = id;

    // Logic: description || item || "Sem descrição"
    final rawDesc = data['description'] ?? data['item'] ?? "Sem descrição";
    data['displayTitle'] = data['isSurprise'] == true ? "[Surpresa] $rawDesc" : rawDesc;

    // Logic: creatorName || name || requesterName
    data['displayCreator'] = data['creatorName'] ?? data['name'] ?? data['requesterName'] ?? "Membro";

    // Logic: authorName || chef || chefName
    data['displayAuthor'] = data['authorName'] ?? data['chef'] ?? data['chefName'] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = auth.userProfile;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Guard: Waiting for Auth Profile to ensure filters work correctly
    if (user == null || profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: KinColors.primary)));
    }

    final String role = profile['role'] ?? 'support';
    final bool isAdmin = role == 'admin';
    final bool isSupport = role == 'support';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 35,
            ),
            decoration: const BoxDecoration(
              color: KinColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                Text(
                  "Solicitações & Pedidos",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 5),
                Text(
                  "Fila de Preparo",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final List<Map<String, dynamic>> filteredItems = [];
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Technical: (creatorId OR createdBy)
                  final bool isOwner = (data['creatorId'] ?? data['createdBy']) == user.uid;

                  bool shouldShowToUser = true;
                  if (data['isSurprise'] == true) {
                    shouldShowToUser = isSupport || isOwner;
                  }

                  // Technical: Target verification logic
                  final bool isTargetedToMe = data['targetChefId'] == null ||
                      data['targetChefId'] == "" ||
                      data['targetChefId'] == 'all' ||
                      data['targetChefId'] == user.uid ||
                      data['targetChefId'] == role;

                  if (shouldShowToUser && (isOwner || isTargetedToMe)) {
                    _prepareData(data, doc.id);
                    filteredItems.add(data);
                  }
                }

                if (filteredItems.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 100),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final orderItem = filteredItems[index];
                    return OrderCard(
                      key: ValueKey(orderItem['id']),
                      item: orderItem,
                      currentUid: user.uid,
                      currentName: profile['name'],
                      isManagement: isAdmin,
                      onCheck: () => _handleCheckOrder(orderItem, orderItem['id']),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // FAB: Logical visibility based on Role
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 10),
        child: FloatingActionButton(
          backgroundColor: KinColors.primary,
          onPressed: () {
            if (isSupport) {
              showDialog(context: context, builder: (_) => const ModalAddVoluntary());
            } else if (isAdmin) {
              showDialog(context: context, builder: (_) => const ModalNewRequest());
            }
          },
          child: Icon(isAdmin ? Icons.add_comment_outlined : Icons.restaurant_outlined, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma solicitação pendente",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          const Text(
            "Todas as refeições foram preparadas ou entregues.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}