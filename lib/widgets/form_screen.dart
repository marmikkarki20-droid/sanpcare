import 'package:flutter/material.dart';

import 'app_scaffold.dart';

class FormScreen extends StatelessWidget {
  const FormScreen({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSubmit,
    required this.isBusy,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: Form(
        key: formKey,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: children.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index < children.length) return children[index];
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: FilledButton.icon(
                onPressed: isBusy ? null : onSubmit,
                icon: isBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('Submit'),
              ),
            );
          },
        ),
      ),
    );
  }
}
