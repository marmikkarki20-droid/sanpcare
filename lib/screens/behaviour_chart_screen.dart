import 'package:flutter/material.dart';

import '../app/care_scope.dart';
import '../core/navigation.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_screen.dart';

class BehaviourChartScreen extends StatefulWidget {
  const BehaviourChartScreen({super.key});

  @override
  State<BehaviourChartScreen> createState() => _BehaviourChartScreenState();
}

class _BehaviourChartScreenState extends State<BehaviourChartScreen> {
  final formKey = GlobalKey<FormState>();
  final trigger = TextEditingController();
  final behaviourObserved = TextEditingController();
  final staffResponse = TextEditingController();
  final deEscalationStrategy = TextEditingController();
  final outcome = TextEditingController();
  final followUp = TextEditingController();
  String moodLevel = 'Settled';

  @override
  void dispose() {
    trigger.dispose();
    behaviourObserved.dispose();
    staffResponse.dispose();
    deEscalationStrategy.dispose();
    outcome.dispose();
    followUp.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final controller = CareScope.of(context);
    try {
      await controller.submitBehaviourChart(
        trigger: trigger.text,
        behaviourObserved: behaviourObserved.text,
        staffResponse: staffResponse.text,
        deEscalationStrategy: deEscalationStrategy.text,
        outcome: outcome.text,
        moodLevel: moodLevel,
        followUp: followUp.text,
      );
      if (!mounted) return;
      showSnack(context, 'Behaviour chart submitted.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showSnack(context, controller.error ?? 'Behaviour chart failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CareScope.of(context);
    return FormScreen(
      title: 'Behaviour chart',
      formKey: formKey,
      isBusy: controller.isBusy,
      onSubmit: submit,
      children: [
        RequiredField(
          controller: trigger,
          label: 'Trigger',
          icon: Icons.bolt_outlined,
          maxLines: 2,
        ),
        RequiredField(
          controller: behaviourObserved,
          label: 'Behaviour observed',
          icon: Icons.visibility_outlined,
          maxLines: 3,
        ),
        RequiredField(
          controller: staffResponse,
          label: 'Staff response',
          icon: Icons.support_agent_outlined,
          maxLines: 3,
        ),
        RequiredField(
          controller: deEscalationStrategy,
          label: 'De-escalation strategy',
          icon: Icons.self_improvement_outlined,
          maxLines: 2,
        ),
        RequiredField(
          controller: outcome,
          label: 'Outcome',
          icon: Icons.task_alt_outlined,
          maxLines: 2,
        ),
        DropdownButtonFormField<String>(
          initialValue: moodLevel,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.mood_outlined),
            labelText: 'Mood level',
          ),
          items:
              const [
                    'Settled',
                    'Anxious',
                    'Withdrawn',
                    'Agitated',
                    'Elevated',
                    'Distressed',
                  ]
                  .map(
                    (mood) => DropdownMenuItem(value: mood, child: Text(mood)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => moodLevel = value ?? moodLevel),
        ),
        OptionalField(
          controller: followUp,
          label: 'Follow-up required',
          icon: Icons.flag_outlined,
          maxLines: 2,
        ),
      ],
    );
  }
}
