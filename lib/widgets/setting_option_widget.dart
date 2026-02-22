import 'package:flutter/material.dart';

class SettingOptionWidget extends StatelessWidget {
  final String label;
  final Widget child;
  final String? helperText;

  const SettingOptionWidget({
    super.key,
    required this.label,
    required this.child,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
            if (helperText != null && helperText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                helperText!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
