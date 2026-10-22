import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kincare/core/theme/app_theme.dart';
import 'package:kincare/features/auth/data/providers/auth_provider.dart';

class FoodHistoryScreen extends StatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _selectedDays = 7; // Logic: Query boundary (7, 15, 30, or 60 days)

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.userProfile;

    // Security: Structural access guard ensuring only authorized roles view consumption logs
    final bool hasAccess = profile?['role'] == 'admin';

    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text("Histórico de Consumo")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Você não possui permissão para acessar este histórico.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: KinColors.text),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: KinColors.text),
        title: Text(
          "Histórico de Consumo",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: KinColors.text,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _buildHistoryStream(),
          ),
        ],
      ),
    );
  }

  // UI/UX Component: Segmented period filter to control query depth
  Widget _buildPeriodSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton("7 Dias", 7),
          const SizedBox(width: 4),
          _buildFilterButton("15 Dias", 15),
          const SizedBox(width: 4),
          _buildFilterButton("30 Dias", 30),
          const SizedBox(width: 4),
          _buildFilterButton("60 Dias", 60),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, int days) {
    final bool isSelected = _selectedDays == days;
    return InkWell(
      onTap: () => setState(() => _selectedDays = days),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KinColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? KinColors.primary : Colors.grey,
          ),
        ),
      ),
    );
  }

  // Data Pipeline Logic: Real-time query to the 'food_history' collection with time boundary calculations
  Widget _buildHistoryStream() {
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: _selectedDays));

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('food_history')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Erro de conexão ou permissão ao carregar o histórico."),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: KinColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Nenhum registro encontrado nos últimos $_selectedDays dias.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            // Logic: Distinguish status destinations matching dictionary fields
            final String status = data["status"] ?? "consumption";
            final bool isConsumption = status == "consumption";

            final String description = data["description"] ?? "Item sem descrição";
            final int quantity = data["quantity"] ?? 0;
            final String executorName = data["creatorName"] ?? "Membro da Casa";

            // Technical: Clean formatting for Firestore server timestamps
            final Timestamp? ts = data["createdAt"] as Timestamp?;
            String dateStr = "";
            if (ts != null) {
              final date = ts.toDate();
              dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // UI/UX Component: Strict color and icon separation to quickly track waste vs ingestion
                  CircleAvatar(
                    backgroundColor: isConsumption
                        ? Colors.green.withValues(alpha: 0.1)
                        : const Color(0xFFB71C1C).withValues(alpha: 0.1),
                    child: Icon(
                      isConsumption ? Icons.restaurant_outlined : Icons.delete_outline,
                      color: isConsumption ? Colors.green : const Color(0xFFB71C1C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: KinColors.text,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isConsumption
                              ? "Consumido: $quantity un"
                              : "Descartado: $quantity un",
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isConsumption ? Colors.green : const Color(0xFFB71C1C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Registrado por: $executorName",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}