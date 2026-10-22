import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class DeliveryModal extends StatefulWidget {
  final Map<String, dynamic> order;
  final String orderId;

  const DeliveryModal({super.key, required this.order, required this.orderId});

  @override
  State<DeliveryModal> createState() => _DeliveryModalState();
}

class _DeliveryModalState extends State<DeliveryModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");

  String _daysValid = "90";
  // Technical: Internal state in English per Dictionary standard
  String _storageLocation = "freezer";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.order['description'] ?? "";

    // Technical: Normalize incoming location data to match internal keys
    final incomingLoc = widget.order['location']?.toString().toLowerCase() ?? '';
    if (incomingLoc.contains('geladeira') || incomingLoc.contains('fridge')) {
      _handleStorageSelect('fridge_std');
    } else if (incomingLoc.contains('armário') || incomingLoc.contains('pantry') || incomingLoc.contains('despensa')) {
      _handleStorageSelect('ambient_std');
    } else {
      _handleStorageSelect('freezer_std');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _handleStorageSelect(String type) {
    setState(() {
      switch (type) {
        case 'ambient_std':
          _daysValid = "1";
          _storageLocation = "pantry";
          break;
        case 'fridge_sensitive':
          _daysValid = "3";
          _storageLocation = "fridge";
          break;
        case 'fridge_std':
          _daysValid = "5";
          _storageLocation = "fridge";
          break;
        case 'freezer_sensitive':
          _daysValid = "30";
          _storageLocation = "freezer";
          break;
        case 'freezer_bakery':
          _daysValid = "60";
          _storageLocation = "freezer";
          break;
        case 'freezer_std':
          _daysValid = "90";
          _storageLocation = "freezer";
          break;
        case 'freezer_raw':
          _daysValid = "180";
          _storageLocation = "freezer";
          break;
        default:
          _daysValid = "90";
          _storageLocation = "freezer";
      }
    });
  }

  Future<void> _handleMarkAsReady() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': 'accepted'});

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Não foi possível atualizar o status.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFinalDelivery() async {
    final finalName = _nameController.text.trim();
    final quantity = _qtyController.text.trim();
    final bool startingInFreezer = _storageLocation == "freezer";

    if (finalName.isEmpty || quantity.isEmpty || _daysValid.isEmpty) {
      _showError("Preencha todos os campos obrigatórios.");
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      // 1. Technical: Recover data from the first stage
      final Timestamp? readyAtTimestamp = widget.order['readyAt'] as Timestamp?;
      final DateTime readyAt = readyAtTimestamp?.toDate() ?? DateTime.now();
      final DateTime now = DateTime.now();

      // 2. Logic: Calculate exact days elapsed during the waiting period
      final int daysWaiting = now.difference(readyAt).inDays;

      // 3. Technical: Read the INITIAL safety baseline to check if it spoiled BEFORE delivery
      final int initialDaysValid = widget.order['initialDaysValid'] ?? 90;
      if (daysWaiting >= initialDaysValid) {
        _showError("Aviso: O item ultrapassou o período seguro de espera na origem.");
        setState(() => _isLoading = false);
        return;
      }

      // 4. Security: Compute remaining shelf life based on CURRENT selection
      final int selectedDaysValid = int.parse(_daysValid);
      final int remainingDays = selectedDaysValid - daysWaiting;

      // Guard: Double check to ensure edge cases don't produce sub-zero life ranges
      final int finalDaysValid = remainingDays > 0 ? remainingDays : 1;
      final expirationDate = now.add(Duration(days: finalDaysValid));

      // 5. Database Writing (Strictly English mapping)
      await FirebaseFirestore.instance.collection('stock').add({
        'description': finalName,
        'quantity': int.parse(quantity),
        'expiryDate': expirationDate,
        'daysValid': finalDaysValid,
        'location': _storageLocation,
        'status': 'in_stock',
        'wasFrozen': startingInFreezer,
        'originalExpiryDate': startingInFreezer ? expirationDate : null,
        'createdAt': FieldValue.serverTimestamp(),
        'authorName': auth.userProfile?['name'] ?? "Membro Responsável",
        'authorId': widget.order['authorId'],
        'creatorName': widget.order['creatorName'],
        'creatorId': widget.order['creatorId'],
      });

      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).delete();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Não foi possível registrar o item no estoque.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status']?.toString().toLowerCase() ?? '';
    final bool isPending = status == 'pending';

    if (isPending) {
      final bool hasSelectedLocation = _storageLocation.isNotEmpty;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Preparo Concluído",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KinColors.primary),
                ),
              ),
              const SizedBox(height: 15),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                  children: [
                    const TextSpan(text: "O item "),
                    TextSpan(
                      text: "${_nameController.text} ",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const TextSpan(text: "está finalizado. Onde ele ficará armazenado até o consumo ou entrega?"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickStorageBtn(
                      icon: Icons.inventory_2_outlined,
                      label: "Despensa",
                      isSelected: _storageLocation == "pantry",
                      onTap: () => setState(() {
                        _storageLocation = "pantry";
                        _daysValid = "1";
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickStorageBtn(
                      icon: Icons.kitchen_outlined,
                      label: "Geladeira",
                      isSelected: _storageLocation == "fridge",
                      onTap: () => setState(() {
                        _storageLocation = "fridge";
                        _daysValid = "5";
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickStorageBtn(
                      icon: Icons.ac_unit,
                      label: "Freezer",
                      isSelected: _storageLocation == "freezer",
                      onTap: () => setState(() {
                        _storageLocation = "freezer";
                        _daysValid = "90";
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              _buildPrimaryButton(
                "Confirmar Armazenamento",
                hasSelectedLocation ? _handleMarkAsReady : () => _showError("Selecione onde o item foi guardado."),
              ),
              _buildCancelButton("Voltar", () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Entregar ao Estoque",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KinColors.primary),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _getOrderStatusText(status),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 15),

              _buildLabel("Despensa (Temperatura Ambiente):"),
              Row(
                children: [
                  _buildStorageBtn("Despensa\n(24h)", 'ambient_std', _storageLocation == "pantry"),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 15),

              _buildLabel("Geladeira:"),
              Row(
                children: [
                  _buildStorageBtn("Delicado\n(3 dias)", 'fridge_sensitive', _daysValid == "3" && _storageLocation == "fridge"),
                  const SizedBox(width: 8),
                  _buildStorageBtn("Padrão\n(5 dias)", 'fridge_std', _daysValid == "5" && _storageLocation == "fridge"),
                ],
              ),
              const SizedBox(height: 15),

              _buildLabel("Freezer:"),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildStorageBtn("Peixe/Molhos\n(30d)", 'freezer_sensitive', _daysValid == "30" && _storageLocation == "freezer", isSmall: true),
                  _buildStorageBtn("Pão/Massa\n(60d)", 'freezer_bakery', _daysValid == "60" && _storageLocation == "freezer", isSmall: true),
                  _buildStorageBtn("Cozidos\n(90d)", 'freezer_std', _daysValid == "90" && _storageLocation == "freezer", isSmall: true),
                  _buildStorageBtn("Cru/Vegetais\n(180d)", 'freezer_raw', _daysValid == "180" && _storageLocation == "freezer", isSmall: true),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel("Informações do Item:"),
              TextField(
                controller: _nameController,
                decoration: AppTheme.inputDecoration(hint: "Nome do prato ou item", context: context),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: AppTheme.inputDecoration(hint: "Qtd", context: context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(
                        "Validade: $_daysValid dias",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF555555), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildPrimaryButton("Confirmar Entrada", _handleFinalDelivery),
              _buildCancelButton("Cancelar", () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF444444))),
    );
  }

  Widget _buildQuickStorageBtn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? KinColors.primary : const Color(0xFFDDDDDD),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? KinColors.primary : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? KinColors.primary : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBtn(String label, String type, bool isActive, {bool isSmall = false}) {
    return GestureDetector(
      onTap: () => _handleStorageSelect(type),
      child: Container(
        height: 55,
        width: isSmall ? (MediaQuery.of(context).size.width * 0.20) : null,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? KinColors.primary : const Color(0xFFDDDDDD), width: isActive ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? KinColors.primary : const Color(0xFF666666),
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 10 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: KinColors.primary,
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildCancelButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.w500, fontSize: 14)),
      ),
    );
  }

  String _getOrderStatusText(String status) {
    if (status == 'accepted' || status == 'preparing') return "Item: ${_nameController.text}\nStatus: Em preparo";
    return "Item: ${_nameController.text}\nStatus: Aguardando ação";
  }
}