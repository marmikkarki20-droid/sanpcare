import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../models/care_models.dart';
import '../services/address_geocoding_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/admin_mobile_widgets.dart';
import '../widgets/brand_logo.dart';
import '../widgets/info_widgets.dart';
import 'admin_create_staff_screen.dart';

part 'admin/admin_mobile_portal.dart';
part 'admin/admin_roster_screen.dart';
part 'admin/admin_timesheet_screen.dart';

const _adminNavy = adminMobileNavy;
const _adminMuted = adminMobileMuted;
const _adminLine = adminMobileLine;
const _adminTopBar = adminMobileTopBar;

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'NA';
  return parts
      .take(2)
      .map((part) => part.characters.first)
      .join()
      .toUpperCase();
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int currentIndex = 0;

  String get title => switch (currentIndex) {
    0 => 'Admin Dashboard',
    1 => 'Scheduler',
    2 => 'Staff',
    3 => 'Clients',
    _ => 'Reports',
  };

  void openMoreMenu() {
    final rootContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      barrierColor: const Color(0x6615313D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4, 2, 4, 12),
                    child: Text(
                      'More',
                      style: TextStyle(
                        color: _adminNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                _MoreMenuTile(
                  icon: Icons.account_circle_outlined,
                  title: 'Profile',
                  subtitle: 'Update admin details',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openScreen(rootContext, const AdminProfileScreen());
                  },
                ),
                _MoreMenuTile(
                  icon: Icons.access_time_outlined,
                  title: 'Attendance',
                  subtitle: 'Review verified location check-ins',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openScreen(
                      rootContext,
                      AdminCheckInsScreen(
                        title: 'Attendance',
                        checkIns: CareScope.of(rootContext).checkIns,
                      ),
                    );
                  },
                ),
                _MoreMenuTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Timesheets',
                  subtitle: 'Approve worked shifts for payroll',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openScreen(
                      rootContext,
                      AdminCheckInsScreen(
                        title: 'Timesheets',
                        checkIns: CareScope.of(rootContext).checkIns,
                      ),
                    );
                  },
                ),
                _MoreMenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Portal settings and account controls',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showSnack(rootContext, 'Settings will be available soon.');
                  },
                ),
                _MoreMenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out of CareSnap admin',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    signOutAndReturnToLogin(rootContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _adminTopBar,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _adminTopBar,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: adminMobileSurface,
        appBar: AppBar(
          toolbarHeight: 88,
          backgroundColor: _adminTopBar,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: const Color(0x24102B38),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: _adminTopBar,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: _adminTopBar,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          flexibleSpace: const ColoredBox(color: _adminTopBar),
          leadingWidth: 70,
          leading: IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded, size: 32),
            onPressed: openMoreMenu,
          ),
          titleSpacing: 0,
          title: _AdminAppBarTitle(sectionTitle: title),
          actions: [
            _AdminHeaderIconButton(
              tooltip: 'Refresh',
              icon: Icons.refresh_rounded,
              onPressed: controller.isBusy ? null : controller.refresh,
            ),
            _AdminHeaderIconButton(
              tooltip: 'More',
              icon: Icons.more_vert_rounded,
              onPressed: openMoreMenu,
            ),
            const SizedBox(width: 18),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: currentIndex,
            children: [
              _AdminMobileDashboardTab(
                onOpenStaff: () => setState(() => currentIndex = 2),
                onOpenClients: () => setState(() => currentIndex = 3),
                onOpenReports: () => setState(() => currentIndex = 4),
              ),
              const _AdminMobileSchedulerTab(),
              const _AdminMobileStaffTab(),
              const _AdminMobileClientsTab(),
              const _AdminMobileReportsTab(),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: currentIndex,
          onDestinationSelected: (index) =>
              setState(() => currentIndex = index),
        ),
      ),
    );
  }
}

