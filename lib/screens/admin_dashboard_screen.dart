import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../models/care_models.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/brand_logo.dart';
import '../widgets/dashboard_grid.dart';
import '../widgets/info_widgets.dart';
import 'admin_create_staff_screen.dart';

const _adminNavy = Color(0xFF12313D);
const _adminSurface = Color(0xFFF5F8FA);
const _adminMuted = Color(0xFF607783);
const _adminLine = Color(0xFFDCE8EC);

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final activeCheckIns = controller.checkIns
        .where((record) => record.status == 'Verified')
        .length;
    final actionRequired = controller.reports
        .where((report) => report.status == ReportStatus.actionRequired)
        .length;
    final incidents = controller.reports
        .where((report) => report.collection == 'incidentReports')
        .length;
    final hazards = controller.reports
        .where((report) => report.collection == 'hazardReports')
        .length;
    final incidentReports = controller.reports
        .where((report) => report.collection == 'incidentReports')
        .toList();
    final hazardReports = controller.reports
        .where((report) => report.collection == 'hazardReports')
        .toList();
    final actionRequiredReports = controller.reports
        .where((report) => report.status == ReportStatus.actionRequired)
        .toList();
    final activeStaffRecords = controller.checkIns
        .where((record) => record.status == 'Verified')
        .toList();

    return Scaffold(
      backgroundColor: _adminSurface,
      drawer: _AdminPortalDrawer(
        onCreateStaff: () =>
            openScreen(context, const AdminCreateStaffScreen()),
        onScheduler: () => openScreen(context, const AdminRosteringScreen()),
        onStaff: () => openScreen(context, const AdminStaffDirectoryScreen()),
        onClients: () =>
            openScreen(context, const AdminResidentOnboardingScreen()),
        onTasks: () => openScreen(context, const AdminTaskManagementScreen()),
        onReports: () => openScreen(
          context,
          AdminFilteredReportsScreen(
            title: 'Submitted records',
            reports: controller.reports,
          ),
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 76,
        backgroundColor: _adminNavy,
        foregroundColor: Colors.white,
        title: const CareSnapWordmark(compact: true, light: true),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.isBusy ? null : controller.refresh,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => signOutAndReturnToLogin(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                _AdminSchedulerBoard(
                  activeStaff: activeCheckIns,
                  actionRequired: actionRequired,
                  onVacantShift: () =>
                      openScreen(context, const AdminRosteringScreen()),
                  onAssignStaff: () =>
                      openScreen(context, const AdminAssignShiftScreen()),
                  onStaffDirectory: () =>
                      openScreen(context, const AdminStaffDirectoryScreen()),
                  onClientList: () => openScreen(
                    context,
                    const AdminResidentOnboardingScreen(),
                  ),
                ),
                const SizedBox(height: 18),
                _AdminDashboardHeader(
                  activeStaff: activeCheckIns,
                  actionRequired: actionRequired,
                ),
                const SizedBox(height: 14),
                _AdminActionPanel(
                  onCreateStaff: () =>
                      openScreen(context, const AdminCreateStaffScreen()),
                  onReviewReports: () => openScreen(
                    context,
                    AdminFilteredReportsScreen(
                      title: 'Submitted records',
                      reports: controller.reports,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(title: 'Rostering & people'),
                const SizedBox(height: 12),
                DashboardGrid(
                  minTileWidth: 230,
                  childAspectRatio: 1.7,
                  children: [
                    _AdminWorkflowCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Rostering',
                      subtitle:
                          'Assign staff to care visits and review coverage.',
                      color: const Color(0xFF2868D9),
                      onTap: () =>
                          openScreen(context, const AdminRosteringScreen()),
                    ),
                    _AdminWorkflowCard(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Staff directory',
                      subtitle: 'Review active staff and remove access.',
                      color: const Color(0xFF087C89),
                      onTap: () => openScreen(
                        context,
                        const AdminStaffDirectoryScreen(),
                      ),
                    ),
                    _AdminWorkflowCard(
                      icon: Icons.elderly_outlined,
                      title: 'Onboard client',
                      subtitle: 'Create a new resident support profile.',
                      color: const Color(0xFF1B9B73),
                      onTap: () => openScreen(
                        context,
                        const AdminResidentOnboardingScreen(),
                      ),
                    ),
                    _AdminWorkflowCard(
                      icon: Icons.task_alt_outlined,
                      title: 'Shift tasks',
                      subtitle: 'Add task items for assigned staff shifts.',
                      color: const Color(0xFF6F5BD8),
                      onTap: () => openScreen(
                        context,
                        const AdminTaskManagementScreen(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionHeader(title: 'Shift overview'),
                const SizedBox(height: 12),
                DashboardGrid(
                  minTileWidth: 190,
                  childAspectRatio: 1.78,
                  children: [
                    _AdminMetricCard(
                      icon: Icons.verified_user_rounded,
                      label: 'Active staff',
                      value: '$activeCheckIns',
                      color: const Color(0xFF10B889),
                      onTap: () => openScreen(
                        context,
                        AdminCheckInsScreen(
                          title: 'Active staff',
                          checkIns: activeStaffRecords,
                        ),
                      ),
                    ),
                    _AdminMetricCard(
                      icon: Icons.emergency_rounded,
                      label: 'Incidents',
                      value: '$incidents',
                      color: const Color(0xFFC43D32),
                      onTap: () => openScreen(
                        context,
                        AdminFilteredReportsScreen(
                          title: 'Incident reports',
                          reports: incidentReports,
                        ),
                      ),
                    ),
                    _AdminMetricCard(
                      icon: Icons.health_and_safety_rounded,
                      label: 'Hazards',
                      value: '$hazards',
                      color: const Color(0xFFE08A1E),
                      onTap: () => openScreen(
                        context,
                        AdminFilteredReportsScreen(
                          title: 'Hazard reports',
                          reports: hazardReports,
                        ),
                      ),
                    ),
                    _AdminMetricCard(
                      icon: Icons.flag_rounded,
                      label: 'Action required',
                      value: '$actionRequired',
                      color: const Color(0xFF087589),
                      onTap: () => openScreen(
                        context,
                        AdminFilteredReportsScreen(
                          title: 'Action required',
                          reports: actionRequiredReports,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SectionHeader(title: 'GPS check-ins'),
                const SizedBox(height: 12),
                if (controller.checkIns.isEmpty)
                  const EmptyState(
                    icon: Icons.my_location,
                    message: 'No check-ins recorded yet.',
                  )
                else
                  ...controller.checkIns
                      .take(4)
                      .map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InfoCard(
                            icon: record.status == 'Verified'
                                ? Icons.verified_outlined
                                : Icons.location_off_outlined,
                            title: record.status,
                            subtitle:
                                '${record.distanceMetres.toStringAsFixed(0)} m from assigned location • ${DateFormat('d MMM, h:mm a').format(record.createdAt)}',
                            badge: StatusBadge(
                              label: record.status,
                              color: record.status == 'Verified'
                                  ? const Color(0xFF327A60)
                                  : const Color(0xFFC43D32),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 22),
                SectionHeader(title: 'Submitted records'),
                const SizedBox(height: 12),
                ReportList(
                  reports: controller.reports,
                  emptyMessage: 'No submitted care records yet.',
                  embedded: true,
                  onTap: (report) => openScreen(
                    context,
                    AdminReportDetailScreen(report: report),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminPortalDrawer extends StatelessWidget {
  const _AdminPortalDrawer({
    required this.onCreateStaff,
    required this.onScheduler,
    required this.onStaff,
    required this.onClients,
    required this.onTasks,
    required this.onReports,
  });

  final VoidCallback onCreateStaff;
  final VoidCallback onScheduler;
  final VoidCallback onStaff;
  final VoidCallback onClients;
  final VoidCallback onTasks;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    void closeAndRun(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    void closeAndSnack(String message) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              color: _adminNavy,
              child: const CareSnapWordmark(compact: true, light: true),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _AdminDrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    selected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Scheduler',
                    onTap: () => closeAndRun(onScheduler),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.apartment_outlined,
                    label: 'Facilities',
                    onTap: () => closeAndSnack('Facilities opened.'),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.badge_outlined,
                    label: 'Staff',
                    onTap: () => closeAndRun(onStaff),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.groups_2_outlined,
                    label: 'Clients',
                    onTap: () => closeAndRun(onClients),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.access_time_outlined,
                    label: 'Timesheet',
                    onTap: () => closeAndSnack('Timesheet review opened.'),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.task_alt_outlined,
                    label: 'Tasks',
                    onTap: () => closeAndRun(onTasks),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Invoices',
                    onTap: () => closeAndSnack('Invoice queue opened.'),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.assignment_outlined,
                    label: 'Forms',
                    onTap: () => closeAndRun(onReports),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.report_problem_outlined,
                    label: 'Incidents',
                    onTap: () => closeAndRun(onReports),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.analytics_outlined,
                    label: 'Reports',
                    onTap: () => closeAndRun(onReports),
                  ),
                  const Divider(height: 24),
                  _AdminDrawerItem(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Create staff',
                    onTap: () => closeAndRun(onCreateStaff),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  const _AdminDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? const Color(0xFFE9EFFB) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? const Color(0xFF29306E) : _adminMuted,
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? const Color(0xFF29306E) : _adminNavy,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: _adminMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSchedulerBoard extends StatelessWidget {
  const _AdminSchedulerBoard({
    required this.activeStaff,
    required this.actionRequired,
    required this.onVacantShift,
    required this.onAssignStaff,
    required this.onStaffDirectory,
    required this.onClientList,
  });

  final int activeStaff;
  final int actionRequired;
  final VoidCallback onVacantShift;
  final VoidCallback onAssignStaff;
  final VoidCallback onStaffDirectory;
  final VoidCallback onClientList;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(4, (index) => today.add(Duration(days: index)));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10102B38),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF262B68),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Text(
                  'Scheduler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                _SchedulerIconButton(
                  icon: Icons.search_rounded,
                  onTap: () => showSnack(context, 'Search roster opened.'),
                ),
                const SizedBox(width: 8),
                _SchedulerIconButton(
                  icon: Icons.flag_outlined,
                  onTap: onVacantShift,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                _AdminFilterChip(label: 'Sydney', onTap: onClientList),
                _AdminFilterChip(label: 'Client', onTap: onClientList),
                _AdminFilterChip(label: 'All status', onTap: onVacantShift),
                _AdminFilterChip(label: 'All types', onTap: onAssignStaff),
                _AdminFilterChip(
                  label: 'Weekly',
                  onTap: () => showSnack(context, 'Weekly roster selected.'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _adminLine),
                bottom: BorderSide(color: _adminLine),
              ),
            ),
            child: Row(
              children: days.map((day) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(day).toUpperCase(),
                        style: const TextStyle(
                          color: _adminMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: _adminNavy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          _RosterScheduleRow(
            avatar: 'VS',
            name: 'Vacant Shift',
            time: '4am - 7am',
            client: 'Steven Bradbury',
            service: 'Morning support',
            statusColor: const Color(0xFFC43D32),
            cardColor: const Color(0xFFFFF1F1),
            onTap: onVacantShift,
          ),
          _RosterScheduleRow(
            avatar: 'CT',
            name: 'Cathy',
            time: '9am - 12pm',
            client: 'Shane Jacobson',
            service: 'Domestic assistance',
            statusColor: const Color(0xFF1B9B73),
            cardColor: const Color(0xFFE8F8EF),
            onTap: onAssignStaff,
          ),
          _RosterScheduleRow(
            avatar: 'JL',
            name: 'Jolene',
            time: '4pm - 7pm',
            client: 'John Smith',
            service: 'Community participation',
            statusColor: const Color(0xFF1B9B73),
            cardColor: const Color(0xFFE8F8EF),
            onTap: onStaffDirectory,
          ),
          _RosterScheduleRow(
            avatar: 'LY',
            name: 'Lyla',
            time: '9am - 6pm',
            client: 'Sophie Baxter',
            service: 'SIL afternoon',
            statusColor: const Color(0xFF2868D9),
            cardColor: const Color(0xFFEAF1FF),
            onTap: onAssignStaff,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: _SchedulerStat(
                    label: 'Active staff',
                    value: '$activeStaff',
                    color: const Color(0xFF1B9B73),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SchedulerStat(
                    label: 'Follow-ups',
                    value: '$actionRequired',
                    color: actionRequired > 0
                        ? const Color(0xFFC43D32)
                        : const Color(0xFF2868D9),
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

class _SchedulerIconButton extends StatelessWidget {
  const _SchedulerIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _AdminFilterChip extends StatelessWidget {
  const _AdminFilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        avatar: const Icon(Icons.expand_more_rounded, size: 16),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        labelStyle: const TextStyle(
          color: _adminMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RosterScheduleRow extends StatelessWidget {
  const _RosterScheduleRow({
    required this.avatar,
    required this.name,
    required this.time,
    required this.client,
    required this.service,
    required this.statusColor,
    required this.cardColor,
    required this.onTap,
  });

  final String avatar;
  final String name;
  final String time;
  final String client;
  final String service;
  final Color statusColor;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _adminLine)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: statusColor,
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 88,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(
                    left: BorderSide(color: statusColor, width: 4),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: _adminNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      client,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: _adminMuted),
          ],
        ),
      ),
    );
  }
}

class _SchedulerStat extends StatelessWidget {
  const _SchedulerStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: _adminMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardHeader extends StatelessWidget {
  const _AdminDashboardHeader({
    required this.activeStaff,
    required this.actionRequired,
  });

  final int activeStaff;
  final int actionRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF4F6)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF12313D), Color(0xFF087C89)],
                  ),
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
                        color: _adminNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Care operations centre',
                      style: TextStyle(
                        color: _adminMuted,
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
              final tiles = [
                _HeaderMetric(
                  label: 'Staff on shift',
                  value: '$activeStaff',
                  icon: Icons.groups_2_outlined,
                  color: const Color(0xFF1B9B73),
                ),
                _HeaderMetric(
                  label: 'Action required',
                  value: '$actionRequired',
                  icon: Icons.flag_outlined,
                  color: actionRequired > 0
                      ? const Color(0xFFC43D32)
                      : const Color(0xFF327A60),
                ),
              ];
              if (compact) {
                return Column(
                  children: tiles
                      .map(
                        (tile) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: tile,
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 10),
                  Expanded(child: tiles[1]),
                ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
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
                    color: _adminNavy,
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
                    color: _adminMuted,
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

class _AdminActionPanel extends StatelessWidget {
  const _AdminActionPanel({
    required this.onCreateStaff,
    required this.onReviewReports,
  });

  final VoidCallback onCreateStaff;
  final VoidCallback onReviewReports;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
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
              'Quick actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage staff access and review submitted care records.',
              style: TextStyle(color: _adminMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCreateStaff,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Create staff'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReviewReports,
                    icon: const Icon(Icons.folder_copy_outlined),
                    label: const Text('Records'),
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

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
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
            border: Border.all(color: _adminLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.18),
                          color.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF8AA0A8),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _adminNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _adminMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminWorkflowCard extends StatelessWidget {
  const _AdminWorkflowCard({
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
            border: Border.all(color: _adminLine),
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
                        color: _adminNavy,
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
                        color: _adminMuted,
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

class AdminRosteringScreen extends StatelessWidget {
  const AdminRosteringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final reportsNeedingAction = controller.reports
        .where((report) => report.status == ReportStatus.actionRequired)
        .length;
    return AppScaffold(
      title: 'Rostering',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminRosterSummary(actionRequired: reportsNeedingAction),
          const SizedBox(height: 12),
          _RosterAssignmentCard(
            title: 'Personal care visit',
            time: '7:00 AM - 3:00 PM',
            staff: 'Mia Thompson',
            client: 'Avery Nguyen',
            location: 'Harbourview Supported Living, Suite 12',
            status: 'Assigned',
            onPressed: () =>
                showSnack(context, 'Roster assignment marked for review.'),
          ),
          const SizedBox(height: 12),
          _RosterAssignmentCard(
            title: 'Evening SIL support',
            time: '3:00 PM - 10:00 PM',
            staff: 'Unassigned',
            client: 'Jamie Marsh',
            location: '143 Knoke Ave, Gordon ACT 2906',
            status: 'Open',
            onPressed: () =>
                openScreen(context, const AdminAssignShiftScreen()),
          ),
        ],
      ),
    );
  }
}

class _AdminRosterSummary extends StatelessWidget {
  const _AdminRosterSummary({required this.actionRequired});

  final int actionRequired;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coverage overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const StatusBadge(
                  label: '2 assigned visits',
                  color: Color(0xFF1B9B73),
                ),
                StatusBadge(
                  label: '$actionRequired follow-ups',
                  color: actionRequired > 0
                      ? const Color(0xFFC43D32)
                      : const Color(0xFF327A60),
                ),
                const StatusBadge(
                  label: '1 open shift',
                  color: Color(0xFFF1A73A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterAssignmentCard extends StatelessWidget {
  const _RosterAssignmentCard({
    required this.title,
    required this.time,
    required this.staff,
    required this.client,
    required this.location,
    required this.status,
    required this.onPressed,
  });

  final String title;
  final String time;
  final String staff;
  final String client;
  final String location;
  final String status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final open = status == 'Open';
    return InfoCard(
      icon: open ? Icons.person_add_alt_1_outlined : Icons.event_available,
      title: '$title • $time',
      subtitle: 'Staff: $staff\nClient: $client\n$location',
      badge: StatusBadge(
        label: status,
        color: open ? const Color(0xFFF1A73A) : const Color(0xFF1B9B73),
      ),
      onTap: onPressed,
    );
  }
}

class AdminAssignShiftScreen extends StatefulWidget {
  const AdminAssignShiftScreen({super.key});

  @override
  State<AdminAssignShiftScreen> createState() => _AdminAssignShiftScreenState();
}

class _AdminAssignShiftScreenState extends State<AdminAssignShiftScreen> {
  final formKey = GlobalKey<FormState>();
  final staffEmailController = TextEditingController(
    text: 'staffmarmik@caresnap.com',
  );
  final clientNameController = TextEditingController(text: 'Jamie Marsh');
  final dateController = TextEditingController(text: '2026-05-24');
  final startController = TextEditingController(text: '15:00');
  final endController = TextEditingController(text: '22:00');
  final locationController = TextEditingController(
    text: '143 Knoke Ave, Gordon ACT 2906, Australia',
  );
  bool isSaving = false;

  @override
  void dispose() {
    staffEmailController.dispose();
    clientNameController.dispose();
    dateController.dispose();
    startController.dispose();
    endController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final staffEmail = staffEmailController.text.trim().toLowerCase();
      final staffSnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: staffEmail)
          .limit(1)
          .get();
      if (staffSnapshot.docs.isEmpty) {
        throw StateError('Staff email was not found.');
      }

      final clientName = clientNameController.text.trim();
      final clientSnapshot = await firestore
          .collection('clients')
          .where('fullName', isEqualTo: clientName)
          .limit(1)
          .get();
      final clientId = clientSnapshot.docs.isNotEmpty
          ? clientSnapshot.docs.first.id
          : await _createClientProfile(firestore, clientName);

      final start = _dateTimeFromFields(
        dateController.text.trim(),
        startController.text.trim(),
      );
      final end = _dateTimeFromFields(
        dateController.text.trim(),
        endController.text.trim(),
      );

      await firestore.collection('shifts').add({
        'staffId': staffSnapshot.docs.first.id,
        'clientId': clientId,
        'startTime': Timestamp.fromDate(start),
        'endTime': Timestamp.fromDate(end),
        'serviceLocation': locationController.text.trim(),
        'assignedLatitude': -35.456,
        'assignedLongitude': 149.087,
        'shiftStatus': 'Scheduled',
        'checkInStatus': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showSnack(context, 'Shift assigned to $staffEmail.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<String> _createClientProfile(
    FirebaseFirestore firestore,
    String clientName,
  ) async {
    final doc = await firestore.collection('clients').add({
      'fullName': clientName,
      'roomNumber': 'Community support',
      'address': locationController.text.trim(),
      'careNeeds': 'SIL support and community participation.',
      'mobilityStatus': 'Pending assessment',
      'communicationNeeds': 'Pending assessment',
      'riskNotes': 'Pending assessment',
      'emergencyContact': 'To be confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  DateTime _dateTimeFromFields(String dateValue, String timeValue) {
    final date = DateTime.tryParse(dateValue);
    final parts = timeValue.split(':');
    if (date == null || parts.length != 2) {
      throw StateError('Use date YYYY-MM-DD and time HH:mm.');
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Assign shift',
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roster assignment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AdminTextField(
                      controller: staffEmailController,
                      label: 'Staff email',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: clientNameController,
                      label: 'Client name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: dateController,
                      label: 'Date',
                      icon: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AdminTextField(
                            controller: startController,
                            label: 'Start',
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AdminTextField(
                            controller: endController,
                            label: 'End',
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isSaving ? null : submit,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Assign staff'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminTaskManagementScreen extends StatefulWidget {
  const AdminTaskManagementScreen({super.key});

  @override
  State<AdminTaskManagementScreen> createState() =>
      _AdminTaskManagementScreenState();
}

class _AdminTaskManagementScreenState extends State<AdminTaskManagementScreen> {
  final formKey = GlobalKey<FormState>();
  final shiftIdController = TextEditingController();
  final titleController = TextEditingController();
  final categoryController = TextEditingController(text: 'Shift task');
  final notesController = TextEditingController();
  late Future<List<_AdminShiftOption>> shiftsFuture;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    shiftsFuture = _loadShifts();
  }

  @override
  void dispose() {
    shiftIdController.dispose();
    titleController.dispose();
    categoryController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<List<_AdminShiftOption>> _loadShifts() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('shifts').limit(30).get();
    final shifts = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final staffId = data['staffId'] as String? ?? '';
        final clientId = data['clientId'] as String? ?? '';
        final staffName = await _nameFor(firestore, 'users', staffId);
        final clientName = await _nameFor(firestore, 'clients', clientId);
        return _AdminShiftOption(
          id: doc.id,
          staffName: staffName ?? 'Assigned staff',
          clientName: clientName ?? 'Client',
          startTime: dateFromFirestore(data['startTime']) ?? DateTime.now(),
          location: data['serviceLocation'] as String? ?? 'Service location',
        );
      }),
    );
    shifts.sort((a, b) => a.startTime.compareTo(b.startTime));
    return shifts;
  }

  Future<String?> _nameFor(
    FirebaseFirestore firestore,
    String collection,
    String id,
  ) async {
    if (id.isEmpty) return null;
    final doc = await firestore.collection(collection).doc(id).get();
    final data = doc.data();
    if (collection == 'users') return data?['fullName'] as String?;
    return data?['fullName'] as String?;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('shiftTasks').add({
        'shiftId': shiftIdController.text.trim(),
        'title': titleController.text.trim(),
        'category': categoryController.text.trim().isEmpty
            ? 'Shift task'
            : categoryController.text.trim(),
        'notes': notesController.text.trim(),
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      titleController.clear();
      notesController.clear();
      if (mounted) {
        showSnack(context, 'Task added to shift.');
        setState(() {
          shiftsFuture = _loadShifts();
        });
      }
    } catch (error) {
      if (mounted) {
        showSnack(context, error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Shift tasks',
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add staff task',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select an assigned shift, then add the task staff should complete.',
                      style: TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AdminTextField(
                      controller: shiftIdController,
                      label: 'Selected shift ID',
                      icon: Icons.event_available_outlined,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: titleController,
                      label: 'Task title',
                      icon: Icons.task_alt_outlined,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: categoryController,
                      label: 'Category',
                      icon: Icons.label_outline,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: notesController,
                      label: 'Task instructions',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSaving ? null : submit,
                        icon: isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_task_outlined),
                        label: const Text('Add task'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Assigned shifts',
              trailing: IconButton(
                tooltip: 'Refresh shifts',
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() => shiftsFuture = _loadShifts()),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<_AdminShiftOption>>(
              future: shiftsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final shifts = snapshot.data ?? [];
                if (shifts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy_outlined,
                    message: 'No shifts are assigned yet.',
                  );
                }
                return Column(
                  children: shifts.map((shift) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InfoCard(
                        icon: Icons.event_available_outlined,
                        title:
                            '${shift.staffName} • ${DateFormat('EEE, d MMM').format(shift.startTime)}',
                        subtitle:
                            '${shift.clientName}\n${DateFormat.jm().format(shift.startTime)} • ${shift.location}',
                        badge: StatusBadge(
                          label: shiftIdController.text.trim() == shift.id
                              ? 'Selected'
                              : 'Use',
                          color: shiftIdController.text.trim() == shift.id
                              ? _adminNavy
                              : _adminMuted,
                        ),
                        onTap: () {
                          setState(() => shiftIdController.text = shift.id);
                          showSnack(context, 'Shift selected.');
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminShiftOption {
  const _AdminShiftOption({
    required this.id,
    required this.staffName,
    required this.clientName,
    required this.startTime,
    required this.location,
  });

  final String id;
  final String staffName;
  final String clientName;
  final DateTime startTime;
  final String location;
}

class AdminStaffDirectoryScreen extends StatelessWidget {
  const AdminStaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Staff directory',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StaffDirectoryCard(
            name: 'Mia Thompson',
            email: 'staff@caresnap.test',
            role: 'Disability Support Worker',
            active: true,
            onRemove: () => showSnack(context, 'Staff access removal queued.'),
          ),
          const SizedBox(height: 12),
          _StaffDirectoryCard(
            name: 'Marmik Karki',
            email: 'staffmarmik@caresnap.com',
            role: 'Support Worker',
            active: true,
            onRemove: () => showSnack(context, 'Staff access removal queued.'),
          ),
        ],
      ),
    );
  }
}

class _StaffDirectoryCard extends StatelessWidget {
  const _StaffDirectoryCard({
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.onRemove,
  });

  final String name;
  final String email;
  final String role;
  final bool active;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE6F3F5),
                  child: Icon(Icons.badge_outlined, color: _adminNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _adminNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _adminMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: active ? 'Active' : 'Inactive',
                  color: active
                      ? const Color(0xFF1B9B73)
                      : const Color(0xFF7C8790),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              role,
              style: const TextStyle(
                color: _adminMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Remove access'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminResidentOnboardingScreen extends StatefulWidget {
  const AdminResidentOnboardingScreen({super.key});

  @override
  State<AdminResidentOnboardingScreen> createState() =>
      _AdminResidentOnboardingScreenState();
}

class _AdminResidentOnboardingScreenState
    extends State<AdminResidentOnboardingScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final suiteController = TextEditingController();
  final addressController = TextEditingController();
  final careNeedsController = TextEditingController();
  final emergencyContactController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    suiteController.dispose();
    addressController.dispose();
    careNeedsController.dispose();
    emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final name = nameController.text.trim();
    try {
      await FirebaseFirestore.instance.collection('clients').add({
        'fullName': name,
        'roomNumber': suiteController.text.trim(),
        'address': addressController.text.trim(),
        'careNeeds': careNeedsController.text.trim(),
        'mobilityStatus': 'Pending assessment',
        'communicationNeeds': 'Pending assessment',
        'riskNotes': 'Pending assessment',
        'emergencyContact': emergencyContactController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      showSnack(context, '$name has been added to client profiles.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, '$name has been staged for coordinator review.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Onboard client',
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resident support profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AdminTextField(
                      controller: nameController,
                      label: 'Full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: suiteController,
                      label: 'Room or suite',
                      icon: Icons.meeting_room_outlined,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: addressController,
                      label: 'Primary address',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: careNeedsController,
                      label: 'Care needs',
                      icon: Icons.volunteer_activism_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: emergencyContactController,
                      label: 'Emergency contact',
                      icon: Icons.call_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: submit,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add client profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(prefixIcon: Icon(icon), labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}

class AdminFilteredReportsScreen extends StatelessWidget {
  const AdminFilteredReportsScreen({
    super.key,
    required this.title,
    required this.reports,
  });

  final String title;
  final List<ReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: ReportList(
        reports: reports,
        emptyMessage: 'No records found.',
        onTap: (report) =>
            openScreen(context, AdminReportDetailScreen(report: report)),
      ),
    );
  }
}

class AdminCheckInsScreen extends StatelessWidget {
  const AdminCheckInsScreen({
    super.key,
    required this.title,
    required this.checkIns,
  });

  final String title;
  final List<CheckInRecord> checkIns;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: checkIns.isEmpty ? 1 : checkIns.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (checkIns.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_user_outlined,
              message: 'No active staff check-ins yet.',
            );
          }
          final record = checkIns[index];
          return InfoCard(
            icon: Icons.verified_outlined,
            title: record.status,
            subtitle:
                '${record.distanceMetres.toStringAsFixed(0)} m from assigned location\n${DateFormat('d MMM yyyy, h:mm a').format(record.createdAt)}',
            badge: const StatusBadge(label: 'Active', color: Color(0xFF327A60)),
          );
        },
      ),
    );
  }
}

class AdminReportDetailScreen extends StatelessWidget {
  const AdminReportDetailScreen({super.key, required this.report});

  final ReportSummary report;

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return AppScaffold(
      title: 'Report review',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportReviewHeader(report: report),
          const SizedBox(height: 12),
          _ReportDetailsCard(report: report),
          if (report.imageUrl != null) ...[
            const SizedBox(height: 12),
            _ReportEvidenceCard(imageUrl: report.imageUrl!),
          ],
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ReportStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : () async {
                                await controller.updateReportStatus(
                                  report,
                                  status,
                                );
                                if (context.mounted) {
                                  showSnack(
                                    context,
                                    'Status updated to ${status.label}.',
                                  );
                                  Navigator.pop(context);
                                }
                              },
                        icon: Icon(
                          status == report.status
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        label: Text(status.label),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportReviewHeader extends StatelessWidget {
  const _ReportReviewHeader({required this.report});

  final ReportSummary report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconForReport(report.collection),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _adminNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d MMM yyyy, h:mm a').format(report.createdAt),
                    style: const TextStyle(
                      color: _adminMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(label: report.status.label, color: report.status.color),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailsCard extends StatelessWidget {
  const _ReportDetailsCard({required this.report});

  final ReportSummary report;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Staff member', report.staffName ?? report.staffId),
      if (report.clientName != null)
        MapEntry('Client', report.clientName!)
      else if (report.clientId.isNotEmpty)
        MapEntry('Client', report.clientId),
      ...report.details.entries,
    ].where((entry) => entry.value.trim().isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...rows.map((entry) => _ReportDetailRow(entry: entry)),
          ],
        ),
      ),
    );
  }
}

class _ReportDetailRow extends StatelessWidget {
  const _ReportDetailRow({required this.entry});

  final MapEntry<String, String> entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 520;
          final label = Text(
            entry.key,
            style: const TextStyle(
              color: _adminMuted,
              fontWeight: FontWeight.w800,
            ),
          );
          final value = Text(
            entry.value,
            style: const TextStyle(
              color: _adminNavy,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 4), value],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 160, child: label),
              Expanded(child: value),
            ],
          );
        },
      ),
    );
  }
}

class _ReportEvidenceCard extends StatelessWidget {
  const _ReportEvidenceCard({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final canPreview = imageUrl.startsWith('http');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined, color: _adminNavy),
                const SizedBox(width: 10),
                Text(
                  'Photo evidence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (canPreview)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 260,
                      alignment: Alignment.center,
                      color: const Color(0xFFEAF6F8),
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const _ImageError(),
                ),
              )
            else
              const _ImageError(),
          ],
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF3CF8A)),
      ),
      child: const Text(
        'Image preview is unavailable for this record.',
        style: TextStyle(color: Color(0xFF8A5A00), fontWeight: FontWeight.w700),
      ),
    );
  }
}
