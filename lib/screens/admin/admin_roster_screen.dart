part of '../admin_dashboard_screen.dart';

class AdminRosteringScreen extends StatefulWidget {
  const AdminRosteringScreen({super.key});

  @override
  State<AdminRosteringScreen> createState() => _AdminRosteringScreenState();
}

class _AdminRosteringScreenState extends State<AdminRosteringScreen> {
  late Future<List<_AdminRosterShift>> shiftsFuture;

  @override
  void initState() {
    super.initState();
    shiftsFuture = _loadRosterShifts();
  }

  Future<List<_AdminRosterShift>> _loadRosterShifts() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('shifts').limit(80).get();
    final shifts = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final staffId = data['staffId'] as String? ?? '';
        final clientId = data['clientId'] as String? ?? '';
        final staffName = await _nameFor(firestore, 'users', staffId);
        final clientName = await _nameFor(firestore, 'clients', clientId);
        return _AdminRosterShift(
          id: doc.id,
          staffId: staffId,
          clientId: clientId,
          staffName:
              staffName ??
              (staffId.isEmpty ? 'Vacant shift' : 'Assigned staff'),
          clientName: clientName ?? 'Resident',
          startTime: dateFromFirestore(data['startTime']) ?? DateTime.now(),
          endTime:
              dateFromFirestore(data['endTime']) ??
              DateTime.now().add(const Duration(hours: 1)),
          location: data['serviceLocation'] as String? ?? 'Service location',
          serviceType: data['serviceType'] as String? ?? 'Care visit',
          status: data['shiftStatus'] as String? ?? 'Scheduled',
          checkInStatus: data['checkInStatus'] as String? ?? 'Pending',
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
    return doc.data()?['fullName'] as String?;
  }

