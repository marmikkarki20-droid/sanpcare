import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_screen.dart';

class ProgressNoteScreen extends StatefulWidget {
  const ProgressNoteScreen({super.key});

  @override
  State<ProgressNoteScreen> createState() => _ProgressNoteScreenState();
}

class _ProgressNoteScreenState extends State<ProgressNoteScreen> {
  final formKey = GlobalKey<FormState>();
  final shiftSummary = TextEditingController();
  final activities = TextEditingController();
  final mealsFluids = TextEditingController();
  final personalCare = TextEditingController();
  final moodBehaviour = TextEditingController();
  final communication = TextEditingController();
  final followUp = TextEditingController();

  @override
  void dispose() {
    shiftSummary.dispose();
    activities.dispose();
    mealsFluids.dispose();
    personalCare.dispose();
    moodBehaviour.dispose();
    communication.dispose();
    followUp.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final controller = CareScope.of(context);
    try {
      await controller.submitProgressNote(
        shiftSummary: shiftSummary.text,
        activities: activities.text,
        mealsFluids: mealsFluids.text,
        personalCare: personalCare.text,
        moodBehaviour: moodBehaviour.text,
        communication: communication.text,
        followUp: followUp.text,
      );
      if (!mounted) return;
      showSnack(context, 'Progress note submitted.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showSnack(context, controller.error ?? 'Progress note failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return FormScreen(
      title: 'Progress note',
      formKey: formKey,
      isBusy: controller.isBusy,
      onSubmit: submit,
      children: [
        RequiredField(
          controller: shiftSummary,
          label: 'Shift summary',
          icon: Icons.summarize_outlined,
          maxLines: 3,
        ),
        RequiredField(
          controller: activities,
          label: 'Activities completed',
          icon: Icons.checklist_outlined,
          maxLines: 3,
        ),
        RequiredField(
          controller: mealsFluids,
          label: 'Meals and fluids',
          icon: Icons.local_drink_outlined,
          maxLines: 2,
        ),
        RequiredField(
          controller: personalCare,
          label: 'Personal care support',
          icon: Icons.spa_outlined,
          maxLines: 2,
        ),
        RequiredField(
          controller: moodBehaviour,
          label: 'Mood and behaviour',
          icon: Icons.mood_outlined,
          maxLines: 2,
        ),
        RequiredField(
          controller: communication,
          label: 'Communication with client',
          icon: Icons.chat_bubble_outline,
          maxLines: 2,
        ),
        OptionalField(
          controller: followUp,
          label: 'Concerns or follow-up required',
          icon: Icons.flag_outlined,
          maxLines: 2,
        ),
      ],
    );
  }
}
