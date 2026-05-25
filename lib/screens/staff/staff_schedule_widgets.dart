part of '../staff_dashboard_screen.dart';

class StaffScheduleTimeline extends StatefulWidget {
  const StaffScheduleTimeline({
    super.key,
    required this.selectedDate,
    required this.scheduleDates,
    required this.shifts,
    required this.clientsById,
    required this.calendarExpanded,
    required this.onRefresh,
    required this.onDateSelected,
    required this.onToggleCalendar,
    required this.onCloseCalendar,
    required this.onOpenShift,
  });

  final DateTime selectedDate;
  final List<DateTime> scheduleDates;
  final List<ShiftAssignment> shifts;
  final Map<String, ClientProfile> clientsById;
  final bool calendarExpanded;
  final RefreshCallback onRefresh;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onToggleCalendar;
  final VoidCallback onCloseCalendar;
  final ValueChanged<ShiftAssignment> onOpenShift;

  @override
  State<StaffScheduleTimeline> createState() => _StaffScheduleTimelineState();
}

class _StaffScheduleTimelineState extends State<StaffScheduleTimeline> {
  static const _estimatedRowHeight = 94.0;

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(
      initialScrollOffset: _selectedIndex() * _estimatedRowHeight,
    );
  }

  @override
  void didUpdateWidget(covariant StaffScheduleTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _selectedIndex() {
    final index = widget.scheduleDates.indexWhere(
      (date) => _isSameDay(date, widget.selectedDate),
    );
    return index < 0 ? 0 : index;
  }

  void _jumpToSelected() {
    if (!_controller.hasClients) return;
    final target = _selectedIndex() * _estimatedRowHeight;
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftDates = widget.shifts
        .map((shift) => _dateOnly(shift.startTime))
        .toSet();

    return Column(
      children: [
        _WeekStrip(
          selectedDate: widget.selectedDate,
          shiftDates: shiftDates,
          onDateSelected: widget.onDateSelected,
        ),
        _DownCue(
          expanded: widget.calendarExpanded,
          onPressed: widget.onToggleCalendar,
        ),
        Expanded(
          child: widget.calendarExpanded
              ? _InlineScheduleCalendar(
                  selectedDate: widget.selectedDate,
                  shiftDates: shiftDates,
                  onDateSelected: widget.onDateSelected,
                  onClose: widget.onCloseCalendar,
                )
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: ListView.builder(
                    controller: _controller,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    itemCount: widget.scheduleDates.length,
                    itemBuilder: (context, index) {
                      final date = widget.scheduleDates[index];
                      final shiftsForDate =
                          widget.shifts
                              .where(
                                (shift) => _isSameDay(date, shift.startTime),
                              )
                              .toList()
                            ..sort(
                              (a, b) => a.startTime.compareTo(b.startTime),
                            );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _ScheduleDayRow(
                          date: date,
                          selected: _isSameDay(date, widget.selectedDate),
                          onDateTap: () => widget.onDateSelected(date),
                          child: shiftsForDate.isEmpty
                              ? const _NoShiftCard()
                              : Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < shiftsForDate.length;
                                      i++
                                    ) ...[
                                      _RosterShiftCard(
                                        shift: shiftsForDate[i],
                                        client:
                                            widget.clientsById[shiftsForDate[i]
                                                .clientId],
                                        onTap: () => widget.onOpenShift(
                                          shiftsForDate[i],
                                        ),
                                      ),
                                      if (i != shiftsForDate.length - 1)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selectedDate,
    required this.shiftDates,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final Set<DateTime> shiftDates;
  final ValueChanged<DateTime> onDateSelected;

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
          final hasShift = shiftDates.contains(_dateOnly(day));
          return Expanded(
            child: Tooltip(
              message: DateFormat('EEEE, d MMMM').format(day),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onDateSelected(day),
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
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DownCue extends StatelessWidget {
  const _DownCue({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 34,
        child: IconButton(
          tooltip: expanded ? 'Close calendar' : 'Open calendar',
          padding: EdgeInsets.zero,
          icon: Icon(
            expanded
                ? Icons.keyboard_double_arrow_up_rounded
                : Icons.keyboard_double_arrow_down_rounded,
            size: 34,
            color: _scheduleBlue,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _InlineScheduleCalendar extends StatelessWidget {
  const _InlineScheduleCalendar({
    required this.selectedDate,
    required this.shiftDates,
    required this.onDateSelected,
    required this.onClose,
  });

  final DateTime selectedDate;
  final Set<DateTime> shiftDates;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final firstMonth = DateTime(selectedDate.year, selectedDate.month);
    final secondMonth = DateTime(selectedDate.year, selectedDate.month + 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        _CalendarMonth(
          month: firstMonth,
          selectedDate: selectedDate,
          shiftDates: shiftDates,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: 28),
        _CalendarMonth(
          month: secondMonth,
          selectedDate: selectedDate,
          shiftDates: shiftDates,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Close calendar'),
          ),
        ),
      ],
    );
  }
}

class _CalendarMonth extends StatelessWidget {
  const _CalendarMonth({
    required this.month,
    required this.selectedDate,
    required this.shiftDates,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final Set<DateTime> shiftDates;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = monthStart.weekday % DateTime.daysPerWeek;
    final cellCount = leadingBlanks + daysInMonth;

    return Column(
      children: [
        Text(
          DateFormat('MMMM yyyy').format(monthStart),
          style: const TextStyle(
            color: _muted,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ((cellCount + 6) ~/ 7) * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 58,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(month.year, month.month, dayNumber);
            final selected = _isSameDay(date, selectedDate);
            final hasShift = shiftDates.contains(_dateOnly(date));

            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onDateSelected(date),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? _scheduleBlue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: selected ? Colors.white : _ink,
                        fontSize: 19,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
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
          },
        ),
      ],
    );
  }
}

class _ScheduleDayRow extends StatelessWidget {
  const _ScheduleDayRow({
    required this.date,
    required this.child,
    required this.selected,
    required this.onDateTap,
  });

  final DateTime date;
  final Widget child;
  final bool selected;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onDateTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: selected ? _scheduleBlue : _ink,
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: selected ? _scheduleBlue : _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
  final ClientProfile? client;
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
                text: client?.fullName ?? 'Assigned client',
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
