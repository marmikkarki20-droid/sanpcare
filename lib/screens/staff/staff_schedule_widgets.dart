part of '../staff_dashboard_screen.dart';

class StaffScheduleTimeline extends StatelessWidget {
  const StaffScheduleTimeline({
    super.key,
    required this.selectedDate,
    required this.scheduleDates,
    required this.shift,
    required this.client,
    required this.onRefresh,
    required this.onOpenShift,
  });

  final DateTime selectedDate;
  final List<DateTime> scheduleDates;
  final ShiftAssignment? shift;
  final ClientProfile? client;
  final RefreshCallback onRefresh;
  final VoidCallback onOpenShift;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WeekStrip(selectedDate: selectedDate),
        const _DownCue(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                ...scheduleDates.map((date) {
                  final assignedShift = shift;
                  final assignedClient = client;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _ScheduleDayRow(
                      date: date,
                      child:
                          assignedShift != null &&
                              assignedClient != null &&
                              _isSameDay(date, assignedShift.startTime)
                          ? _RosterShiftCard(
                              shift: assignedShift,
                              client: assignedClient,
                              onTap: onOpenShift,
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

class _IconTextLine extends StatelessWidget {
  const _IconTextLine({
    required this.icon,
    required this.text,
    this.iconColor = _muted,
    this.textColor = _ink,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
