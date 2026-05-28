import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../controllers/care_controller.dart' show CheckInResult;
import '../core/navigation.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/info_widgets.dart';
import '../widgets/location_map_card.dart';

class GpsCheckInScreen extends StatefulWidget {
  const GpsCheckInScreen({super.key});

  @override
  State<GpsCheckInScreen> createState() => _GpsCheckInScreenState();
}

class _GpsCheckInScreenState extends State<GpsCheckInScreen> {
  CheckInResult? result;
  bool resultWasCheckOut = false;

  Future<void> runVerification() async {
    final controller = CareScope.of(context);
    final shift = controller.shift;
    if (shift == null) return;
    final checkingOut = shift.isCheckedIn && !shift.isEnded;
    try {
      final nextResult = checkingOut
          ? await controller.performLiveCheckOut()
          : await controller.performLiveCheckIn();
      setState(() {
        result = nextResult;
        resultWasCheckOut = checkingOut;
      });
    } catch (_) {
      if (mounted) {
        showSnack(context, controller.error ?? 'Could not update attendance.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final shift = controller.shift;
    if (shift == null) {
      return const AppScaffold(
        title: 'Verify location',
        body: EmptyState(
          icon: Icons.location_off_outlined,
          message: 'No shift location has been assigned yet.',
        ),
      );
    }
    final activeResult = result;
    final checkedIn = shift.isCheckedIn;
    final ended = shift.isEnded;
    final checkingOut = checkedIn && !ended;
    final verificationPassed = activeResult?.verified ?? false;
    final attendanceBlockReason = controller.attendanceBlockReason(shift);
    final attendanceBlocked = attendanceBlockReason != null;

    return AppScaffold(
      title: 'Verify location',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeResult == null)
            LocationMapCard(
              title: 'Assigned care visit location',
              address: shift.serviceLocation,
              latitude: shift.assignedLatitude,
              longitude: shift.assignedLongitude,
              badge: StatusBadge(
                label: attendanceBlocked
                    ? 'Failed'
                    : ended
                    ? 'Clocked out'
                    : checkedIn
                    ? 'Clocked in'
                    : shift.checkInStatus == 'Failed'
                    ? 'Location failed'
                    : 'Pending',
                color: attendanceBlocked
                    ? const Color(0xFFC43D32)
                    : checkedIn || ended
                    ? const Color(0xFF327A60)
                    : shift.checkInStatus == 'Failed'
                    ? const Color(0xFFC43D32)
                    : const Color(0xFFD37A18),
              ),
            )
          else
            LiveLocationMapCard(
              assignedAddress: shift.serviceLocation,
              assignedLatitude: shift.assignedLatitude,
              assignedLongitude: shift.assignedLongitude,
              currentLatitude: activeResult.latitude,
              currentLongitude: activeResult.longitude,
              distanceMetres: activeResult.distanceMetres,
              accuracyMetres: activeResult.accuracyMetres,
              verified: activeResult.verified,
            ),
          const SizedBox(height: 16),
          if (activeResult != null)
            _CheckInResultCard(
              result: activeResult,
              isCheckOut: resultWasCheckOut,
            )
          else if (attendanceBlocked)
            InfoCard(
              icon: checkingOut
                  ? Icons.logout_outlined
                  : Icons.event_busy_outlined,
              title: checkingOut ? 'Clock out failed' : 'Clock in failed',
              subtitle: attendanceBlockReason,
              badge: const StatusBadge(
                label: 'Failed',
                color: Color(0xFFC43D32),
              ),
            )
          else if (ended)
            InfoCard(
              icon: Icons.task_alt_outlined,
              title: 'Clocked out',
              subtitle: '',
              badge: const StatusBadge(
                label: 'Clocked out',
                color: Color(0xFF327A60),
              ),
            )
          else if (checkedIn)
            InfoCard(
              icon: Icons.logout_outlined,
              title: 'Clock out',
              subtitle: '',
              badge: const StatusBadge(
                label: 'Clocked in',
                color: Color(0xFF327A60),
              ),
            )
          else
            InfoCard(
              icon: Icons.location_searching,
              title: 'Clock in',
              subtitle: '',
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                controller.isBusy ||
                    attendanceBlocked ||
                    (ended && !verificationPassed)
                ? null
                : verificationPassed
                ? () => Navigator.of(context).pop(true)
                : runVerification,
            icon: controller.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    verificationPassed
                        ? Icons.check_circle_outline
                        : activeResult == null
                        ? Icons.map_outlined
                        : Icons.refresh_rounded,
                  ),
            label: Text(
              verificationPassed
                  ? resultWasCheckOut
                        ? 'Finish clock out'
                        : 'Continue to shift'
                  : ended
                  ? 'Clocked out'
                  : attendanceBlocked
                  ? checkingOut
                        ? 'Clock out failed'
                        : 'Clock in failed'
                  : activeResult != null
                  ? 'Check again'
                  : checkingOut
                  ? 'Verify location'
                  : 'Verify location',
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInResultCard extends StatelessWidget {
  const _CheckInResultCard({required this.result, required this.isCheckOut});

  final CheckInResult result;
  final bool isCheckOut;

  @override
  Widget build(BuildContext context) {
    final verified = result.verified;
    return InfoCard(
      icon: verified ? Icons.verified_outlined : Icons.location_off_outlined,
      title: verified
          ? isCheckOut
                ? 'Clocked out'
                : 'Clocked in'
          : 'Location failed',
      subtitle: '',
      badge: StatusBadge(
        label: verified
            ? isCheckOut
                  ? 'Clocked out'
                  : 'Clocked in'
            : 'Failed',
        color: verified ? const Color(0xFF327A60) : const Color(0xFFC43D32),
      ),
    );
  }
}
