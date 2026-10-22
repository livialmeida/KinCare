import 'package:provider/provider.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_fonts/google_fonts.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/stock/domain/stock_item.dart';
import 'package:kincare/features/stock/presentation/widgets/edit_stock_modal.dart';
import 'package:kincare/features/stock/presentation/widgets/stock_card.dart';
import 'package:kincare/features/stock/presentation/widgets/move_stock_modal.dart';
import 'package:kincare/features/stock/services/stock_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _userRole;
  bool _hasPantryAccess = false;

  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _prepareHome();

    // technical: execute device OS sync and alert popup check right after initial frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().syncDeviceOSAndCheckChange(context: context);
      }
    });
  }

  Future<void> _prepareHome() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userDoc = await _db.collection('users').doc(user.uid).get();
      final profile = userDoc.data();

      final role = profile?['role'] as String?;
      final hasAccess = profile?['hasPantryAccess'] as bool? ?? false;
      final Timestamp? accessUntilTs = profile?['pantryAccessUntil'];
      final DateTime? accessUntil = accessUntilTs?.toDate();

      final now = DateTime.now();
      final bool isAccessValid = hasAccess && accessUntil != null && accessUntil.isAfter(now);

      if (mounted) {
        setState(() {
          _userRole = role;
          _hasPantryAccess = (role == 'support') ? isAccessValid : true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic: Handle item consumption with async gap protection and elegant visual dialogs
  Future<void> _handleConsume(StockItem item) async {
    final bool isExpired = item.daysRemaining < 0;
    final stockService = StockService();

    // Disposal flow (expired items included for history auditing)
    if (isExpired) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirmar Descarte"),
          content: Text("O item \"${item.description}\" está com validade expirada. Confirmar o descarte e registro no histórico?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
              onPressed: () async {
                await stockService.processStockDisposal(item: item);
                if (dialogContext.mounted) Navigator.pop(dialogContext);

                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (successContext) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_forever, color: Color(0xFFB71C1C), size: 48),
                          const SizedBox(height: 16),
                          Text("${item.description} descartado e arquivado com sucesso.", textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
              },
              child: const Text("DESCARTAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    try {
      if (item.quantity > 1) {
        await stockService.processStockConsumption(item: item, autoReorder: false);
        return;
      }

      if (!mounted) return;

      // Step: Open confirmation dialog for last unit
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Última Unidade Consumida"),
          content: Text("Você consumiu a última unidade de \"${item.description}\". Deseja gerar uma solicitação automática de reposição?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await stockService.processStockConsumption(item: item, autoReorder: false);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text("Apenas Consumir"),
            ),
            TextButton(
              onPressed: () async {
                await stockService.processStockConsumption(item: item, autoReorder: true);
                if (dialogContext.mounted) Navigator.pop(dialogContext);

                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (successContext) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.autorenew, color: KinColors.primary, size: 48),
                          const SizedBox(height: 16),
                          Text("Solicitação de reposição registrada: ${item.description}", textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
              },
              child: const Text("Solicitar Reposição", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (errorContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Color(0xFFB71C1C), size: 48),
              SizedBox(height: 16),
              Text("Erro ao atualizar o estoque.", textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 18,
              bottom: 20,
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
            child: Column(
              children: [
                const Text(
                  'Despensa & Estoque',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 14),

                if (_hasPantryAccess && !_isLoading)
                  _buildFilterSection(),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: KinColors.primary))
                : StreamBuilder<QuerySnapshot>(
              stream: _hasPantryAccess
                  ? _db.collection('stock').orderBy('expiryDate', descending: false).snapshots()
                  : _db.collection('stock')
                  .where('authorId', isEqualTo: _auth.currentUser?.uid)
                  .orderBy('expiryDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Erro de permissão ou conexão..."));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final allDocs = snapshot.data!.docs;

                // logic: client-side filtering based on _activeFilter
                final docs = allDocs.where((doc) {
                  if (_activeFilter == 'all') return true;
                  final loc = (doc.data() as Map<String, dynamic>)['location']?.toString().toLowerCase() ?? '';
                  // matching 'fridge', 'freezer' or 'pantry'
                  return loc.contains(_activeFilter);
                }).toList();

                if (docs.isEmpty) return _buildEmptyState(isLocked: false);

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final item = StockItem(
                      id: docs[index].id,
                      description: data['description'] ?? '',
                      quantity: data['quantity'] ?? 0,
                      status: data['status'] ?? 'in_stock',
                      location: data['location'] ?? 'Fridge',
                      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
                      daysValid: data['daysValid'],
                      wasFrozen: data['wasFrozen'] ?? false,
                      thawCycles: data['thawCycles'] ?? 0,
                      thawStartedAt: data['thawStartedAt'] != null
                          ? (data['thawStartedAt'] as Timestamp).toDate()
                          : null,
                      originalExpiryDate: data['originalExpiryDate'] != null
                          ? (data['originalExpiryDate'] as Timestamp).toDate()
                          : null,
                      authorName: data['authorName'],
                      createdAt: data['createdAt'] != null
                          ? (data['createdAt'] as Timestamp).toDate()
                          : DateTime.now(),
                    );

                    return StockCard(
                      key: ValueKey(item.id),
                      item: item,
                      onConsume: () => _handleConsume(item),
                      onMove: () => showMoveStockModal(context, item),
                      // Technical Lifecycle Sync: Open the newly created isolated correction modal
                      onEdit: (selectedItem) {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => EditStockModal(item: selectedItem),
                        );
                      },
                      isManagement: _userRole == 'super_admin' || _userRole == 'admin',
                      hasRoutineAccess: _hasPantryAccess,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = [
      {'label': 'Tudo', 'key': 'all'},
      {'label': 'Geladeira', 'key': 'fridge'},
      {'label': 'Freezer', 'key': 'freezer'},
      {'label': 'Despensa', 'key': 'pantry'},
    ];

    // Technical: Visual translate to push the entire symmetrical filter block lower into the header area
    return Transform.translate(
      offset: const Offset(0, 14), // Pushes lower down to perfectly line up with the bottom curve
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        child: Row(
          // Technical: Forcing even distribution of child spacing to keep left and right outer margins identical
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: filters.map((f) {
            final isSelected = _activeFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => setState(() => _activeFilter = f['key']!),
                borderRadius: BorderRadius.circular(20),
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f['label']!,
                    style: GoogleFonts.nunito(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isLocked}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocked && _userRole == 'support' ? Icons.lock_outline : Icons.inventory_2_outlined,
              size: 44,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isLocked
                  ? "Acesso restrito à despensa. Utilize a aba de pedidos para entregas."
                  : "Nenhum item cadastrado nesta categoria.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}