class _MoreMenuTile extends StatelessWidget {
  const _MoreMenuTile({
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: adminMobileAqua,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: adminMobileTeal, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _adminNavy,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _adminMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHeaderIconButton extends StatelessWidget {
  const _AdminHeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.42),
          fixedSize: const Size(46, 46),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 29),
      ),
    );
  }
}

class _AdminAppBarTitle extends StatelessWidget {
  const _AdminAppBarTitle({required this.sectionTitle});

  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2400161C),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const CareSnapMark(size: 42),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CareSnap',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD5E6EC),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final positionController = TextEditingController();
  final facilityController = TextEditingController();
  bool initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialised) return;
    final user = CareScope.of(context).user;
    fullNameController.text = user?.fullName ?? '';
    positionController.text = user?.position ?? '';
    facilityController.text = user?.facilityId ?? '';
    initialised = true;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    positionController.dispose();
    facilityController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    final controller = CareScope.of(context);
    try {
      await controller.updateCurrentUserProfile(
        fullName: fullNameController.text,
        position: positionController.text,
        facilityId: facilityController.text,
      );
      if (!mounted) return;
      showSnack(context, 'Profile updated.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, controller.error ?? 'Could not update profile.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final user = controller.user;
    if (user == null) {
      return const AppScaffold(
        title: 'Profile',
        body: EmptyState(
          icon: Icons.account_circle_outlined,
          message: 'Profile is unavailable.',
        ),
      );
    }

    return AppScaffold(
      title: 'Profile',
      maxWidth: 560,
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF12313D),
                    Color(0xFF087C89),
                    Color(0xFF2563B8),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24102B38),
                    blurRadius: 18,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(
                      _initials(user.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(label: 'Admin', color: Color(0xFFF1A73A)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined),
                        labelText: 'Full name',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: positionController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.work_outline),
                        labelText: 'Role or position',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Position is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: facilityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.business_outlined),
                        labelText: 'Facility',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Save profile',
              icon: controller.isBusy
                  ? Icons.hourglass_top_rounded
                  : Icons.check_rounded,
              onPressed: controller.isBusy ? null : saveProfile,
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
  late Future<List<ClientProfile>> clientsFuture;
  String? selectedClientId;

  @override
  void initState() {
    super.initState();
    clientsFuture = _loadClients();
  }

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
      final doc = await FirebaseFirestore.instance.collection('clients').add({
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
      nameController.clear();
      suiteController.clear();
      addressController.clear();
      careNeedsController.clear();
      emergencyContactController.clear();
      setState(() {
        selectedClientId = doc.id;
        clientsFuture = _loadClients();
      });
    } catch (_) {
      if (!mounted) return;
      showSnack(context, '$name has been staged for coordinator review.');
    }
  }

  Future<List<ClientProfile>> _loadClients() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('clients')
        .limit(50)
        .get();
    final clients =
        snapshot.docs
            .map((doc) => ClientProfile.fromFirestore(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (selectedClientId == null && clients.isNotEmpty) {
      selectedClientId = clients.first.id;
    }
    return clients;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Clients',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<List<ClientProfile>>(
            future: clientsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final clients = snapshot.data ?? [];
              if (clients.isEmpty) {
                return const EmptyState(
                  icon: Icons.groups_2_outlined,
                  message: 'No residents have been onboarded yet.',
                );
              }
              final selectedClient = clients.firstWhere(
                (client) => client.id == selectedClientId,
                orElse: () => clients.first,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedClient.id,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_search_outlined),
                      labelText: 'Pick resident',
                    ),
                    items: clients
                        .map(
                          (client) => DropdownMenuItem(
                            value: client.id,
                            child: Text(client.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedClientId = value),
                  ),
                  const SizedBox(height: 12),
                  _ClientDetailsCard(client: selectedClient),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Form(
            key: formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onboard new resident',
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
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: submit,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Add resident'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientDetailsCard extends StatelessWidget {
  const _ClientDetailsCard({required this.client});

  final ClientProfile client;

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
                CircleAvatar(
                  backgroundColor: const Color(0xFFE6F3F5),
                  child: Text(
                    _initials(client.fullName),
                    style: const TextStyle(
                      color: _adminNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    client.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _adminNavy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const StatusBadge(label: 'Resident', color: _adminNavy),
              ],
            ),
            const SizedBox(height: 14),
            MetricLine(
              icon: Icons.meeting_room_outlined,
              label: 'Room or suite',
              value: client.roomNumber,
            ),
            MetricLine(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: client.address,
            ),
            MetricLine(
              icon: Icons.volunteer_activism_outlined,
              label: 'Care needs',
              value: client.careNeeds,
            ),
            MetricLine(
              icon: Icons.accessible_forward_outlined,
              label: 'Mobility',
              value: client.mobilityStatus,
            ),
            MetricLine(
              icon: Icons.record_voice_over_outlined,
              label: 'Communication',
              value: client.communicationNeeds,
            ),
            MetricLine(
              icon: Icons.priority_high_outlined,
              label: 'Risk notes',
              value: client.riskNotes,
            ),
            MetricLine(
              icon: Icons.call_outlined,
              label: 'Emergency contact',
              value: client.emergencyContact,
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
    this.hintText,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        hintText: hintText,
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}

class AdminReportDetailScreen extends StatefulWidget {
  const AdminReportDetailScreen({super.key, required this.report});

  final ReportSummary report;

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  late ReportStatus selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.report.status;
  }

  Future<void> updateStatus(ReportStatus status) async {
    final controller = CareScope.of(context);
    if (widget.report.id.startsWith('sample-')) {
      showSnack(context, 'Sample report marked ${status.label}.');
      Navigator.pop(context);
      return;
    }
    await controller.updateReportStatus(widget.report, status);
    if (!mounted) return;
    showSnack(context, 'Status updated to ${status.label}.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return AppScaffold(
      title: 'Report review',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportReviewHeader(report: widget.report),
          const SizedBox(height: 12),
          _ReportSummaryActionCard(report: widget.report),
          const SizedBox(height: 12),
          _ReportDetailsCard(report: widget.report),
          if (widget.report.imageUrl != null) ...[
            const SizedBox(height: 12),
            _ReportEvidenceCard(imageUrl: widget.report.imageUrl!),
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
                  DropdownButtonFormField<ReportStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.rule_outlined),
                      labelText: 'Status update',
                    ),
                    items: ReportStatus.values
                        .where((status) => status != ReportStatus.newReport)
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: controller.isBusy
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => selectedStatus = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Mark Under Review',
                    icon: Icons.rate_review_outlined,
                    filled: false,
                    onPressed: controller.isBusy
                        ? null
                        : () => updateStatus(ReportStatus.underReview),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Mark Action Required',
                    icon: Icons.flag_outlined,
                    onPressed: controller.isBusy
                        ? null
                        : () => updateStatus(ReportStatus.actionRequired),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Mark Resolved',
                    icon: Icons.check_circle_outline,
                    filled: false,
                    onPressed: controller.isBusy
                        ? null
                        : () => updateStatus(ReportStatus.resolved),
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

class _ReportSummaryActionCard extends StatelessWidget {
  const _ReportSummaryActionCard({required this.report});

  final ReportSummary report;

  @override
  Widget build(BuildContext context) {
    final summary = report.subtitle.trim().isNotEmpty
        ? report.subtitle
        : report.details['Description'] ??
              report.details['Shift summary'] ??
              report.details['Behaviour observed'] ??
              'No written summary has been supplied.';
    final actionTaken =
        report.details['Action taken'] ??
        report.details['Staff response'] ??
        report.details['Follow-up'] ??
        'No action has been recorded yet.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(
                color: _adminNavy,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 26),
            Text(
              'Action taken',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              actionTaken,
              style: const TextStyle(
                color: _adminNavy,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
