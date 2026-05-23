import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../controllers/care_controller.dart';
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

  Future<void> runCheckIn() async {
    final controller = CareScope.of(context);
    try {
      final nextResult = await controller.performLiveCheckIn();
      setState(() => result = nextResult);
    } catch (_) {
      if (mounted) {
        showSnack(context, controller.error ?? 'Unable to check location.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    final shift = controller.shift;
    if (shift == null) {
      return const AppScaffold(
        title: 'GPS check-in',
        body: EmptyState(
          icon: Icons.location_off_outlined,
          message: 'No shift location has been assigned yet.',
        ),
      );
    }
    final activeResult = result;
    final checkedIn = shift.isCheckedIn;

    return AppScaffold(
      title: 'GPS check-in',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LocationMapCard(
            title: 'Assigned care visit location',
            address: shift.serviceLocation,
            latitude: shift.assignedLatitude,
            longitude: shift.assignedLongitude,
            badge: StatusBadge(
              label: shift.checkInStatus,
              color: checkedIn
                  ? const Color(0xFF327A60)
                  : const Color(0xFFD37A18),
            ),
          ),
          const SizedBox(height: 16),
          if (activeResult != null)
            _CheckInResultCard(result: activeResult)
          else if (checkedIn)
            InfoCard(
              icon: Icons.verified_outlined,
              title: 'Shift started successfully.',
              subtitle: 'You are checked in at the assigned location.',
              badge: const StatusBadge(
                label: 'Checked In',
                color: Color(0xFF327A60),
              ),
            )
          else
            const InfoCard(
              icon: Icons.location_searching,
              title: 'Ready to verify location',
              subtitle:
                  'GPS will compare this device location with the assigned shift location.',
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.isBusy || checkedIn ? null : runCheckIn,
            icon: controller.isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Verify live GPS'),
          ),
        ],
      ),
    );
  }
}

class _CheckInResultCard extends StatelessWidget {
  const _CheckInResultCard({required this.result});

  final CheckInResult result;

  @override
  Widget build(BuildContext context) {
    final verified = result.verified;
    return InfoCard(
      icon: verified ? Icons.verified_outlined : Icons.location_off_outlined,
      title: verified
          ? 'Shift started successfully.'
          : 'You are outside the assigned shift location.',
      subtitle: verified
          ? 'Distance ${result.distanceMetres.toStringAsFixed(0)} m, GPS accuracy ${result.accuracyMetres.toStringAsFixed(0)} m.'
          : 'Distance ${result.distanceMetres.toStringAsFixed(0)} m. Please move closer or contact your supervisor.',
      badge: StatusBadge(
        label: verified ? 'Verified' : 'Failed',
        color: verified ? const Color(0xFF327A60) : const Color(0xFFC43D32),
      ),
    );
  }
}
