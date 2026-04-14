// lib/widgets/pet_card.dart

import 'package:flutter/material.dart';

class PetCard extends StatelessWidget {
  final String name;
  final String breed;
  final int age;
  final Color themeColor;

  const PetCard({
    Key? key,
    required this.name,
    required this.breed,
    required this.age,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeColor.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Pet Icon
            CircleAvatar(
              radius: 30,
              backgroundColor: themeColor,
              child: const Icon(Icons.pets, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            // Pet Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$breed, $age year(s) old",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // "View" Icon
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}