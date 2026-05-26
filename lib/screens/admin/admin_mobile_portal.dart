part of '../admin_dashboard_screen.dart';

class _AdminMobileDashboardTab extends StatefulWidget {
  const _AdminMobileDashboardTab({
    required this.onOpenStaff,
    required this.onOpenClients,
    required this.onOpenReports,
  });

  final VoidCallback onOpenStaff;
  final VoidCallback onOpenClients;
  final VoidCallback onOpenReports;

  @override
  State<_AdminMobileDashboardTab> createState() =>
      _AdminMobileDashboardTabState();
}

class _AdminMobileDashboardTabState extends State<_AdminMobileDashboardTab> {
  late Future<List<_AdminRosterShift>> shiftsFuture;

  @override
  void initState() {
    super.initState();
    shiftsFuture = _loadAdminMobileRosterShifts();
  }

  Future<void> refresh() async {
    final controller = CareScope.of(context);
    await controller.refresh();
    final future = _loadAdminMobileRosterShifts();
    setState(() => shiftsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return FutureBuilder<List<_AdminRosterShift>>(
      future: shiftsFuture,
      builder: (context, snapshot) {
        final shifts = _withSampleShifts(snapshot.data ?? []);
        final reports = _withSampleReports(controller.reports);
        final todayShifts = shifts
            .where((shift) => _isToday(shift.startTime))
            .toList();
        final checkedInShifts = shifts
            .where((shift) => _mobileShiftStatus(shift).label == 'Checked In')
            .toList();
        final missedClockInShifts = shifts
            .where((shift) => _mobileShiftStatus(shift).label == 'Missed')
            .toList();
        final openIncidents = reports
            .where(
              (report) =>
                  report.collection == 'incidentReports' &&
                  report.status != ReportStatus.resolved,
            )
            .length;
        final hazardsUnderReview = reports
            .where(
              (report) =>
                  report.collection == 'hazardReports' &&
                  (report.status == ReportStatus.underReview ||
                      report.status == ReportStatus.actionRequired),
            )
            .length;
        final reviewReports = reports
            .where((report) => report.status != ReportStatus.resolved)
            .toList();
        final reportsPending = reviewReports.length;
        final behaviourChartsPending = reviewReports
            .where((report) => report.collection == 'behaviourCharts')
            .length;
        final attentionCount = missedClockInShifts.length + reportsPending;
        final alerts = _adminAlertsFrom(shifts, reports).take(3).toList();
        final checkInPreview = [
          ...checkedInShifts,
          ...missedClockInShifts,
        ].take(4).toList();

        void openTodayShifts() {
          openScreen(
            context,
            _AdminMobileShiftSummaryScreen(
              title: 'Today\'s Shifts',
              emptyMessage: 'No shifts scheduled for today.',
              shifts: todayShifts,
            ),
          );
        }

        void openCheckedInShifts() {
          openScreen(
            context,
            _AdminMobileShiftSummaryScreen(
              title: 'Staff Checked In',
              emptyMessage: 'No staff are checked in right now.',
              shifts: checkedInShifts,
            ),
          );
        }

        void openMissedClockIns() {
          openScreen(
            context,
            _AdminMobileShiftSummaryScreen(
              title: 'Missed Clock-ins',
              emptyMessage: 'No missed clock-ins.',
              shifts: missedClockInShifts,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useTwoPanels = constraints.maxWidth >= 680;
              final shiftPanel = _DashboardPanel(
                title: 'Today\'s Shifts',
                onViewAll: openTodayShifts,
                children: [
                  if (todayShifts.isEmpty)
                    const _CompactEmptyRow(
                      icon: Icons.event_busy_outlined,
                      message: 'No shifts scheduled for today.',
                    )
                  else
                    ...todayShifts
                        .take(3)
                        .map(
                          (shift) => _ShiftPreviewRow(
                            shift: shift,
                            status: _mobileShiftStatus(shift),
                            onTap: () => openScreen(
                              context,
                              const AdminAssignShiftScreen(),
                            ),
                          ),
                        ),
                  if (todayShifts.length > 3)
                    _MoreRowsFooter(
                      label: '+ ${todayShifts.length - 3} more shifts',
                      onTap: openTodayShifts,
                    ),
                ],
              );
              final checkInPanel = _DashboardPanel(
                title: 'Staff Check-ins',
                onViewAll: openCheckedInShifts,
                children: [
                  if (checkInPreview.isEmpty)
                    const _CompactEmptyRow(
                      icon: Icons.location_off_outlined,
                      message: 'No check-ins recorded yet.',
                    )
                  else
                    ...checkInPreview.map(
                      (shift) => _CheckInPreviewRow(
                        shift: shift,
                        status: _mobileShiftStatus(shift),
                        onTap: openCheckedInShifts,
                      ),
                    ),
                ],
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                children: [
                  _AdminMobileHero(
                    title: 'Today\'s Overview',
                    subtitle: DateFormat(
                      'EEEE, d MMMM yyyy',
                    ).format(DateTime.now()),
                    attentionCount: attentionCount,
                    onTap: widget.onOpenReports,
                  ),
                  const SizedBox(height: 18),
                  _DashboardSectionHeader(
                    title: 'Operations Summary',
                    onViewAll: widget.onOpenReports,
                  ),
                  const SizedBox(height: 10),
                  _OperationsSummaryGrid(
                    children: [
                      MobileDashboardCard(
                        title: 'Today\'s Shifts',
                        value: '${todayShifts.length}',
                        icon: Icons.calendar_today_rounded,
                        color: const Color(0xFF087CFF),
                        onTap: openTodayShifts,
                      ),
                      MobileDashboardCard(
                        title: 'Staff Checked In',
                        value: '${checkedInShifts.length}',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF0F9D58),
                        onTap: openCheckedInShifts,
                      ),
                      MobileDashboardCard(
                        title: 'Missed Clock-ins',
                        value: '${missedClockInShifts.length}',
                        icon: Icons.person_off_rounded,
                        color: const Color(0xFFE0001A),
                        onTap: openMissedClockIns,
                      ),
                      MobileDashboardCard(
                        title: 'Open Incidents',
                        value: '$openIncidents',
                        icon: Icons.warning_rounded,
                        color: const Color(0xFFE0001A),
                        onTap: widget.onOpenReports,
                      ),
                      MobileDashboardCard(
                        title: 'Hazards Under Review',
                        value: '$hazardsUnderReview',
                        icon: Icons.shield_rounded,
                        color: const Color(0xFFF57C00),
                        onTap: widget.onOpenReports,
                      ),
                      MobileDashboardCard(
                        title: 'Reports Pending',
                        value: '$reportsPending',
                        icon: Icons.description_rounded,
                        color: const Color(0xFF7E3FD6),
                        onTap: widget.onOpenReports,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DashboardSectionHeader(
                    title: 'Priority Alerts',
                    onViewAll: widget.onOpenReports,
                  ),
                  const SizedBox(height: 10),
                  _PriorityAlertsPanel(
                    alerts: alerts,
                    onTap: widget.onOpenReports,
                  ),
                  const SizedBox(height: 12),
                  if (useTwoPanels)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: shiftPanel),
                        const SizedBox(width: 16),
                        Expanded(child: checkInPanel),
                      ],
                    )
                  else ...[
                    shiftPanel,
                    const SizedBox(height: 12),
                    checkInPanel,
                  ],
                  const SizedBox(height: 18),
                  _DashboardSectionHeader(
                    title: 'Reports Needing Review',
                    onViewAll: widget.onOpenReports,
                  ),
                  const SizedBox(height: 10),
                  _ReportReviewSummaryCard(
                    incidentCount: openIncidents,
                    hazardCount: hazardsUnderReview,
                    behaviourCount: behaviourChartsPending,
                    onTap: widget.onOpenReports,
                  ),
                  const SizedBox(height: 18),
                  _DashboardSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 10),
                  AdminMobileGrid(
                    twoColumnMinWidth: null,
                    children: [
                      _QuickActionTile(
                        label: 'Add Staff',
                        subtitle: 'Create staff login',
                        icon: Icons.person_add_alt_1_rounded,
                        color: const Color(0xFF087C89),
                        onPressed: () =>
                            openScreen(context, const AdminCreateStaffScreen()),
                      ),
                      _QuickActionTile(
                        label: 'Add Client',
                        subtitle: 'New care profile',
                        icon: Icons.group_add_rounded,
                        color: const Color(0xFF2563B8),
                        onPressed: () => openScreen(
                          context,
                          const AdminResidentOnboardingScreen(),
                        ),
                      ),
                      _QuickActionTile(
                        label: 'Assign Shift',
                        subtitle: 'Roster a visit',
                        icon: Icons.add_task_rounded,
                        color: const Color(0xFF0F9D78),
                        onPressed: () =>
                            openScreen(context, const AdminAssignShiftScreen()),
                      ),
                      _QuickActionTile(
                        label: 'View Reports',
                        subtitle: 'Review records',
                        icon: Icons.assignment_rounded,
                        color: const Color(0xFFE08A1E),
                        onPressed: widget.onOpenReports,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AdminMobileSchedulerTab extends StatefulWidget {
  const _AdminMobileSchedulerTab();

  @override
  State<_AdminMobileSchedulerTab> createState() =>
      _AdminMobileSchedulerTabState();
}

class _AdminMobileSchedulerTabState extends State<_AdminMobileSchedulerTab> {
  late DateTime selectedDate;
  late Future<List<_AdminRosterShift>> shiftsFuture;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    shiftsFuture = _loadAdminMobileRosterShifts();
  }

  Future<void> refresh() async {
    final future = _loadAdminMobileRosterShifts();
    setState(() => shiftsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_AdminRosterShift>>(
      future: shiftsFuture,
      builder: (context, snapshot) {
        final shifts = _withSampleShifts(snapshot.data ?? []);
        final selectedShifts =
            shifts
                .where((shift) => _sameDay(shift.startTime, selectedDate))
                .toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _ScheduleDateSelector(
                selectedDate: selectedDate,
                onChanged: (value) => setState(() => selectedDate = value),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Add Shift',
                      icon: Icons.add_rounded,
                      onPressed: () =>
                          openScreen(context, const AdminAssignShiftScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Publish Shifts',
                      icon: Icons.send_outlined,
                      filled: false,
                      onPressed: () =>
                          showSnack(context, 'Shifts published to staff app.'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionHeader(
                title: DateFormat('EEEE, d MMM').format(selectedDate),
                trailing: StatusBadge(
                  label: '${selectedShifts.length} shifts',
                  color: const Color(0xFF087C89),
                ),
              ),
              const SizedBox(height: 10),
              if (selectedShifts.isEmpty)
                _MobileEmptyBlock(
                  icon: Icons.event_busy_outlined,
                  message: 'No shifts scheduled for this day.',
                )
              else
                ...selectedShifts.map((shift) {
                  final status = _mobileShiftStatus(shift);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShiftCard(
                      staffName: shift.staffName,
                      clientName: shift.clientName,
                      time: _timeRangeFromDates(shift.startTime, shift.endTime),
                      serviceType: shift.serviceType,
                      status: status.label,
                      statusColor: status.color,
                      location: shift.location,
                      onTap: () =>
                          openScreen(context, const AdminAssignShiftScreen()),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _AdminMobileStaffTab extends StatefulWidget {
  const _AdminMobileStaffTab();

  @override
  State<_AdminMobileStaffTab> createState() => _AdminMobileStaffTabState();
}

class _AdminMobileStaffTabState extends State<_AdminMobileStaffTab> {
  late Future<List<_AdminMobileStaffProfile>> staffFuture;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    staffFuture = _loadAdminMobileStaff();
  }

  Future<void> refresh() async {
    final future = _loadAdminMobileStaff();
    setState(() => staffFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_AdminMobileStaffProfile>>(
      future: staffFuture,
      builder: (context, snapshot) {
        final staff = _withSampleStaff(snapshot.data ?? []);
        final filtered = staff.where((person) {
          final haystack =
              '${person.name} ${person.role} ${person.email} ${person.status}'
                  .toLowerCase();
          return haystack.contains(searchText.trim().toLowerCase());
        }).toList();
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              CustomTextField(
                label: 'Search staff',
                hintText: 'Name, role, email, status',
                icon: Icons.search_rounded,
                onChanged: (value) => setState(() => searchText = value),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Add Staff',
                icon: Icons.person_add_alt_1_outlined,
                onPressed: () =>
                    openScreen(context, const AdminCreateStaffScreen()),
              ),
              const SizedBox(height: 18),
              SectionHeader(title: 'Staff team'),
              const SizedBox(height: 10),
              ...filtered.map(
                (person) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StaffCard(
                    name: person.name,
                    role: person.role,
                    contact: person.contactLabel,
                    availability: person.availability,
                    compliance: person.compliance,
                    status: person.status,
                    statusColor: person.statusColor,
                    onTap: () => openScreen(
                      context,
                      _AdminMobileStaffDetailsScreen(staff: person),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminMobileClientsTab extends StatefulWidget {
  const _AdminMobileClientsTab();

  @override
  State<_AdminMobileClientsTab> createState() => _AdminMobileClientsTabState();
}

class _AdminMobileClientsTabState extends State<_AdminMobileClientsTab> {
  late Future<List<_AdminMobileClientProfile>> clientsFuture;

  @override
  void initState() {
    super.initState();
    clientsFuture = _loadAdminMobileClients();
  }

  Future<void> refresh() async {
    final future = _loadAdminMobileClients();
    setState(() => clientsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_AdminMobileClientProfile>>(
      future: clientsFuture,
      builder: (context, snapshot) {
        final clients = _withSampleClients(snapshot.data ?? []);
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              PrimaryButton(
                label: 'Add Client',
                icon: Icons.group_add_outlined,
                onPressed: () =>
                    openScreen(context, const AdminResidentOnboardingScreen()),
              ),
              const SizedBox(height: 18),
              SectionHeader(title: 'Client profiles'),
              const SizedBox(height: 10),
              ...clients.map(
                (client) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClientCard(
                    name: client.name,
                    roomAddress: client.roomAddress,
                    fundingType: client.fundingType,
                    assignedStaff: client.assignedStaff,
                    nextShift: client.nextShift,
                    status: client.status,
                    statusColor: client.statusColor,
                    onTap: () => openScreen(
                      context,
                      _AdminMobileClientDetailsScreen(client: client),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminMobileReportsTab extends StatefulWidget {
  const _AdminMobileReportsTab();

  @override
  State<_AdminMobileReportsTab> createState() => _AdminMobileReportsTabState();
}

class _AdminMobileReportsTabState extends State<_AdminMobileReportsTab> {
  ReportStatus? statusFilter;

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final reports = _withSampleReports(controller.reports);
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Incident'),
                Tab(text: 'Hazard'),
                Tab(text: 'Behaviour'),
                Tab(text: 'Compliance'),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ReportFilterChip(
                    label: 'Submitted',
                    selected: statusFilter == ReportStatus.newReport,
                    onSelected: () => _toggleFilter(ReportStatus.newReport),
                  ),
                  _ReportFilterChip(
                    label: 'Under Review',
                    selected: statusFilter == ReportStatus.underReview,
                    onSelected: () => _toggleFilter(ReportStatus.underReview),
                  ),
                  _ReportFilterChip(
                    label: 'Action Required',
                    selected: statusFilter == ReportStatus.actionRequired,
                    onSelected: () =>
                        _toggleFilter(ReportStatus.actionRequired),
                  ),
                  _ReportFilterChip(
                    label: 'Resolved',
                    selected: statusFilter == ReportStatus.resolved,
                    onSelected: () => _toggleFilter(ReportStatus.resolved),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ReportCategoryList(
                  reports: _filterReports(reports, 'incidentReports'),
                ),
                _ReportCategoryList(
                  reports: _filterReports(reports, 'hazardReports'),
                ),
                _ReportCategoryList(
                  reports: _filterReports(reports, 'behaviourCharts'),
                ),
                _ReportCategoryList(
                  reports: _filterReports(reports, 'progressNotes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFilter(ReportStatus status) {
    setState(() {
      statusFilter = statusFilter == status ? null : status;
    });
  }

  List<ReportSummary> _filterReports(
    List<ReportSummary> reports,
    String collection,
  ) {
    return reports
        .where((report) => report.collection == collection)
        .where(
          (report) => statusFilter == null || report.status == statusFilter,
        )
        .toList();
  }
}

class _ReportCategoryList extends StatelessWidget {
  const _ReportCategoryList({required this.reports});

  final List<ReportSummary> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          _MobileEmptyBlock(
            icon: Icons.assignment_turned_in_outlined,
            message: 'No reports match this view.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = reports[index];
        return _reportCardFromSummary(
          context,
          report,
          onTap: () =>
              openScreen(context, AdminReportDetailScreen(report: report)),
        );
      },
    );
  }
}

class _AdminMobileShiftSummaryScreen extends StatelessWidget {
  const _AdminMobileShiftSummaryScreen({
    required this.title,
    required this.emptyMessage,
    required this.shifts,
  });

  final String title;
  final String emptyMessage;
  final List<_AdminRosterShift> shifts;

  @override
  Widget build(BuildContext context) {
    final sortedShifts = [...shifts]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return AppScaffold(
      title: title,
      maxWidth: 560,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (sortedShifts.isEmpty)
            _MobileEmptyBlock(
              icon: Icons.event_busy_outlined,
              message: emptyMessage,
            )
          else
            ...sortedShifts.map((shift) {
              final status = _mobileShiftStatus(shift);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShiftCard(
                  staffName: shift.staffName,
                  clientName: shift.clientName,
                  time: _timeRangeFromDates(shift.startTime, shift.endTime),
                  serviceType: shift.serviceType,
                  status: status.label,
                  statusColor: status.color,
                  location: shift.location,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AdminMobileStaffDetailsScreen extends StatelessWidget {
  const _AdminMobileStaffDetailsScreen({required this.staff});

  final _AdminMobileStaffProfile staff;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Staff details',
      maxWidth: 560,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            name: staff.name,
            subtitle: staff.role,
            badge: staff.status,
            badgeColor: staff.statusColor,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Contact details',
            children: [
              MetricLine(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: staff.phone,
              ),
              MetricLine(
                icon: Icons.mail_outline,
                label: 'Email',
                value: staff.email,
              ),
              MetricLine(
                icon: Icons.event_available_outlined,
                label: 'Availability',
                value: staff.availability,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Compliance summary',
            children: [
              MetricLine(
                icon: Icons.verified_user_outlined,
                label: 'Status',
                value: staff.compliance,
              ),
              const MetricLine(
                icon: Icons.policy_outlined,
                label: 'NDIS worker screening',
                value: 'Cleared',
              ),
              const MetricLine(
                icon: Icons.medical_services_outlined,
                label: 'First aid',
                value: 'Valid until Nov 2026',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Training/certificates',
            children: const [
              MetricLine(
                icon: Icons.workspace_premium_outlined,
                label: 'Medication assistance',
                value: 'Completed',
              ),
              MetricLine(
                icon: Icons.psychology_alt_outlined,
                label: 'Positive behaviour support',
                value: 'Due Aug 2026',
              ),
              MetricLine(
                icon: Icons.health_and_safety_outlined,
                label: 'Manual handling',
                value: 'Completed',
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<_AdminRosterShift>>(
            future: _loadAdminMobileStaffShifts(staff.id),
            builder: (context, snapshot) {
              final shifts = _withSampleShifts(snapshot.data ?? [])
                  .where(
                    (shift) =>
                        staff.id.isEmpty ||
                        shift.staffId == staff.id ||
                        shift.staffName == staff.name,
                  )
                  .take(3)
                  .toList();
              return _DetailCard(
                title: 'Assigned shifts',
                children: shifts
                    .map(
                      (shift) => MetricLine(
                        icon: Icons.calendar_month_outlined,
                        label: DateFormat('EEE d MMM').format(shift.startTime),
                        value:
                            '${shift.clientName}, ${_timeRangeFromDates(shift.startTime, shift.endTime)}',
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Recent attendance',
            children: const [
              MetricLine(
                icon: Icons.login_outlined,
                label: 'Last clock-in',
                value: 'Verified on site',
              ),
              MetricLine(
                icon: Icons.timer_outlined,
                label: 'This fortnight',
                value: '72.5 hours',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMobileClientDetailsScreen extends StatelessWidget {
  const _AdminMobileClientDetailsScreen({required this.client});

  final _AdminMobileClientProfile client;

  @override
  Widget build(BuildContext context) {
    final reports = _withSampleReports(CareScope.of(context).reports)
        .where(
          (report) =>
              report.clientId == client.id || report.clientName == client.name,
        )
        .take(3)
        .toList();
    return AppScaffold(
      title: 'Client details',
      maxWidth: 560,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            name: client.name,
            subtitle: client.roomAddress,
            badge: client.riskLevel,
            badgeColor: client.statusColor,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Care plan summary',
            children: [
              MetricLine(
                icon: Icons.volunteer_activism_outlined,
                label: 'Support focus',
                value: client.carePlan,
              ),
              MetricLine(
                icon: Icons.priority_high_outlined,
                label: 'Risk level',
                value: client.riskLevel,
              ),
              MetricLine(
                icon: Icons.calendar_today_outlined,
                label: 'Plan review due',
                value: client.planReviewDue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Assigned staff',
            children: [
              MetricLine(
                icon: Icons.groups_2_outlined,
                label: 'Primary team',
                value: client.assignedStaff,
              ),
              MetricLine(
                icon: Icons.event_outlined,
                label: 'Next shift',
                value: client.nextShift,
              ),
              MetricLine(
                icon: Icons.payments_outlined,
                label: 'Funding',
                value: client.fundingType,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Recent notes',
            children: const [
              MetricLine(
                icon: Icons.notes_outlined,
                label: 'Progress note',
                value: 'Community access completed with good engagement.',
              ),
              MetricLine(
                icon: Icons.restaurant_outlined,
                label: 'Meals/fluid',
                value: 'Lunch prepared with prompting.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Reports history',
            children: reports
                .map(
                  (report) => MetricLine(
                    icon: iconForReport(report.collection),
                    label: _adminReportCategory(report.collection),
                    value: DateFormat('d MMM').format(report.createdAt),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AdminMobileHero extends StatelessWidget {
  const _AdminMobileHero({
    required this.title,
    required this.subtitle,
    required this.attentionCount,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int attentionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attentionText = attentionCount == 1
        ? '1 item needs attention'
        : '$attentionCount items need attention';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _adminLine),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10102B38),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B7E91), Color(0xFF1BA0B4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: adminMobileTeal.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _adminNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Color(0xFFE0001A),
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            attentionText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE0001A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const StatusBadge(label: 'Live', color: Color(0xFF12A060)),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF486479),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  const _DashboardSectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _adminNavy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: adminMobileTeal,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('View all'),
          ),
      ],
    );
  }
}

class _OperationsSummaryGrid extends StatelessWidget {
  const _OperationsSummaryGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 6
            : constraints.maxWidth >= 520
            ? 3
            : 2;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _PriorityAlertsPanel extends StatelessWidget {
  const _PriorityAlertsPanel({required this.alerts, required this.onTap});

  final List<_AdminMobileAlert> alerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _adminLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C102B38),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < alerts.length; index++) ...[
            _AdminAlertTile(alert: alerts[index], onTap: onTap),
            if (index != alerts.length - 1)
              const Divider(height: 1, indent: 24, endIndent: 24),
          ],
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.onViewAll,
    required this.children,
  });

  final String title;
  final VoidCallback onViewAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _adminLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102B38),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _adminNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    foregroundColor: adminMobileTeal,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _ShiftPreviewRow extends StatelessWidget {
  const _ShiftPreviewRow({
    required this.shift,
    required this.status,
    required this.onTap,
  });

  final _AdminRosterShift shift;
  final _ShiftStatusView status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CompactDashboardRow(
      leading: _PersonAvatar(name: shift.staffName),
      title: shift.staffName,
      subtitle:
          '${shift.clientName}\n${_timeRangeFromDates(shift.startTime, shift.endTime)}',
      badge: StatusBadge(label: status.label, color: status.color),
      onTap: onTap,
    );
  }
}

class _CheckInPreviewRow extends StatelessWidget {
  const _CheckInPreviewRow({
    required this.shift,
    required this.status,
    required this.onTap,
  });

  final _AdminRosterShift shift;
  final _ShiftStatusView status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verified = status.label == 'Checked In';
    final badgeColor = verified ? const Color(0xFF12A060) : status.color;
    return _CompactDashboardRow(
      leading: _PersonAvatar(name: shift.staffName),
      title: shift.staffName,
      subtitle: DateFormat('h:mm a').format(shift.startTime),
      badge: StatusBadge(
        label: verified ? 'GPS Verified' : 'Not Verified',
        color: badgeColor,
      ),
      onTap: onTap,
    );
  }
}

class _CompactDashboardRow extends StatelessWidget {
  const _CompactDashboardRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _adminNavy,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF456077),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            badge,
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF486479),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE9F4F6),
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: _adminNavy,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactEmptyRow extends StatelessWidget {
  const _CompactEmptyRow({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: _adminMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _adminMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreRowsFooter extends StatelessWidget {
  const _MoreRowsFooter({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 13),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: adminMobileTeal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportReviewSummaryCard extends StatelessWidget {
  const _ReportReviewSummaryCard({
    required this.incidentCount,
    required this.hazardCount,
    required this.behaviourCount,
    required this.onTap,
  });

  final int incidentCount;
  final int hazardCount;
  final int behaviourCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _adminLine),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A102B38),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = [
                _ReportReviewMetric(
                  title: 'Incident Reports',
                  value: incidentCount,
                  subtitle: 'Under Review',
                  icon: Icons.report_problem_rounded,
                  color: const Color(0xFFE0001A),
                ),
                _ReportReviewMetric(
                  title: 'Hazard Reports',
                  value: hazardCount,
                  subtitle: 'Action Required',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFF57C00),
                ),
                _ReportReviewMetric(
                  title: 'Behaviour Charts',
                  value: behaviourCount,
                  subtitle: 'Pending',
                  icon: Icons.groups_2_rounded,
                  color: const Color(0xFF7E3FD6),
                ),
              ];

              if (constraints.maxWidth < 620) {
                return Column(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      metrics[index],
                      if (index != metrics.length - 1)
                        const Divider(height: 24),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var index = 0; index < metrics.length; index++) ...[
                    Expanded(child: metrics[index]),
                    if (index != metrics.length - 1)
                      const _VerticalMetricDivider(),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportReviewMetric extends StatelessWidget {
  const _ReportReviewMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _adminNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$value',
                style: const TextStyle(
                  color: _adminNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF456077),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerticalMetricDivider extends StatelessWidget {
  const _VerticalMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: _adminLine,
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _adminLine),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A14313D),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminNavy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleDateSelector extends StatelessWidget {
  const _ScheduleDateSelector({
    required this.selectedDate,
    required this.onChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous week',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () =>
                    onChanged(selectedDate.subtract(const Duration(days: 7))),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _adminNavy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next week',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () =>
                    onChanged(selectedDate.add(const Duration(days: 7))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: days.map((day) {
              final selected = _sameDay(day, selectedDate);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onChanged(day),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: selected
                            ? adminMobileTeal
                            : const Color(0xFFF5F8FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? adminMobileTeal : _adminLine,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(day),
                            style: TextStyle(
                              color: selected ? Colors.white : _adminMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: selected ? Colors.white : _adminNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ReportFilterChip extends StatelessWidget {
  const _ReportFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _AdminAlertTile extends StatelessWidget {
  const _AdminAlertTile({required this.alert, required this.onTap});

  final _AdminMobileAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AdminIconBadge(
                icon: alert.icon,
                color: alert.color,
                size: 42,
                innerSize: 28,
                iconSize: 17,
                borderAlpha: 0.12,
                innerRadius: 8,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminNavy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF456077),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(label: alert.badge, color: alert.color),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF486479),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  final String name;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFE6F3F5),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: _adminNavy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _adminNavy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _adminMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: badge, color: badgeColor),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (children.isEmpty)
              const Text(
                'No records available yet.',
                style: TextStyle(color: _adminMuted),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _MobileEmptyBlock extends StatelessWidget {
  const _MobileEmptyBlock({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _adminLine),
      ),
      child: Column(
        children: [
          Icon(icon, color: _adminMuted, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _adminMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMobileStaffProfile {
  const _AdminMobileStaffProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.availability,
    required this.compliance,
    required this.status,
    required this.statusColor,
  });

  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final String availability;
  final String compliance;
  final String status;
  final Color statusColor;

  String get contactLabel =>
      phone == 'Not recorded' ? email : '$phone • $email';
}

class _AdminMobileClientProfile {
  const _AdminMobileClientProfile({
    required this.id,
    required this.name,
    required this.roomAddress,
    required this.fundingType,
    required this.assignedStaff,
    required this.nextShift,
    required this.status,
    required this.statusColor,
    required this.carePlan,
    required this.riskLevel,
    required this.planReviewDue,
  });

  final String id;
  final String name;
  final String roomAddress;
  final String fundingType;
  final String assignedStaff;
  final String nextShift;
  final String status;
  final Color statusColor;
  final String carePlan;
  final String riskLevel;
  final String planReviewDue;
}

class _AdminMobileAlert {
  const _AdminMobileAlert({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
}

class _ShiftStatusView {
  const _ShiftStatusView(this.label, this.color);

  final String label;
  final Color color;
}

Future<List<_AdminRosterShift>> _loadAdminMobileRosterShifts() async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('shifts').limit(100).get();
  final shifts = await Future.wait(
    snapshot.docs.map((doc) => _adminRosterShiftFromDoc(firestore, doc)),
  );
  shifts.sort((a, b) => a.startTime.compareTo(b.startTime));
  return shifts;
}

Future<List<_AdminRosterShift>> _loadAdminMobileStaffShifts(
  String staffId,
) async {
  if (staffId.isEmpty || staffId.startsWith('sample-')) return [];
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore
      .collection('shifts')
      .where('staffId', isEqualTo: staffId)
      .limit(20)
      .get();
  final shifts = await Future.wait(
    snapshot.docs.map(
      (doc) => _adminRosterShiftFromDoc(
        firestore,
        doc,
        staffNameOverride: 'Assigned staff',
      ),
    ),
  );
  shifts.sort((a, b) => a.startTime.compareTo(b.startTime));
  return shifts;
}

Future<_AdminRosterShift> _adminRosterShiftFromDoc(
  FirebaseFirestore firestore,
  QueryDocumentSnapshot<Map<String, dynamic>> doc, {
  String? staffNameOverride,
}) async {
  final data = doc.data();
  final staffId = data['staffId'] as String? ?? '';
  final clientId = data['clientId'] as String? ?? '';
  final staffName =
      staffNameOverride ??
      await _adminMobileNameFor(firestore, 'users', staffId);
  final clientName = await _adminMobileNameFor(firestore, 'clients', clientId);

  return _AdminRosterShift(
    id: doc.id,
    staffId: staffId,
    clientId: clientId,
    staffName:
        staffName ?? (staffId.isEmpty ? 'Vacant shift' : 'Assigned staff'),
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
}

Future<List<_AdminMobileStaffProfile>> _loadAdminMobileStaff() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'staff')
      .limit(80)
      .get();
  final staff = snapshot.docs.map((doc) {
    final user = AppUser.fromFirestore(doc.id, doc.data());
    return _AdminMobileStaffProfile(
      id: user.id,
      name: user.fullName,
      role: user.position,
      email: user.email,
      phone: doc.data()['phone'] as String? ?? 'Not recorded',
      availability: doc.data()['availability'] as String? ?? 'Available today',
      compliance: doc.data()['compliance'] as String? ?? 'Compliant',
      status: user.isActive ? 'Active' : 'On Leave',
      statusColor: user.isActive
          ? const Color(0xFF1B9B73)
          : const Color(0xFF7C8790),
    );
  }).toList()..sort((a, b) => a.name.compareTo(b.name));
  return staff;
}

Future<List<_AdminMobileClientProfile>> _loadAdminMobileClients() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('clients')
      .limit(80)
      .get();
  final clients = snapshot.docs.map((doc) {
    final client = ClientProfile.fromFirestore(doc.id, doc.data());
    return _AdminMobileClientProfile(
      id: client.id,
      name: client.fullName,
      roomAddress: '${client.roomNumber} • ${client.address}',
      fundingType: doc.data()['fundingType'] as String? ?? 'NDIS Core Supports',
      assignedStaff:
          doc.data()['assignedStaff'] as String? ?? 'CareSnap support team',
      nextShift: doc.data()['nextShift'] as String? ?? 'Next rostered visit',
      status: doc.data()['status'] as String? ?? 'Active',
      statusColor: const Color(0xFF1B9B73),
      carePlan: client.careNeeds.isEmpty
          ? 'Daily living, community access, and medication prompts'
          : client.careNeeds,
      riskLevel: client.riskNotes.toLowerCase().contains('high')
          ? 'High risk'
          : 'Medium risk',
      planReviewDue:
          doc.data()['planReviewDue'] as String? ??
          DateFormat(
            'd MMM yyyy',
          ).format(DateTime.now().add(const Duration(days: 58))),
    );
  }).toList()..sort((a, b) => a.name.compareTo(b.name));
  return clients;
}

Future<String?> _adminMobileNameFor(
  FirebaseFirestore firestore,
  String collection,
  String id,
) async {
  if (id.isEmpty) return null;
  final doc = await firestore.collection(collection).doc(id).get();
  return doc.data()?['fullName'] as String?;
}

List<_AdminRosterShift> _withSampleShifts(List<_AdminRosterShift> shifts) {
  if (shifts.isNotEmpty) return shifts;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    _AdminRosterShift(
      id: 'sample-shift-1',
      staffId: 'sample-staff-1',
      clientId: 'sample-client-1',
      staffName: 'Marmik Shrestha',
      clientName: 'Avery Nguyen',
      startTime: today.add(const Duration(hours: 7)),
      endTime: today.add(const Duration(hours: 15)),
      location: 'Harbourview Supported Living, Suite 12',
      serviceType: 'Personal care',
      status: 'Started',
      checkInStatus: 'Verified',
    ),
    _AdminRosterShift(
      id: 'sample-shift-2',
      staffId: 'sample-staff-2',
      clientId: 'sample-client-2',
      staffName: 'Priya Rana',
      clientName: 'Noah Williams',
      startTime: today.add(const Duration(hours: 14)),
      endTime: today.add(const Duration(hours: 22)),
      location: '5 Fussell Lane, Gungahlin',
      serviceType: 'Community access',
      status: 'Scheduled',
      checkInStatus: 'Pending',
    ),
    _AdminRosterShift(
      id: 'sample-shift-3',
      staffId: 'sample-staff-3',
      clientId: 'sample-client-3',
      staffName: 'Jasmine Lee',
      clientName: 'Lila Carter',
      startTime: today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 9)),
      endTime: today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 13)),
      location: 'Canberra Community Hub',
      serviceType: 'Shopping support',
      status: 'Ended',
      checkInStatus: 'Verified',
    ),
    _AdminRosterShift(
      id: 'sample-shift-4',
      staffId: 'sample-staff-4',
      clientId: 'sample-client-4',
      staffName: 'Daniel Okafor',
      clientName: 'Mia Thompson',
      startTime: today.subtract(const Duration(hours: 3)),
      endTime: today.add(const Duration(hours: 2)),
      location: 'Belconnen SIL House',
      serviceType: 'Medication prompt',
      status: 'Scheduled',
      checkInStatus: 'Pending',
    ),
  ];
}

List<_AdminMobileStaffProfile> _withSampleStaff(
  List<_AdminMobileStaffProfile> staff,
) {
  if (staff.isNotEmpty) return staff;
  return const [
    _AdminMobileStaffProfile(
      id: 'sample-staff-1',
      name: 'Marmik Shrestha',
      role: 'Disability Support Worker',
      email: 'marmik@caresnap.com',
      phone: '0402 184 331',
      availability: 'Available today, 7 AM - 3 PM',
      compliance: 'All checks current',
      status: 'Active',
      statusColor: Color(0xFF1B9B73),
    ),
    _AdminMobileStaffProfile(
      id: 'sample-staff-2',
      name: 'Priya Rana',
      role: 'Senior Support Worker',
      email: 'priya@caresnap.com',
      phone: '0411 908 227',
      availability: 'Afternoon shifts',
      compliance: 'First aid due in 45 days',
      status: 'Active',
      statusColor: Color(0xFF1B9B73),
    ),
    _AdminMobileStaffProfile(
      id: 'sample-staff-4',
      name: 'Daniel Okafor',
      role: 'Community Access Worker',
      email: 'daniel@caresnap.com',
      phone: '0493 775 102',
      availability: 'Available weekdays',
      compliance: 'Manual handling current',
      status: 'Missing Clock-in',
      statusColor: Color(0xFFC43D32),
    ),
  ];
}

List<_AdminMobileClientProfile> _withSampleClients(
  List<_AdminMobileClientProfile> clients,
) {
  if (clients.isNotEmpty) return clients;
  final reviewDate = DateFormat(
    'd MMM yyyy',
  ).format(DateTime.now().add(const Duration(days: 42)));
  return [
    _AdminMobileClientProfile(
      id: 'sample-client-1',
      name: 'Avery Nguyen',
      roomAddress: 'Suite 12 • Harbourview Supported Living',
      fundingType: 'NDIS Core Supports',
      assignedStaff: 'Marmik Shrestha, Priya Rana',
      nextShift: 'Today, 7:00 AM - 3:00 PM',
      status: 'Active',
      statusColor: const Color(0xFF1B9B73),
      carePlan: 'Personal care, meals, medication prompts, and social support',
      riskLevel: 'Medium risk',
      planReviewDue: reviewDate,
    ),
    _AdminMobileClientProfile(
      id: 'sample-client-2',
      name: 'Noah Williams',
      roomAddress: '5 Fussell Lane • Gungahlin',
      fundingType: 'SIL daily living',
      assignedStaff: 'Priya Rana',
      nextShift: 'Today, 2:00 PM - 10:00 PM',
      status: 'Active',
      statusColor: const Color(0xFF1B9B73),
      carePlan: 'Community access, shopping, and meal preparation',
      riskLevel: 'Low risk',
      planReviewDue: reviewDate,
    ),
    _AdminMobileClientProfile(
      id: 'sample-client-3',
      name: 'Lila Carter',
      roomAddress: 'Room 4 • Belconnen SIL House',
      fundingType: 'Capacity building',
      assignedStaff: 'Jasmine Lee',
      nextShift: 'Tomorrow, 9:00 AM - 1:00 PM',
      status: 'Plan Review',
      statusColor: const Color(0xFFE08A1E),
      carePlan: 'Behaviour support, skill building, and transport assistance',
      riskLevel: 'High risk',
      planReviewDue: reviewDate,
    ),
  ];
}

List<ReportSummary> _withSampleReports(List<ReportSummary> reports) {
  if (reports.isNotEmpty) return reports;
  final now = DateTime.now();
  return [
    ReportSummary(
      id: 'sample-incident-1',
      collection: 'incidentReports',
      title: 'Incident: Medication refusal',
      subtitle: 'Client declined evening medication prompt.',
      staffId: 'sample-staff-2',
      clientId: 'sample-client-2',
      status: ReportStatus.actionRequired,
      createdAt: now.subtract(const Duration(hours: 2)),
      staffName: 'Priya Rana',
      clientName: 'Noah Williams',
      details: const {
        'Report type': 'Medication incident',
        'Description': 'Medication was offered as per support plan.',
        'Action taken': 'Supervisor notified and family contact documented.',
        'Severity': 'High',
      },
    ),
    ReportSummary(
      id: 'sample-hazard-1',
      collection: 'hazardReports',
      title: 'Hazard: Wet bathroom floor',
      subtitle: 'Slip risk identified during morning support.',
      staffId: 'sample-staff-1',
      clientId: 'sample-client-1',
      status: ReportStatus.underReview,
      createdAt: now.subtract(const Duration(hours: 5)),
      staffName: 'Marmik Shrestha',
      clientName: 'Avery Nguyen',
      details: const {
        'Report type': 'Environmental hazard',
        'Risk level': 'Medium',
        'Description': 'Bathroom floor remained wet after shower support.',
        'Action taken': 'Area dried and maintenance request raised.',
      },
    ),
    ReportSummary(
      id: 'sample-behaviour-1',
      collection: 'behaviourCharts',
      title: 'Behaviour chart',
      subtitle: 'Verbal escalation during community access.',
      staffId: 'sample-staff-3',
      clientId: 'sample-client-3',
      status: ReportStatus.newReport,
      createdAt: now.subtract(const Duration(days: 1)),
      staffName: 'Jasmine Lee',
      clientName: 'Lila Carter',
      details: const {
        'Trigger': 'Unexpected change to shopping plan',
        'Behaviour observed': 'Raised voice and refusal to leave vehicle',
        'Staff response': 'Used calm redirection and offered choices',
        'Severity': 'Medium',
      },
    ),
    ReportSummary(
      id: 'sample-compliance-1',
      collection: 'progressNotes',
      title: 'Progress note',
      subtitle: 'Daily living support completed.',
      staffId: 'sample-staff-1',
      clientId: 'sample-client-1',
      status: ReportStatus.resolved,
      createdAt: now.subtract(const Duration(days: 2)),
      staffName: 'Marmik Shrestha',
      clientName: 'Avery Nguyen',
      details: const {
        'Shift summary': 'Personal care and meal support completed.',
        'Activities': 'Laundry, lunch preparation, and short walk.',
        'Severity': 'Routine',
      },
    ),
  ];
}

List<_AdminMobileAlert> _adminAlertsFrom(
  List<_AdminRosterShift> shifts,
  List<ReportSummary> reports,
) {
  final missed = shifts.where(
    (shift) => _mobileShiftStatus(shift).label == 'Missed',
  );
  final actionReports = reports.where(
    (report) => report.status == ReportStatus.actionRequired,
  );
  final underReview = reports.where(
    (report) => report.status == ReportStatus.underReview,
  );

  final alerts = <_AdminMobileAlert>[
    for (final shift in missed)
      _AdminMobileAlert(
        icon: Icons.timer_off_rounded,
        title: '${shift.staffName} missed clock-in',
        subtitle:
            '${shift.clientName} • ${_timeRangeFromDates(shift.startTime, shift.endTime)}',
        badge: 'Missed',
        color: const Color(0xFFC43D32),
      ),
    for (final report in actionReports)
      _AdminMobileAlert(
        icon: Icons.priority_high_rounded,
        title: report.title,
        subtitle: report.clientName ?? report.subtitle,
        badge: 'Action',
        color: const Color(0xFFC43D32),
      ),
    for (final report in underReview)
      _AdminMobileAlert(
        icon: Icons.rate_review_rounded,
        title: report.title,
        subtitle: report.clientName ?? report.subtitle,
        badge: 'Review',
        color: const Color(0xFFE08A1E),
      ),
  ];
  if (alerts.isNotEmpty) return alerts;
  return const [
    _AdminMobileAlert(
      icon: Icons.verified_rounded,
      title: 'All active shifts are covered',
      subtitle: 'No missed clock-ins requiring attention.',
      badge: 'Clear',
      color: Color(0xFF1B9B73),
    ),
  ];
}

Widget _reportCardFromSummary(
  BuildContext context,
  ReportSummary report, {
  required VoidCallback onTap,
}) {
  return ReportCard(
    reportNumber: _reportNumber(report),
    category: _adminReportCategory(report.collection),
    clientName: report.clientName ?? 'Client not linked',
    staffName: report.staffName ?? 'Staff not linked',
    dateTime: DateFormat('d MMM yyyy, h:mm a').format(report.createdAt),
    severity: _reportSeverity(report),
    status: _adminReportStatusLabel(report.status),
    statusColor: report.status.color,
    hasPhoto: report.imageUrl?.trim().isNotEmpty ?? false,
    onTap: onTap,
  );
}

_ShiftStatusView _mobileShiftStatus(_AdminRosterShift shift) {
  if (shift.isEnded) {
    return const _ShiftStatusView('Completed', Color(0xFF607783));
  }
  if (shift.isStarted || shift.checkInStatus == 'Verified') {
    return const _ShiftStatusView('Checked In', Color(0xFF1B9B73));
  }
  final graceTime = shift.startTime.add(const Duration(minutes: 30));
  if (DateTime.now().isAfter(graceTime)) {
    return const _ShiftStatusView('Missed', Color(0xFFC43D32));
  }
  return const _ShiftStatusView('Scheduled', Color(0xFF2868D9));
}

String _adminReportStatusLabel(ReportStatus status) {
  return status == ReportStatus.newReport ? 'Submitted' : status.label;
}

String _adminReportCategory(String collection) {
  return switch (collection) {
    'incidentReports' => 'Incident',
    'hazardReports' => 'Hazard',
    'behaviourCharts' => 'Behaviour',
    'progressNotes' => 'Compliance',
    _ => 'Compliance',
  };
}

String _reportNumber(ReportSummary report) {
  final prefix = switch (report.collection) {
    'incidentReports' => 'INC',
    'hazardReports' => 'HAZ',
    'behaviourCharts' => 'BEH',
    _ => 'COM',
  };
  final id = report.id.length >= 4 ? report.id.substring(0, 4) : report.id;
  return '$prefix-${report.createdAt.year}-${id.toUpperCase()}';
}

String _reportSeverity(ReportSummary report) {
  return report.details['Severity'] ??
      report.details['Risk level'] ??
      (report.status == ReportStatus.actionRequired ? 'High' : 'Routine');
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
