import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../widgets/settings_widget.dart';

class SettingsPage extends StatefulWidget {
  final Settings? initialSettings;

  const SettingsPage({super.key, this.initialSettings});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Settings _settings;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSettings != null) {
      _settings = widget.initialSettings!;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // PopScope automatically handles the pop operation
        // No manual Navigator.pop needed here to avoid debug lock
      },
      child: SettingsWidget(
        initialSettings: _isInitialized ? _settings : null,
        onSettingsUpdated: (updatedSettings) {
          setState(() {
            _settings = updatedSettings;
            if (!_isInitialized) {
              _isInitialized = true;
            }
          });
        },
      ),
    );
  }
}
