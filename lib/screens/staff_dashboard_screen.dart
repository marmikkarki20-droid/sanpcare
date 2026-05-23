import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../models/care_models.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/info_widgets.dart';
import '../widgets/location_map_card.dart';
import 'behaviour_chart_screen.dart';
import 'gps_check_in_screen.dart';
import 'hazard_report_screen.dart';
import 'incident_report_screen.dart';
import 'my_reports_screen.dart';
import 'progress_note_screen.dart';

const _navy = Color(0xFF12313D);
const _ink = Color(0xFF17262E);
const _muted = Color(0xFF637781);
const _scheduleBlue = Color(0xFF087C89);
const _actionGreen = Color(0xFF1B9B73);
const _surface = Color(0xFFF5F8FA);
const _line = Color(0xFFDCE8EC);

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final user = controller.user;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final shift = controller.shift;
    final client = controller.client;
    final selectedDate = _dateOnly(shift?.startTime ?? DateTime.now());
    final scheduleDates = List.generate(
      5,
      (index) => selectedDate.add(Duration(days: index)),
    );

    return Scaffold(
      backgroundColor: _surface,
      drawer: _StaffDrawer(user: user),
      appBar: AppBar(
        toolbarHeight: 88,
        centerTitle: true,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          DateFormat('MMM yyyy').format(selectedDate).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        leadingWidth: 76,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menu',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.menu_rounded, size: 34),
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD71920),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, size: 30),
            onPressed: controller.isBusy ? null : controller.refresh,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            children: [
              _WeekStrip(selectedDate: selectedDate),
              const _DownCue(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      ...scheduleDates.map((date) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _ScheduleDayRow(
                            date: date,
                            child:
                                shift != null &&
                                    client != null &&
                                    _isSameDay(date, shift.startTime)
                                ? _RosterShiftCard(
                                    shift: shift,
                                    client: client,
                                    onTap: () => openScreen(
                                      context,
                                      const StaffShiftDetailScreen(),
                                    ),
                                  )
                                : const _NoShiftCard(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StaffShiftDetailScreen extends StatefulWidget {
  const StaffShiftDetailScreen({super.key});

  @override
  State<StaffShiftDetailScreen> createState() => _StaffShiftDetailScreenState();
}

class _StaffShiftDetailScreenState extends State<StaffShiftDetailScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final shift = controller.shift;
    final client = controller.client;
    final user = controller.user;

    if (shift == null || client == null || user == null) {
      return const AppScaffold(
        title: 'Shift details',
        body: EmptyState(
          icon: Icons.event_busy_outlined,
          message: 'No shift has been assigned yet.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left, size: 34),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 6,
        title: Text(
          '${client.fullName} - Personal Care',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _ShiftDetailsTab(shift: shift, client: client, user: user),
          _ShiftTasksTab(tasks: controller.shiftTasks),
          _ShiftProgressTab(notes: controller.progressNotes),
          _ShiftEventsTab(reports: controller.reports),
        ],
      ),
      floatingActionButton: selectedIndex == 2
          ? const _ProgressActionMenu()
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Details',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted),
            selectedIcon: Icon(Icons.format_list_bulleted),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.comment_outlined),
            selectedIcon: Icon(Icons.comment),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Events',
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday % DateTime.daysPerWeek),
    );
    final days = List.generate(
      DateTime.daysPerWeek,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 12),
      color: Colors.white,
      child: Row(
        children: days.map((day) {
          final selected = _isSameDay(day, selectedDate);
          final hasShift =
              selected ||
              day.difference(selectedDate).inDays == 3 ||
              day.difference(selectedDate).inDays == -1;
          return Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('EEE').format(day),
                  style: TextStyle(
                    color: selected ? _scheduleBlue : _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 48 : 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _scheduleBlue : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasShift ? _scheduleBlue : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DownCue extends StatelessWidget {
  const _DownCue();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 34,
        child: Icon(
          Icons.keyboard_double_arrow_down_rounded,
          size: 34,
          color: _scheduleBlue,
        ),
      ),
    );
  }
}

class _ScheduleDayRow extends StatelessWidget {
  const _ScheduleDayRow({required this.date, required this.child});

  final DateTime date;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Column(
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEE').format(date),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _RosterShiftCard extends StatelessWidget {
  const _RosterShiftCard({
    required this.shift,
    required this.client,
    required this.onTap,
  });

  final ShiftAssignment shift;
  final ClientProfile client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = shift.isEnded
        ? 'Completed'
        : shift.isCheckedIn
        ? 'Started'
        : 'Booked';
    final statusColor = shift.isEnded
        ? const Color(0xFF7C8790)
        : shift.isCheckedIn
        ? _actionGreen
        : _scheduleBlue;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Personal Care',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusBadge(label: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 14),
              _IconTextLine(
                icon: Icons.access_time_rounded,
                iconColor: _scheduleBlue,
                text: _timeRange(shift),
                textColor: _ink,
              ),
              const SizedBox(height: 12),
              _IconTextLine(
                icon: Icons.account_circle,
                iconColor: _scheduleBlue,
                text: client.fullName,
                textColor: _ink,
              ),
              const SizedBox(height: 12),
              _IconTextLine(
                icon: Icons.location_on_outlined,
                iconColor: _muted,
                text: shift.serviceLocation,
                textColor: _ink,
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View shift',
                    style: TextStyle(
                      color: _scheduleBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: _scheduleBlue,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoShiftCard extends StatelessWidget {
  const _NoShiftCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: const Text(
        'No scheduled visit',
        style: TextStyle(
          color: _muted,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StaffDrawer extends StatelessWidget {
  const _StaffDrawer({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final controller = CareScope.of(context);
    var notificationsEnabled = false;

    void closeAndOpen(Widget screen) {
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.push(MaterialPageRoute(builder: (_) => screen));
    }

    void closeAndSnack(String message) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    return Drawer(
      width: math.min(width * 0.82, 380),
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 34, 14, 12),
                child: Column(
                  children: [
                    const _DrawerProfileAvatar(),
                    const SizedBox(height: 18),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        user.email,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _DrawerAction(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notification',
                      trailing: _DrawerBadge(
                        count: controller.shift == null ? 1 : 2,
                      ),
                      onTap: () => closeAndOpen(
                        StaffNotificationsScreen(
                          shift: controller.shift,
                          user: user,
                        ),
                      ),
                    ),
                    _DrawerAction(
                      icon: Icons.home_outlined,
                      label: 'My Schedule',
                      selected: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _DrawerAction(
                      icon: Icons.event_busy_outlined,
                      label: 'Availability',
                      onTap: () =>
                          closeAndOpen(const StaffAvailabilityScreen()),
                    ),
                    _DrawerAction(
                      icon: Icons.access_time,
                      label: 'My Timesheet',
                      onTap: () => closeAndOpen(const MyReportsScreen()),
                    ),
                    _DrawerAction(
                      icon: Icons.description_outlined,
                      label: 'My Documents',
                      onTap: () => closeAndOpen(const StaffDocumentsScreen()),
                    ),
                    _DrawerAction(
                      icon: Icons.folder_open_outlined,
                      label: 'Document Hub',
                      onTap: () => closeAndOpen(const DocumentHubScreen()),
                    ),
                    _DrawerAction(
                      icon: Icons.cloud_off_outlined,
                      label: 'Offline Settings',
                      onTap: () => closeAndOpen(
                        const StaffInfoScreen(
                          title: 'Offline settings',
                          icon: Icons.cloud_off_outlined,
                          message:
                              'Critical shift details stay available while connectivity is limited.',
                        ),
                      ),
                    ),
                    _DrawerAction(
                      icon: Icons.info_outline,
                      label: 'About',
                      onTap: () => closeAndOpen(
                        const StaffInfoScreen(
                          title: 'About CareSnap',
                          icon: Icons.info_outline,
                          message:
                              'CareSnap supports rostering, GPS clock-in, care notes, incident reporting, and coordinator review.',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                      child: StatefulBuilder(
                        builder: (context, setDrawerState) {
                          return Row(
                            children: [
                              Switch(
                                value: notificationsEnabled,
                                onChanged: (value) => setDrawerState(
                                  () => notificationsEnabled = value,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Shift Notifications',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => closeAndSnack('English selected.'),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    label: const Text('English'),
                    style: TextButton.styleFrom(
                      foregroundColor: _ink,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => signOutAndReturnToLogin(context),
                    icon: const Icon(Icons.power_settings_new_rounded),
                    label: const Text('Log out'),
                    style: TextButton.styleFrom(
                      foregroundColor: _ink,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _DrawerAction extends StatelessWidget {
  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? const Color(0xFFE5F1FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: selected ? const Color(0xFF1680F8) : _muted,
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? const Color(0xFF1680F8) : _muted,
                      fontSize: 19,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerProfileAvatar extends StatelessWidget {
  const _DrawerProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 42,
      backgroundColor: const Color(0xFF5AAEDF),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.person_rounded, color: Colors.white, size: 46),
          Positioned(
            top: 12,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF5AAEDF),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerBadge extends StatelessWidget {
  const _DrawerBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFD71920),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ShiftDetailsTab extends StatelessWidget {
  const _ShiftDetailsTab({
    required this.shift,
    required this.client,
    required this.user,
  });

  final ShiftAssignment shift;
  final ClientProfile client;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: LocationMapCard(
            title: 'Care visit location',
            address: shift.serviceLocation,
            latitude: shift.assignedLatitude,
            longitude: shift.assignedLongitude,
          ),
        ),
        _AssignmentSplit(user: user, client: client),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Details',
                style: TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              _DetailLine(
                icon: Icons.calendar_month,
                label: 'Date',
                value: DateFormat('EEEE\nMMMM d, yyyy').format(shift.startTime),
              ),
              const SizedBox(height: 24),
              _DetailLine(
                icon: Icons.access_time_filled,
                label: 'Time',
                value: _timeRange(shift),
              ),
              const SizedBox(height: 24),
              _DetailLine(
                icon: Icons.explore,
                label: 'Location',
                value: shift.serviceLocation,
              ),
              const SizedBox(height: 30),
              const Text(
                'More Actions',
                style: TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: shift.isEnded
                          ? null
                          : () => openScreen(context, const GpsCheckInScreen()),
                      icon: Icon(
                        shift.isCheckedIn
                            ? Icons.verified_outlined
                            : Icons.my_location,
                      ),
                      label: Text(
                        shift.isCheckedIn ? 'Check-in' : 'Start shift',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: shift.isCheckedIn && !shift.isEnded
                          ? () async {
                              await CareScope.of(context).endShift();
                              if (context.mounted) {
                                showSnack(context, 'Shift ended.');
                              }
                            }
                          : null,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('End shift'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShiftTasksTab extends StatelessWidget {
  const _ShiftTasksTab({required this.tasks});

  final List<ShiftTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt_outlined,
        message: 'No tasks have been assigned by admin yet.',
      );
    }

    final controller = CareScope.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskTile(
          task: task,
          isBusy: controller.isBusy,
          onChanged: (completed) async {
            await controller.setShiftTaskCompleted(task, completed);
            if (context.mounted) {
              showSnack(
                context,
                completed ? 'Task marked complete.' : 'Task reopened.',
              );
            }
          },
        );
      },
    );
  }
}

class _ShiftProgressTab extends StatelessWidget {
  const _ShiftProgressTab({required this.notes});

  final List<ProgressNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      final controller = CareScope.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No Notes!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 27,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Click here to refresh your notes!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox.square(
                dimension: 64,
                child: FilledButton(
                  onPressed: controller.isBusy ? null : controller.refresh,
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 34),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 160),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const Divider(height: 38),
      itemBuilder: (context, index) => _ProgressNoteRow(note: notes[index]),
    );
  }
}

class _ShiftEventsTab extends StatelessWidget {
  const _ShiftEventsTab({required this.reports});

  final List<ReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No events recorded.',
            style: TextStyle(color: _muted, fontSize: 18),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        return InfoCard(
          icon: _reportIcon(report.collection),
          title: report.title,
          subtitle:
              '${report.subtitle}\n${DateFormat('d MMM, h:mm a').format(report.createdAt)}',
          badge: StatusBadge(
            label: report.status.label,
            color: report.status.color,
          ),
        );
      },
    );
  }
}

class _ProgressActionMenu extends StatefulWidget {
  const _ProgressActionMenu();

  @override
  State<_ProgressActionMenu> createState() => _ProgressActionMenuState();
}

class _ProgressActionMenuState extends State<_ProgressActionMenu> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ShiftAction(
        'Progress Notes',
        Icons.notes_outlined,
        const ProgressNoteScreen(),
      ),
      _ShiftAction(
        'Behaviour',
        Icons.psychology_alt_outlined,
        const BehaviourChartScreen(),
      ),
      _ShiftAction(
        'Incident',
        Icons.error_outline,
        const IncidentReportScreen(),
      ),
      _ShiftAction(
        'Hazard',
        Icons.warning_amber_outlined,
        const HazardReportScreen(),
      ),
    ];

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8, right: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (expanded) ...[
            for (final action in actions) ...[
              _FloatingRecordAction(
                action: action,
                onTap: () {
                  setState(() => expanded = false);
                  _openShiftAction(context, action);
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
          FloatingActionButton.large(
            heroTag: 'shift-action-toggle',
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: const CircleBorder(),
            onPressed: () => setState(() => expanded = !expanded),
            child: Icon(
              expanded ? Icons.close_rounded : Icons.add_rounded,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingRecordAction extends StatelessWidget {
  const _FloatingRecordAction({required this.action, required this.onTap});

  final _ShiftAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 7,
          shadowColor: const Color(0x33000000),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              action.label,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Material(
          color: _navy,
          elevation: 8,
          shadowColor: const Color(0x33000000),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(action.icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShiftAction {
  const _ShiftAction(this.label, this.icon, this.screen);

  final String label;
  final IconData icon;
  final Widget screen;
}

class _AssignmentSplit extends StatelessWidget {
  const _AssignmentSplit({required this.user, required this.client});

  final AppUser user;
  final ClientProfile client;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0)),
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _AssignmentPerson(
                label: 'STAFF',
                name: user.fullName,
                avatarColor: const Color(0xFF2EBFE7),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: _AssignmentPerson(
                label: 'CLIENT',
                name: client.fullName,
                avatarColor: const Color(0xFFE4544E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentPerson extends StatelessWidget {
  const _AssignmentPerson({
    required this.label,
    required this.name,
    required this.avatarColor,
  });

  final String label;
  final String name;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: avatarColor,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF55BFEF),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black, size: 26),
        const SizedBox(width: 22),
        SizedBox(
          width: 104,
          child: Text(label, style: const TextStyle(color: _ink, fontSize: 18)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _ink, fontSize: 18, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.isBusy,
    required this.onChanged,
  });

  final ShiftTask task;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0EDF1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isBusy ? null : () => onChanged(!task.isCompleted),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: isBusy
                    ? null
                    : (value) => onChanged(value ?? !task.isCompleted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: task.isCompleted ? _muted : _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (task.notes.isNotEmpty)
                      Text(
                        task.notes,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    const SizedBox(height: 10),
                    StatusBadge(
                      label: task.isCompleted ? 'Completed' : task.category,
                      color: task.isCompleted ? _actionGreen : _scheduleBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                task.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? _actionGreen : _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressNoteRow extends StatelessWidget {
  const _ProgressNoteRow({required this.note});

  final ProgressNote note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFF32C6EC),
          child: Icon(Icons.person, color: Color(0xFFC8F2FF), size: 38),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notes',
                style: TextStyle(
                  color: _scheduleBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                note.shiftSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _muted, width: 1.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'No attachments',
                  style: TextStyle(color: _ink, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconTextLine extends StatelessWidget {
  const _IconTextLine({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class NurseHandoverScreen extends StatelessWidget {
  const NurseHandoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final client = controller.client;
    if (client == null) {
      return const AppScaffold(
        title: 'Nurse handover',
        body: EmptyState(
          icon: Icons.medical_services_outlined,
          message: 'No client has been assigned yet.',
        ),
      );
    }
    return AppScaffold(
      title: 'Nurse handover',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            icon: Icons.medical_services_outlined,
            title: client.fullName,
            subtitle: '${client.roomNumber}\n${client.emergencyContact}',
          ),
          const SizedBox(height: 12),
          InfoCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'Care needs',
            subtitle: client.careNeeds,
          ),
          const SizedBox(height: 12),
          InfoCard(
            icon: Icons.accessible_forward_outlined,
            title: 'Mobility support',
            subtitle: client.mobilityStatus,
          ),
          const SizedBox(height: 12),
          InfoCard(
            icon: Icons.record_voice_over_outlined,
            title: 'Communication',
            subtitle: client.communicationNeeds,
          ),
          const SizedBox(height: 12),
          InfoCard(
            icon: Icons.priority_high_outlined,
            title: 'Risk alerts',
            subtitle: client.riskNotes,
            badge: const StatusBadge(label: 'Review', color: Color(0xFFC43D32)),
          ),
        ],
      ),
    );
  }
}

class StaffNotificationsScreen extends StatelessWidget {
  const StaffNotificationsScreen({
    super.key,
    required this.shift,
    required this.user,
  });

  final ShiftAssignment? shift;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifications',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (shift == null)
            const InfoCard(
              icon: Icons.event_busy_outlined,
              title: 'No roster assigned',
              subtitle:
                  'Your next shift will appear here after admin assigns it.',
              badge: StatusBadge(label: 'Roster', color: _muted),
            )
          else
            InfoCard(
              icon: Icons.calendar_month_outlined,
              title: 'New roster assigned',
              subtitle:
                  '${DateFormat('EEE, d MMM').format(shift!.startTime)} • ${_timeRange(shift!)}\n${shift!.serviceLocation}',
              badge: const StatusBadge(label: 'Roster', color: _scheduleBlue),
              onTap: () => openScreen(context, const StaffShiftDetailScreen()),
            ),
          const SizedBox(height: 12),
          const InfoCard(
            icon: Icons.health_and_safety_outlined,
            title: 'First aid certificate expires soon',
            subtitle:
                'Your First Aid certificate is due for renewal on 30 Jun 2026.',
            badge: StatusBadge(label: 'Action', color: Color(0xFFD37A18)),
          ),
          const SizedBox(height: 12),
          InfoCard(
            icon: Icons.verified_user_outlined,
            title: 'Profile active',
            subtitle:
                '${user.fullName} is active for rostering and care documentation.',
            badge: const StatusBadge(label: 'Current', color: _actionGreen),
          ),
        ],
      ),
    );
  }
}

class StaffAvailabilityScreen extends StatefulWidget {
  const StaffAvailabilityScreen({super.key});

  @override
  State<StaffAvailabilityScreen> createState() =>
      _StaffAvailabilityScreenState();
}

class _StaffAvailabilityScreenState extends State<StaffAvailabilityScreen> {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();
  final startController = TextEditingController();
  final endController = TextEditingController();
  final reasonController = TextEditingController();
  final unavailableBlocks = <_UnavailableBlock>[];

  @override
  void dispose() {
    dateController.dispose();
    startController.dispose();
    endController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      unavailableBlocks.insert(
        0,
        _UnavailableBlock(
          date: dateController.text.trim(),
          start: startController.text.trim(),
          end: endController.text.trim(),
          reason: reasonController.text.trim(),
        ),
      );
      dateController.clear();
      startController.clear();
      endController.clear();
      reasonController.clear();
    });
    showSnack(context, 'Unavailability sent to rostering.');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Availability',
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
                      'Add unavailability',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Let rostering know when you cannot accept shifts.',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AvailabilityField(
                      controller: dateController,
                      label: 'Date',
                      hint: '24 May 2026',
                      icon: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AvailabilityField(
                            controller: startController,
                            label: 'From',
                            hint: '9:00 AM',
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AvailabilityField(
                            controller: endController,
                            label: 'To',
                            hint: '5:00 PM',
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AvailabilityField(
                      controller: reasonController,
                      label: 'Reason',
                      hint: 'Class, appointment, personal leave',
                      icon: Icons.notes_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: submit,
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Submit unavailability'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: 'Submitted unavailability'),
            const SizedBox(height: 10),
            if (unavailableBlocks.isEmpty)
              const EmptyState(
                icon: Icons.event_available_outlined,
                message: 'No unavailability submitted yet.',
              )
            else
              ...unavailableBlocks.map(
                (block) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InfoCard(
                    icon: Icons.event_busy_outlined,
                    title: block.date,
                    subtitle: '${block.start} - ${block.end}\n${block.reason}',
                    badge: const StatusBadge(
                      label: 'Sent',
                      color: _actionGreen,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityField extends StatelessWidget {
  const _AvailabilityField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        hintText: hint,
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}

class _UnavailableBlock {
  const _UnavailableBlock({
    required this.date,
    required this.start,
    required this.end,
    required this.reason,
  });

  final String date;
  final String start;
  final String end;
  final String reason;
}

class StaffFormsScreen extends StatelessWidget {
  const StaffFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Care forms',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FormLinkCard(
            icon: Icons.notes_outlined,
            title: 'Progress note',
            subtitle: 'Record daily care activities and follow-up needs.',
            onTap: () => _openShiftAction(
              context,
              const _ShiftAction(
                'Progress note',
                Icons.notes_outlined,
                ProgressNoteScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormLinkCard(
            icon: Icons.report_problem_outlined,
            title: 'Incident report',
            subtitle: 'Submit an incident with optional photo evidence.',
            onTap: () => _openShiftAction(
              context,
              const _ShiftAction(
                'Incident report',
                Icons.report_problem_outlined,
                IncidentReportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormLinkCard(
            icon: Icons.warning_amber_outlined,
            title: 'Hazard report',
            subtitle: 'Report environmental risks and attach evidence.',
            onTap: () => _openShiftAction(
              context,
              const _ShiftAction(
                'Hazard report',
                Icons.warning_amber_outlined,
                HazardReportScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormLinkCard(
            icon: Icons.psychology_alt_outlined,
            title: 'Behaviour chart',
            subtitle: 'Record triggers, responses, and outcomes.',
            onTap: () => _openShiftAction(
              context,
              const _ShiftAction(
                'Behaviour chart',
                Icons.psychology_alt_outlined,
                BehaviourChartScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FormLinkCard(
            icon: Icons.folder_copy_outlined,
            title: 'My reports',
            subtitle: 'Review records submitted during your shifts.',
            onTap: () => openScreen(context, const MyReportsScreen()),
          ),
        ],
      ),
    );
  }
}

class StaffDocumentsScreen extends StatelessWidget {
  const StaffDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = CareScope.of(context).user;
    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return AppScaffold(
      title: 'My documents',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            icon: Icons.badge_outlined,
            title: user.fullName,
            subtitle: '${user.position}\n${user.email}',
            badge: const StatusBadge(label: 'Active', color: _actionGreen),
          ),
          const SizedBox(height: 12),
          const _DocumentListItem(
            icon: Icons.verified_user_outlined,
            title: 'NDIS worker screening',
            subtitle: 'Verified credential on file.',
            status: 'Current',
            color: _actionGreen,
          ),
          SizedBox(height: 12),
          const _DocumentListItem(
            icon: Icons.health_and_safety_outlined,
            title: 'First aid certificate',
            subtitle: 'Expires 18 Sep 2026.',
            status: 'Review',
            color: Color(0xFFD37A18),
          ),
          SizedBox(height: 12),
          const _DocumentListItem(
            icon: Icons.school_outlined,
            title: 'Mandatory training record',
            subtitle: 'Medication, infection control, and manual handling.',
            status: 'Complete',
            color: _scheduleBlue,
          ),
          SizedBox(height: 12),
          const _DocumentListItem(
            icon: Icons.description_outlined,
            title: 'Employment documents',
            subtitle: 'Contract, role description, and payroll forms.',
            status: 'Filed',
            color: Color(0xFF7C8790),
          ),
        ],
      ),
    );
  }
}

class DocumentHubScreen extends StatelessWidget {
  const DocumentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Document hub',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DocumentListItem(
            icon: Icons.menu_book_outlined,
            title: 'Care policies',
            subtitle: 'Incident response, privacy, infection control.',
            status: 'Updated',
            color: _scheduleBlue,
          ),
          SizedBox(height: 12),
          _DocumentListItem(
            icon: Icons.assignment_outlined,
            title: 'Shift procedures',
            subtitle: 'Clock-in, progress notes, handover, and escalation.',
            status: 'Read',
            color: _actionGreen,
          ),
          SizedBox(height: 12),
          _DocumentListItem(
            icon: Icons.emergency_outlined,
            title: 'Emergency contacts',
            subtitle: 'After-hours coordinator and service contacts.',
            status: 'Pinned',
            color: Color(0xFFC43D32),
          ),
          SizedBox(height: 12),
          _DocumentListItem(
            icon: Icons.folder_shared_outlined,
            title: 'Client resources',
            subtitle: 'Shared templates and support-plan guidance.',
            status: 'Shared',
            color: Color(0xFF7C8790),
          ),
        ],
      ),
    );
  }
}

class _DocumentListItem extends StatelessWidget {
  const _DocumentListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      badge: StatusBadge(label: status, color: color),
      onTap: () => showSnack(context, '$title opened.'),
    );
  }
}

class CareLocationOverviewScreen extends StatelessWidget {
  const CareLocationOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final shift = controller.shift;
    if (shift == null) {
      return const AppScaffold(
        title: 'Map & location',
        body: EmptyState(
          icon: Icons.map_outlined,
          message: 'No shift location has been assigned yet.',
        ),
      );
    }
    return AppScaffold(
      title: 'Map & location',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LocationMapCard(
            title: 'Care visit location',
            address: shift.serviceLocation,
            latitude: shift.assignedLatitude,
            longitude: shift.assignedLongitude,
            badge: StatusBadge(
              label: shift.checkInStatus,
              color: shift.isCheckedIn
                  ? const Color(0xFF327A60)
                  : const Color(0xFFD37A18),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: shift.isEnded
                ? null
                : () => openScreen(context, const GpsCheckInScreen()),
            icon: const Icon(Icons.my_location),
            label: const Text('Open GPS check-in'),
          ),
        ],
      ),
    );
  }
}

class StaffInfoScreen extends StatelessWidget {
  const StaffInfoScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [InfoCard(icon: icon, title: title, subtitle: message)],
      ),
    );
  }
}

class _FormLinkCard extends StatelessWidget {
  const _FormLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InfoCard(icon: icon, title: title, subtitle: subtitle, onTap: onTap);
  }
}

void _openShiftAction(BuildContext context, _ShiftAction action) {
  openScreen(context, action.screen);
}

IconData _reportIcon(String collection) {
  return switch (collection) {
    'incidentReports' => Icons.local_hospital_outlined,
    'hazardReports' => Icons.warning_amber_outlined,
    'behaviourCharts' => Icons.psychology_alt_outlined,
    'progressNotes' => Icons.notes_outlined,
    _ => Icons.folder_copy_outlined,
  };
}

String _timeRange(ShiftAssignment shift) {
  return '${DateFormat.jm().format(shift.startTime)} - ${DateFormat.jm().format(shift.endTime)}';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
