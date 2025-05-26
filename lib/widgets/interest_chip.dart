import 'package:flutter/material.dart';
import '../models/interest.dart';

class InterestChip extends StatelessWidget {
  final Interest interest;
  final bool isSelected;
  final VoidCallback onTap;

  const InterestChip({
    required this.interest,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(interest.name),
        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[700],
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
