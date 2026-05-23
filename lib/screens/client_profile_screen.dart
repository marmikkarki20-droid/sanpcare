import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/care_scope.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/info_widgets.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final client = controller.client!;

    return AppScaffold(
      title: 'Client profile',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        child: Text(
                          client.fullName.characters.first,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${client.roomNumber} • ${client.address}',
                              style: const TextStyle(color: Color(0xFF536E7A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'Care needs',
            subtitle: client.careNeeds,
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.accessible_forward_outlined,
            title: 'Mobility support',
            subtitle: client.mobilityStatus,
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.record_voice_over_outlined,
            title: 'Communication needs',
            subtitle: client.communicationNeeds,
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.priority_high_outlined,
            title: 'Risk alerts',
            subtitle: client.riskNotes,
            badge: const StatusBadge(label: 'Risk', color: Color(0xFFC43D32)),
          ),
          const SizedBox(height: 10),
          InfoCard(
            icon: Icons.contact_phone_outlined,
            title: 'Emergency contact',
            subtitle: client.emergencyContact,
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Recent progress notes'),
          const SizedBox(height: 10),
          if (controller.progressNotes.isEmpty)
            const EmptyState(
              icon: Icons.notes_outlined,
              message: 'No progress notes have been recorded.',
            )
          else
            ...controller.progressNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InfoCard(
                  icon: Icons.notes_outlined,
                  title: note.shiftSummary,
                  subtitle:
                      '${note.activities}\n${DateFormat('d MMM, h:mm a').format(note.createdAt)}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
