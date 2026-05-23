part of '../admin_dashboard_screen.dart';

class AdminCheckInsScreen extends StatefulWidget {
  const AdminCheckInsScreen({
    super.key,
    required this.title,
    required this.checkIns,
  });

  final String title;
  final List<CheckInRecord> checkIns;

  @override
  State<AdminCheckInsScreen> createState() => _AdminCheckInsScreenState();
}

class _AdminCheckInsScreenState extends State<AdminCheckInsScreen> {
  late Future<List<_TimesheetEntry>> entriesFuture;

  @override
  void initState() {
    super.initState();
    entriesFuture = _loadEntries();
  }

  @override
  void didUpdateWidget(covariant AdminCheckInsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkIns != widget.checkIns) {
      entriesFuture = _loadEntries();
    }
  }

  Future<List<_TimesheetEntry>> _loadEntries() async {
    if (widget.checkIns.isEmpty) return [];
    final firestore = FirebaseFirestore.instance;
    final entries = await Future.wait(
      widget.checkIns.map((record) async {
        final staffName =
            await _nameFor(firestore, 'users', record.staffId) ??
            'Staff member';
        var clientName = 'Resident';
        var serviceType = 'Care visit';
        var location = 'Service location';
        DateTime? startTime;
        DateTime? endTime;

        if (record.shiftId.isNotEmpty) {
          final shift = await firestore
              .collection('shifts')
              .doc(record.shiftId)
              .get();
          final data = shift.data();
          if (data != null) {
            final clientId = data['clientId'] as String? ?? '';
            clientName =
                await _nameFor(firestore, 'clients', clientId) ?? clientName;
            serviceType = data['serviceType'] as String? ?? serviceType;
            location = data['serviceLocation'] as String? ?? location;
            startTime = dateFromFirestore(data['startTime']);
            endTime = dateFromFirestore(data['endTime']);
          }
        }

        return _TimesheetEntry(
          record: record,
          staffName: staffName,
          clientName: clientName,
          serviceType: serviceType,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
      }),
    );
    entries.sort((a, b) => b.record.createdAt.compareTo(a.record.createdAt));
    return entries;
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

  Future<void> refreshEntries() async {
    final future = _loadEntries();
    setState(() => entriesFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      body: FutureBuilder<List<_TimesheetEntry>>(
        future: entriesFuture,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: refreshEntries,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _TimesheetSummaryCard(entries: entries),
                const SizedBox(height: 16),
                SectionHeader(
                  title: 'Clock-in records',
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: refreshEntries,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (entries.isEmpty)
                  const EmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    message:
                        'No staff timesheet records have been submitted yet.',
                  )
                else
                  ...entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TimesheetRecordCard(entry: entry),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimesheetEntry {
  const _TimesheetEntry({
    required this.record,
    required this.staffName,
    required this.clientName,
    required this.serviceType,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  final CheckInRecord record;
  final String staffName;
  final String clientName;
  final String serviceType;
  final String location;
  final DateTime? startTime;
  final DateTime? endTime;
}

class _TimesheetSummaryCard extends StatelessWidget {
  const _TimesheetSummaryCard({required this.entries});

  final List<_TimesheetEntry> entries;

  @override
  Widget build(BuildContext context) {
    final verified = entries
        .where((entry) => entry.record.status == 'Verified')
        .length;
    final exceptions = entries.length - verified;
    final averageDistance = entries.isEmpty
        ? 0
        : entries
                  .map((entry) => entry.record.distanceMetres)
                  .reduce((a, b) => a + b) /
              entries.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _adminNavy,
        borderRadius: BorderRadius.circular(8),
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
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Timesheet review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TimesheetMetric(label: 'Records', value: '${entries.length}'),
              _TimesheetMetric(label: 'Verified', value: '$verified'),
              _TimesheetMetric(label: 'Exceptions', value: '$exceptions'),
              _TimesheetMetric(
                label: 'Avg distance',
                value: '${averageDistance.toStringAsFixed(0)} m',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimesheetMetric extends StatelessWidget {
  const _TimesheetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimesheetRecordCard extends StatelessWidget {
  const _TimesheetRecordCard({required this.entry});

  final _TimesheetEntry entry;

  @override
  Widget build(BuildContext context) {
    final verified = entry.record.status == 'Verified';
    final color = verified ? const Color(0xFF1B9B73) : const Color(0xFFC43D32);
    final shiftTime = entry.startTime == null || entry.endTime == null
        ? 'Shift time pending'
        : _timeRangeFromDates(entry.startTime!, entry.endTime!);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => _TimesheetDetailSheet(entry: entry),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _adminLine),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  _initials(entry.staffName),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
                            entry.staffName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _adminNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        StatusBadge(label: entry.record.status, color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.serviceType} • ${entry.clientName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _adminMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TimesheetLine(
                      icon: Icons.schedule_outlined,
                      label:
                          '${DateFormat('d MMM, h:mm a').format(entry.record.createdAt)} • $shiftTime',
                    ),
                    const SizedBox(height: 5),
                    _TimesheetLine(
                      icon: Icons.near_me_outlined,
                      label:
                          '${entry.record.distanceMetres.toStringAsFixed(0)} m from assigned location',
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

class _TimesheetLine extends StatelessWidget {
  const _TimesheetLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _adminMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _adminMuted,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimesheetDetailSheet extends StatelessWidget {
  const _TimesheetDetailSheet({required this.entry});

  final _TimesheetEntry entry;

  @override
  Widget build(BuildContext context) {
    final shiftTime = entry.startTime == null || entry.endTime == null
        ? 'Shift time pending'
        : _timeRangeFromDates(entry.startTime!, entry.endTime!);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.staffName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _adminNavy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _TimesheetDetailRow(label: 'Resident', value: entry.clientName),
            _TimesheetDetailRow(label: 'Shift', value: shiftTime),
            _TimesheetDetailRow(label: 'Service', value: entry.serviceType),
            _TimesheetDetailRow(label: 'Location', value: entry.location),
            _TimesheetDetailRow(
              label: 'Clock-in',
              value: DateFormat(
                'd MMM yyyy, h:mm a',
              ).format(entry.record.createdAt),
            ),
            _TimesheetDetailRow(
              label: 'Distance',
              value:
                  '${entry.record.distanceMetres.toStringAsFixed(0)} m from assigned location',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimesheetDetailRow extends StatelessWidget {
  const _TimesheetDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: _adminMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _adminNavy,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
