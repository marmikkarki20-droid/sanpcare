import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/care_models.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF536E7A),
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 8), badge!],
            ],
          ),
        ),
      ),
    );
  }
}

class ReportList extends StatelessWidget {
  const ReportList({
    super.key,
    required this.reports,
    required this.emptyMessage,
    this.onTap,
    this.embedded = false,
  });

  final List<ReportSummary> reports;
  final String emptyMessage;
  final ValueChanged<ReportSummary>? onTap;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      if (embedded) {
        return EmptyState(
          icon: Icons.folder_copy_outlined,
          message: emptyMessage,
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(icon: Icons.folder_copy_outlined, message: emptyMessage),
        ],
      );
    }

    return ListView.separated(
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        return InfoCard(
          icon: iconForReport(report.collection),
          title: report.title,
          subtitle: [
            if (report.staffName != null) 'Staff: ${report.staffName}',
            if (report.clientName != null) 'Client: ${report.clientName}',
            if (report.subtitle.isNotEmpty) report.subtitle,
            DateFormat('d MMM, h:mm a').format(report.createdAt),
          ].join('\n'),
          badge: StatusBadge(
            label: report.status.label,
            color: report.status.color,
          ),
          onTap: onTap == null ? null : () => onTap!(report),
        );
      },
    );
  }
}

IconData iconForReport(String collection) {
  return switch (collection) {
    'incidentReports' => Icons.report_problem_outlined,
    'hazardReports' => Icons.warning_amber_outlined,
    'behaviourCharts' => Icons.psychology_alt_outlined,
    _ => Icons.notes_outlined,
  };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 30, color: const Color(0xFF6F8791)),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF536E7A)),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class MetricLine extends StatelessWidget {
  const MetricLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Color(0xFF536E7A)),
            ),
          ),
        ],
      ),
    );
  }
}
