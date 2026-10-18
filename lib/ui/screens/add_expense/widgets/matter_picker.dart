import 'package:flutter/material.dart';
import '../../../../data/models/client_matter.dart';

class MatterPicker extends StatelessWidget {
  final List<ClientMatter> matters;
  final int? selectedMatterId;
  final ValueChanged<int?> onMatterSelected;
  final VoidCallback onQuickAddMatter;

  const MatterPicker({
    super.key,
    required this.matters,
    required this.selectedMatterId,
    required this.onMatterSelected,
    required this.onQuickAddMatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          value: selectedMatterId,
          decoration: InputDecoration(
            labelText: 'Client Matter / Case',
            hintText: 'Select case',
            prefixIcon: const Icon(Icons.business_center_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          isExpanded: true,
          items: matters.map((m) {
            final forumSuffix = (m.forum != null && m.forum!.isNotEmpty) ? ' (${m.forum})' : '';
            return DropdownMenuItem<int>(
              value: m.id,
              child: Text(
                '${m.caseTitle}$forumSuffix',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onMatterSelected,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onQuickAddMatter,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add New Matter', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }
}