  Future<void> refreshShifts() async {
    final future = _loadRosterShifts();
    setState(() => shiftsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final activeStaff = controller.checkIns
        .where((record) => record.status == 'Verified')
        .length;
    final reportsNeedingAction = controller.reports
        .where((report) => report.status == ReportStatus.actionRequired)
        .length;
    return AppScaffold(
      title: 'Rostering',
      body: FutureBuilder<List<_AdminRosterShift>>(
        future: shiftsFuture,
        builder: (context, snapshot) {
          final shifts = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          return RefreshIndicator(
            onRefresh: refreshShifts,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _RosterOverviewCard(
                  shifts: shifts,
                  activeStaff: activeStaff,
                  actionRequired: reportsNeedingAction,
                  onAssignShift: () =>
                      openScreen(context, const AdminAssignShiftScreen()),
                  onRefresh: refreshShifts,
                ),
                const SizedBox(height: 14),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _AdminSchedulerBoard(
                    shifts: shifts,
                    onVacantShift: () =>
                        openScreen(context, const AdminAssignShiftScreen()),
                    onAssignStaff: () =>
                        openScreen(context, const AdminAssignShiftScreen()),
                    onClientList: () => openScreen(
                      context,
                      const AdminResidentOnboardingScreen(),
                    ),
                    onRefresh: refreshShifts,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminRosterShift {
  const _AdminRosterShift({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.staffName,
    required this.clientName,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.serviceType,
    required this.status,
    required this.checkInStatus,
  });

  final String id;
  final String staffId;
  final String clientId;
  final String staffName;
  final String clientName;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String serviceType;
  final String status;
  final String checkInStatus;

  bool get isVacant => staffId.isEmpty;
  bool get isStarted => status == 'Started';
  bool get isEnded => status == 'Ended';
}

class _RosterOverviewCard extends StatelessWidget {
  const _RosterOverviewCard({
    required this.shifts,
    required this.activeStaff,
    required this.actionRequired,
    required this.onAssignShift,
    required this.onRefresh,
  });

  final List<_AdminRosterShift> shifts;
  final int activeStaff;
  final int actionRequired;
  final VoidCallback onAssignShift;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final vacant = shifts.where((shift) => shift.isVacant).length;
    final today = shifts.where((shift) => _isToday(shift.startTime)).length;
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF2868D9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF2868D9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roster control',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _adminNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('EEE, d MMM').format(DateTime.now()),
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh roster',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _RosterMetric(
                label: 'Today',
                value: '$today',
                color: const Color(0xFF2868D9),
              ),
              _RosterMetric(
                label: 'Total shifts',
                value: '${shifts.length}',
                color: const Color(0xFF087C89),
              ),
              _RosterMetric(
                label: 'Vacant',
                value: '$vacant',
                color: vacant > 0
                    ? const Color(0xFFC43D32)
                    : const Color(0xFF327A60),
              ),
              _RosterMetric(
                label: 'Checked in',
                value: '$activeStaff',
                color: const Color(0xFF1B9B73),
              ),
              _RosterMetric(
                label: 'Follow-ups',
                value: '$actionRequired',
                color: actionRequired > 0
                    ? const Color(0xFFC43D32)
                    : const Color(0xFF7357C8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAssignShift,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Assign staff to shift'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterMetric extends StatelessWidget {
  const _RosterMetric({
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
      width: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _AdminSchedulerBoard extends StatelessWidget {
  const _AdminSchedulerBoard({
    required this.shifts,
    required this.onVacantShift,
    required this.onAssignStaff,
    required this.onClientList,
    required this.onRefresh,
  });

  final List<_AdminRosterShift> shifts;
  final VoidCallback onVacantShift;
  final VoidCallback onAssignStaff;
  final VoidCallback onClientList;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<_AdminRosterShift>>{};
    for (final shift in shifts) {
      final day = DateTime(
        shift.startTime.year,
        shift.startTime.month,
        shift.startTime.day,
      );
      grouped.putIfAbsent(day, () => []).add(shift);
    }
    final days = grouped.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
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
                const Icon(
                  Icons.view_week_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Weekly scheduler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _SchedulerIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: onRefresh,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                _AdminFilterChip(
                  label: 'SIL accommodation',
                  onTap: onClientList,
                ),
                _AdminFilterChip(label: 'All staff', onTap: onAssignStaff),
                _AdminFilterChip(label: 'Open shifts', onTap: onVacantShift),
                _AdminFilterChip(
                  label: 'Weekly',
                  onTap: () => showSnack(context, 'Weekly roster selected.'),
                ),
              ],
            ),
          ),
          if (shifts.isEmpty)
            _RosterEmptyState(onAssignShift: onVacantShift)
          else
            ...days.map((day) {
              final dayShifts = grouped[day]!
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
              return _RosterDaySection(
                date: day,
                shifts: dayShifts,
                onShiftTap: onAssignStaff,
                onVacantTap: onVacantShift,
              );
            }),
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
        width: 36,
        height: 36,
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

class _RosterDaySection extends StatelessWidget {
  const _RosterDaySection({
    required this.date,
    required this.shifts,
    required this.onShiftTap,
    required this.onVacantTap,
  });

  final DateTime date;
  final List<_AdminRosterShift> shifts;
  final VoidCallback onShiftTap;
  final VoidCallback onVacantTap;

  @override
  Widget build(BuildContext context) {
    final vacant = shifts.where((shift) => shift.isVacant).length;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _adminLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _isToday(date)
                        ? const Color(0xFFE9F5F7)
                        : const Color(0xFFF5F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _adminLine),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: const TextStyle(
                          color: _adminMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: const TextStyle(
                          color: _adminNavy,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(date),
                    style: const TextStyle(
                      color: _adminNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusBadge(
                  label: vacant > 0 ? '$vacant vacant' : '${shifts.length}',
                  color: vacant > 0
                      ? const Color(0xFFC43D32)
                      : const Color(0xFF327A60),
                ),
              ],
            ),
          ),
          ...shifts.map(
            (shift) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: _RosterShiftTile(
                shift: shift,
                onTap: shift.isVacant ? onVacantTap : onShiftTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterShiftTile extends StatelessWidget {
  const _RosterShiftTile({required this.shift, required this.onTap});

  final _AdminRosterShift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = shift.isVacant
        ? const Color(0xFFC43D32)
        : shift.isEnded
        ? const Color(0xFF7C8790)
        : shift.isStarted
        ? const Color(0xFF1B9B73)
        : const Color(0xFF2868D9);
    final status = shift.isVacant
        ? 'Vacant'
        : shift.isStarted
        ? 'In progress'
        : shift.isEnded
        ? 'Completed'
        : shift.status;

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: color,
                child: Text(
                  _initials(shift.isVacant ? 'Vacant' : shift.staffName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _timeRangeFromDates(shift.startTime, shift.endTime),
                            style: const TextStyle(
                              color: _adminNavy,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        StatusBadge(label: status, color: color),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      shift.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shift.serviceType} • ${shift.staffName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: _adminMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shift.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _adminMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: _adminMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterEmptyState extends StatelessWidget {
  const _RosterEmptyState({required this.onAssignShift});

  final VoidCallback onAssignShift;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Card(
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
                child: const Icon(
                  Icons.event_busy_outlined,
                  size: 30,
                  color: Color(0xFF6F8791),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No shifts have been scheduled yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF536E7A)),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAssignShift,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create first shift'),
              ),
            ],
          ),
        ),
      ),
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
  final staffEmailController = TextEditingController();
  final clientNameController = TextEditingController();
  final serviceTypeController = TextEditingController(text: 'Personal care');
  final dateController = TextEditingController();
  final startController = TextEditingController();
  final endController = TextEditingController();
  final locationController = TextEditingController();
  bool isSaving = false;

  @override
  void dispose() {
    staffEmailController.dispose();
    clientNameController.dispose();
    serviceTypeController.dispose();
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
        'serviceType': serviceTypeController.text.trim(),
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
                        color: _adminNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create a staff shift that appears in the staff schedule.',
                      style: TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w600,
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
                      label: 'Resident name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: serviceTypeController,
                      label: 'Shift type',
                      icon: Icons.volunteer_activism_outlined,
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: dateController,
                      label: 'Date  YYYY-MM-DD',
                      icon: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AdminTextField(
                            controller: startController,
                            label: 'Start  HH:mm',
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AdminTextField(
                            controller: endController,
                            label: 'End  HH:mm',
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AdminTextField(
                      controller: locationController,
                      label: 'Service address',
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

String _timeRangeFromDates(DateTime start, DateTime end) {
  return '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}';
}

bool _isToday(DateTime value) {
  final now = DateTime.now();
  return value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
}
