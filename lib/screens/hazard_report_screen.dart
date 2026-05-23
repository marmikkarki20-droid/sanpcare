import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../widgets/evidence_picker_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_screen.dart';

class HazardReportScreen extends StatefulWidget {
  const HazardReportScreen({super.key});

  @override
  State<HazardReportScreen> createState() => _HazardReportScreenState();
}

class _HazardReportScreenState extends State<HazardReportScreen> {
  final formKey = GlobalKey<FormState>();
  final location = TextEditingController();
  final description = TextEditingController();
  final actionTaken = TextEditingController();
  String hazardType = 'Wet floor';
  String riskLevel = 'Medium';
  XFile? image;

  @override
  void dispose() {
    location.dispose();
    description.dispose();
    actionTaken.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final controller = CareScope.of(context);
    try {
      await controller.submitHazard(
        hazardType: hazardType,
        location: location.text,
        riskLevel: riskLevel,
        description: description.text,
        actionTaken: actionTaken.text,
        image: image,
      );
      if (!mounted) return;
      showSnack(context, 'Hazard report submitted.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showSnack(context, controller.error ?? 'Hazard report failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return FormScreen(
      title: 'Hazard report',
      formKey: formKey,
      isBusy: controller.isBusy,
      onSubmit: submit,
      children: [
        DropdownButtonFormField<String>(
          initialValue: hazardType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.warning_amber_outlined),
            labelText: 'Hazard type',
          ),
          items:
              const [
                    'Wet floor',
                    'Broken furniture',
                    'Damaged equipment',
                    'Blocked exit',
                    'Poor lighting',
                    'Trip hazard',
                    'Unsafe environment',
                  ]
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: (value) =>
              setState(() => hazardType = value ?? hazardType),
        ),
        RequiredField(
          controller: location,
          label: 'Location or room',
          icon: Icons.room_outlined,
        ),
        DropdownButtonFormField<String>(
          initialValue: riskLevel,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.speed_outlined),
            labelText: 'Risk level',
          ),
          items: const ['Low', 'Medium', 'High', 'Urgent']
              .map(
                (level) => DropdownMenuItem(value: level, child: Text(level)),
              )
              .toList(),
          onChanged: (value) => setState(() => riskLevel = value ?? riskLevel),
        ),
        RequiredField(
          controller: description,
          label: 'Description',
          icon: Icons.description_outlined,
          maxLines: 4,
        ),
        RequiredField(
          controller: actionTaken,
          label: 'Immediate action taken',
          icon: Icons.build_circle_outlined,
          maxLines: 3,
        ),
        EvidencePickerCard(
          image: image,
          onChanged: (picked) => setState(() => image = picked),
        ),
      ],
    );
  }
}
