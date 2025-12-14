import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class SelectionActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const SelectionActionBar({
    required this.count,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Row(
            children: [
              DefaultText(
                "$count selected",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, color: Colors.black),
                label: const DefaultText("Cancel"),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                label: Text(
                  "Delete ($count)",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
