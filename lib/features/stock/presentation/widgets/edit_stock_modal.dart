import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/core/utils/time_helper.dart';
import '../../domain/stock_item.dart';

class EditStockModal extends StatefulWidget {
  final StockItem item;

  const EditStockModal({super.key, required this.item});

  @override
  State<EditStockModal> createState() => _EditStockModalState();
}

class _EditStockModalState extends State<EditStockModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  late String _daysValid;
  late String _storageLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.item.description;
    _qtyController.text = widget.item.quantity.toString();
    _daysValid = widget.item.daysValid?.toString() ?? "90";
    _storageLocation = widget.item.location.toLowerCase();

    // Technical: Reverse-map active item constraints to select the correct UI state matrix
    _initializeStorageSelection();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  // Technical: Reverse-map active item constraints to select the correct UI state matrix
  void _initializeStorageSelection() {
    final String currentLoc = widget.item.location.toLowerCase();
    final int currentDays = widget.item.daysValid ?? 90;

    if (currentLoc == 'pantry') {
      _daysValid = "1";
    } else if (currentLoc == 'fridge') {
      _daysValid = currentDays == 3 ? "3" : "5";
    } else {
      if (currentDays == 30) {
        _daysValid = "30";
      } else if (currentDays == 60) {
        _daysValid = "60";
      } else if (currentDays == 180) {
        _daysValid = "180";
      } else {
        _daysValid = "90";
      }
    }
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

  // Logic: Mutate existing stock record enforcing dictionary and security compliance
  Future<void> _handleUpdateStock() async {
    // Security Logic: double-check 3-hour time window validity before firing mutations
    final Timestamp? itemTimestamp = widget.item.createdAt != null
      ? Timestamp.fromDate(widget.item.createdAt!)
      : null;
    final bool isWithinTime = TimeHelper.isWithinWindow(itemTimestamp);

    if (!isWithinTime) {
      if (mounted) {
        await _showTimeExpiredAlert();
        if (mounted) Navigator.pop(context);
      }
      return;
    }

    final finalName = _nameController.text.trim();
    final quantity = _qtyController.text.trim();
    final bool startingInFreezer = _storageLocation == "freezer";

    if (finalName.isEmpty || quantity.isEmpty || _daysValid.isEmpty) {
      _showError("Preencha todos os campos!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Technical: Recalculate expiration baseline from the edit mutation timestamp
      final expirationDate = DateTime.now().add(Duration(days: int.parse(_daysValid)));

      // Security Boundary: Execute strict field update payload directly against document target ID
      await FirebaseFirestore.instance.collection('stock').doc(widget.item.id).update({
        'description': finalName,
        'quantity': int.parse(quantity),
        'expiryDate': expirationDate,
        'daysValid': int.parse(_daysValid),
        'location': _storageLocation,
        'wasFrozen': startingInFreezer,
        'originalExpiryDate': startingInFreezer ? expirationDate : null,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Não foi possível salvar as alterações.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  
  // UI Logic: Warning alert dialog 
  Future<void> _showTimeExpiredAlert() async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.timer_off_outlined, color: Colors.redAccent),
                SizedBox(width: 8),
                Text(
                  "Prazo Expirado",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              "O tempo limite de 3 horas para correção deste item expirou.",
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext), 
                  child: const Text("Entendi", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic: check time window to control UI editability
    final Timestamp? itemTimestamp = widget.item.createdAt != null
      ? Timestamp.fromDate(widget.item.createdAt!)
      : null;
    final bool isWithinTime = TimeHelper.isWithinWindow(itemTimestamp);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Editar Item",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: KinColors.primary),
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
              const SizedBox(height: 20),
              _buildPrimaryButton(
                  "Salvar Alterações",
                  (!isWithinTime || _isLoading) ? () {} : _handleUpdateStock
              ),
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
}