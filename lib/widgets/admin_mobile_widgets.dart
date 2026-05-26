import 'package:flutter/material.dart';

import 'info_widgets.dart';

const adminMobileNavy = Color(0xFF06183D);
const adminMobileTopBar = Color(0xFF02323E);
const adminMobileTeal = Color(0xFF087C89);
const adminMobileAqua = Color(0xFFE4F7F7);
const adminMobileSurface = Color(0xFFF7FAFC);
const adminMobileMuted = Color(0xFF516A82);
const adminMobileLine = Color(0xFFE1E8EF);
const adminMobileShadow = Color(0x0D14313D);

class MobileDashboardCard extends StatelessWidget {
  const MobileDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 140,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: adminMobileLine),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F102B38),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 31),
                const SizedBox(height: 14),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: adminMobileNavy,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminMobileNavy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: adminMobileMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminIconBadge extends StatelessWidget {
  const AdminIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
    this.innerSize = 25,
    this.iconSize = 16,
    this.borderAlpha = 0.16,
    this.innerRadius = 7,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double innerSize;
  final double iconSize;
  final double borderAlpha;
  final double innerRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: borderAlpha)),
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class AdminMobileGrid extends StatelessWidget {
  const AdminMobileGrid({
    super.key,
    required this.children,
    this.spacing = 10,
    this.twoColumnMinWidth = 340,
  });

  final List<Widget> children;
  final double spacing;
  final double? twoColumnMinWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns =
            twoColumnMinWidth == null ||
            constraints.maxWidth >= twoColumnMinWidth!;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
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

class ShiftCard extends StatelessWidget {
  const ShiftCard({
    super.key,
    required this.staffName,
    required this.clientName,
    required this.time,
    required this.serviceType,
    required this.status,
    required this.statusColor,
    this.location,
    this.onTap,
  });

  final String staffName;
  final String clientName;
  final String time;
  final String serviceType;
  final String status;
  final Color statusColor;
  final String? location;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _MobileListCard(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.event_available_rounded,
          color: statusColor,
          size: 21,
        ),
      ),
      title: clientName,
      subtitle: staffName,
      badge: StatusBadge(label: status, color: statusColor),
      children: [
        _CardLine(icon: Icons.access_time_rounded, text: time),
        _CardLine(icon: Icons.volunteer_activism_outlined, text: serviceType),
        if (location != null && location!.trim().isNotEmpty)
          _CardLine(icon: Icons.location_on_outlined, text: location!),
      ],
    );
  }
}

class StaffCard extends StatelessWidget {
  const StaffCard({
    super.key,
    required this.name,
    required this.role,
    required this.contact,
    required this.availability,
    required this.compliance,
    required this.status,
    required this.statusColor,
    this.onTap,
  });

  final String name;
  final String role;
  final String contact;
  final String availability;
  final String compliance;
  final String status;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _MobileListCard(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: adminMobileAqua,
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: adminMobileNavy,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: name,
      subtitle: role,
      badge: StatusBadge(label: status, color: statusColor),
      children: [
        _CardLine(icon: Icons.mail_outline_rounded, text: contact),
        _CardLine(icon: Icons.calendar_today_outlined, text: availability),
        _CardLine(icon: Icons.verified_user_outlined, text: compliance),
      ],
    );
  }
}

class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.name,
    required this.roomAddress,
    required this.fundingType,
    required this.assignedStaff,
    required this.nextShift,
    required this.status,
    required this.statusColor,
    this.onTap,
  });

  final String name;
  final String roomAddress;
  final String fundingType;
  final String assignedStaff;
  final String nextShift;
  final String status;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _MobileListCard(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Text(
          _initials(name),
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
        ),
      ),
      title: name,
      subtitle: roomAddress,
      badge: StatusBadge(label: status, color: statusColor),
      children: [
        _CardLine(icon: Icons.payments_outlined, text: fundingType),
        _CardLine(icon: Icons.groups_2_outlined, text: assignedStaff),
        _CardLine(icon: Icons.event_outlined, text: nextShift),
      ],
    );
  }
}

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.reportNumber,
    required this.category,
    required this.clientName,
    required this.staffName,
    required this.dateTime,
    required this.severity,
    required this.status,
    required this.statusColor,
    this.hasPhoto = false,
    this.onTap,
  });

  final String reportNumber;
  final String category;
  final String clientName;
  final String staffName;
  final String dateTime;
  final String severity;
  final String status;
  final Color statusColor;
  final bool hasPhoto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _MobileListCard(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(_reportIcon(category), color: statusColor, size: 21),
      ),
      title: reportNumber,
      subtitle: category,
      badge: StatusBadge(label: status, color: statusColor),
      children: [
        _CardLine(icon: Icons.person_outline_rounded, text: clientName),
        _CardLine(icon: Icons.badge_outlined, text: staffName),
        _CardLine(icon: Icons.schedule_outlined, text: dateTime),
        _CardLine(icon: Icons.priority_high_outlined, text: severity),
        if (hasPhoto)
          const _CardLine(
            icon: Icons.photo_camera_outlined,
            text: 'Photo attached',
          ),
      ],
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      _AdminBottomNavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
      ),
      _AdminBottomNavItem(
        label: 'Scheduler',
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note_rounded,
      ),
      _AdminBottomNavItem(
        label: 'Staff',
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings_rounded,
      ),
      _AdminBottomNavItem(
        label: 'Clients',
        icon: Icons.diversity_3_outlined,
        selectedIcon: Icons.diversity_3_rounded,
      ),
      _AdminBottomNavItem(
        label: 'Reports',
        icon: Icons.assignment_turned_in_outlined,
        selectedIcon: Icons.assignment_turned_in_rounded,
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: adminMobileTopBar,
        border: Border(top: BorderSide(color: Color(0x338CE6EA))),
        boxShadow: [
          BoxShadow(
            color: Color(0x24102B38),
            blurRadius: 22,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _AdminBottomNavButton(
                    item: items[index],
                    selected: index == currentIndex,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBottomNavItem {
  const _AdminBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _AdminBottomNavButton extends StatelessWidget {
  const _AdminBottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _AdminBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: selected ? 46 : 40,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected ? adminMobileTopBar : Colors.white,
                  size: selected ? 21 : 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.82),
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: adminMobileTeal),
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: adminMobileTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: adminMobileNavy,
          side: const BorderSide(color: adminMobileLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: child,
      ),
    );
  }
}

class _MobileListCard extends StatelessWidget {
  const _MobileListCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.children,
    this.badge,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminMobileLine),
            boxShadow: const [
              BoxShadow(
                color: adminMobileShadow,
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: adminMobileNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: adminMobileMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 8), badge!],
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _CardLine extends StatelessWidget {
  const _CardLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: adminMobileMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: adminMobileNavy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'CS';
  return parts.take(2).map((part) => part.characters.first).join();
}

IconData _reportIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('hazard')) return Icons.warning_amber_outlined;
  if (value.contains('behaviour')) return Icons.psychology_alt_outlined;
  if (value.contains('compliance')) return Icons.verified_user_outlined;
  return Icons.report_problem_outlined;
}
