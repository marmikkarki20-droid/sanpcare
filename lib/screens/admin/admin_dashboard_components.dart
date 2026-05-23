import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/info_widgets.dart';

const adminNavy = Color(0xFF12313D);
const adminMuted = Color(0xFF607783);
const adminLine = Color(0xFFDCE8EC);

class AdminDashboardHeader extends StatelessWidget {
  const AdminDashboardHeader({
    super.key,
    required this.activeStaff,
    required this.actionRequired,
    required this.incidents,
    required this.hazards,
  });

  final int activeStaff;
  final int actionRequired;
  final int incidents;
  final int hazards;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HeaderMetric(
        label: 'Staff on shift',
        value: '$activeStaff',
        icon: Icons.groups_2_outlined,
        color: const Color(0xFF1B9B73),
      ),
      _HeaderMetric(
        label: 'Open incidents',
        value: '$incidents',
        icon: Icons.report_problem_outlined,
        color: const Color(0xFFC43D32),
      ),
      _HeaderMetric(
        label: 'Hazards',
        value: '$hazards',
        icon: Icons.health_and_safety_outlined,
        color: const Color(0xFFE08A1E),
      ),
      _HeaderMetric(
        label: 'Follow-ups',
        value: '$actionRequired',
        icon: Icons.flag_outlined,
        color: actionRequired > 0
            ? const Color(0xFFC43D32)
            : const Color(0xFF327A60),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12313D), Color(0xFF0E6874)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10102B38),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tiles
                    .map((tile) => SizedBox(width: width, child: tile))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: adminNavy,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPriorityPanel extends StatelessWidget {
  const AdminPriorityPanel({
    super.key,
    required this.incidents,
    required this.hazards,
    required this.actionRequired,
    required this.activeStaff,
    required this.onCreateStaff,
    required this.onAssignShift,
    required this.onIncidents,
    required this.onHazards,
    required this.onActionRequired,
  });

  final int incidents;
  final int hazards;
  final int actionRequired;
  final int activeStaff;
  final VoidCallback onCreateStaff;
  final VoidCallback onAssignShift;
  final VoidCallback onIncidents;
  final VoidCallback onHazards;
  final VoidCallback onActionRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102B38),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority queue',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Current operational items that need coordinator attention.',
              style: TextStyle(color: adminMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _PriorityRow(
              icon: Icons.report_problem_outlined,
              title: 'Incident review',
              value: '$incidents',
              color: const Color(0xFFC43D32),
              onTap: onIncidents,
            ),
            _PriorityRow(
              icon: Icons.flag_outlined,
              title: 'Action required',
              value: '$actionRequired',
              color: const Color(0xFFD37A18),
              onTap: onActionRequired,
            ),
            _PriorityRow(
              icon: Icons.health_and_safety_outlined,
              title: 'Hazard records',
              value: '$hazards',
              color: const Color(0xFF087C89),
              onTap: onHazards,
            ),
            _PriorityRow(
              icon: Icons.verified_user_outlined,
              title: 'Staff checked in',
              value: '$activeStaff',
              color: const Color(0xFF1B9B73),
              onTap: onAssignShift,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAssignShift,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Roster'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreateStaff,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Staff'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: adminNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusBadge(label: value, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminWorkspaceCard extends StatelessWidget {
  const AdminWorkspaceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminLine),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: adminNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: adminMuted,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8AA0A8)),
            ],
          ),
        ),
      ),
    );
  }
}
