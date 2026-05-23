import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../widgets/evidence_picker_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_screen.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final formKey = GlobalKey<FormState>();
  final description = TextEditingController();
  final injuryObserved = TextEditingController();
  final actionTaken = TextEditingController();
  final informedPerson = TextEditingController();
  final witnessDetails = TextEditingController();
  final followUp = TextEditingController();
  String incidentType = 'Fall';
  XFile? image;

  @override
  void dispose() {
    description.dispose();
    injuryObserved.dispose();
    actionTaken.dispose();
    informedPerson.dispose();
    witnessDetails.dispose();
    followUp.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final controller = CareScope.of(context);
    try {
      await controller.submitIncident(
        incidentType: incidentType,
        description: description.text,
        injuryObserved: injuryObserved.text,
        actionTaken: actionTaken.text,
        informedPerson: informedPerson.text,
        witnessDetails: witnessDetails.text,
        followUp: followUp.text,
        image: image,
      );
      if (!mounted) return;
      showSnack(context, 'Incident report submitted.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showSnack(context, controller.error ?? 'Incident report failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return FormScreen(
      title: 'Incident report',
      formKey: formKey,
      isBusy: controller.isBusy,
      onSubmit: submit,
      children: [
        DropdownButtonFormField<String>(
          initialValue: incidentType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
            labelText: 'Incident type',
          ),
          items:
              const [
                    'Fall',
                    'Medication concern',
                    'Injury',
                    'Behaviour escalation',
                    'Missing item',
                    'Other',
                  ]
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: (value) =>
              setState(() => incidentType = value ?? incidentType),
        ),
        RequiredField(
          controller: description,
          label: 'What happened',
          icon: Icons.description_outlined,
          maxLines: 4,
        ),
        RequiredField(
          controller: injuryObserved,
          label: 'Injury observed',
          icon: Icons.healing_outlined,
          maxLines: 2,
        ),
        RequiredField(
          controller: actionTaken,
          label: 'Immediate action taken',
          icon: Icons.medical_services_outlined,
          maxLines: 3,
        ),
        RequiredField(
          controller: informedPerson,
          label: 'Who was informed',
          icon: Icons.call_outlined,
          maxLines: 1,
        ),
        OptionalField(
          controller: witnessDetails,
          label: 'Witness details',
          icon: Icons.groups_outlined,
          maxLines: 2,
        ),
        OptionalField(
          controller: followUp,
          label: 'Follow-up required',
          icon: Icons.flag_outlined,
          maxLines: 2,
        ),
        EvidencePickerCard(
          image: image,
          onChanged: (picked) => setState(() => image = picked),
        ),
      ],
    );
  }
}
