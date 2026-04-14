// lib/widgets/appointment_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointmentData;
  final Color themeColor;

  const AppointmentCard({
    Key? key,
    required this.appointmentData,
    required this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely get the vet's name. It might be null if the vet was deleted.
    final vetName = appointmentData['vet']?['name'] ?? 'N/A';
    // Parse and format the date
    final date = DateTime.parse(appointmentData['date']);
    final formattedDate = DateFormat.yMMMd().add_jm().format(date); // e.g., Oct 14, 2025, 10:50 PM

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeColor.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "With Dr. $vetName",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Reason: ${appointmentData['reason']}",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}