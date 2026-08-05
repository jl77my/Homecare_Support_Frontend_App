import 'package:flutter/material.dart';

class PatientSelectorBar extends StatelessWidget {
  /// List of assigned elderly maps containing 'elderlyId' and 'name'
  final List<Map<String, String>> assignedSeniors;
  
  /// Currently active elderly GUID selected by the caregiver
  final String selectedElderlyId;
  
  /// Callback triggered when caregiver selects a different senior
  final ValueChanged<String> onElderlySelected;
  
  /// Callback triggered when tapping the '+' icon to pair a new senior
  final VoidCallback onPairNewElderly;

  const PatientSelectorBar({
    super.key,
    required this.assignedSeniors,
    required this.selectedElderlyId,
    required this.onElderlySelected,
    required this.onPairNewElderly,
  });

  @override
  Widget build(BuildContext context) {
    // Determine current dropdown value safely
    final activeValue = selectedElderlyId.isEmpty && assignedSeniors.isNotEmpty
        ? assignedSeniors.first['elderlyId']
        : selectedElderlyId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search_outlined, color: Color(0xFF60A5FA), size: 20),
          const SizedBox(width: 8),
          const Text(
            'ACTIVE SENIOR:',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: assignedSeniors.any((s) => s['elderlyId'] == activeValue)
                    ? activeValue
                    : null,
                dropdownColor: const Color(0xFF1E293B),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                hint: const Text(
                  'Select Senior Patient',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                items: assignedSeniors.map((senior) {
                  return DropdownMenuItem<String>(
                    value: senior['elderlyId'],
                    child: Text(
                      senior['name'] ?? 'Senior User',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newElderlyId) {
                  if (newElderlyId != null) {
                    onElderlySelected(newElderlyId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 22),
            onPressed: onPairNewElderly,
            tooltip: 'Pair New Senior Patient',
          ),
        ],
      ),
    );
  }
}