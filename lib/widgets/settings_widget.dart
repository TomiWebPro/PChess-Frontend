import 'package:flutter/material.dart';
import '../board_theme.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../piece_set.dart';
import 'setting_option_widget.dart';

class SettingsWidget extends StatefulWidget {
  final Settings? initialSettings;
  final Function(Settings) onSettingsUpdated;

  const SettingsWidget({
    super.key,
    this.initialSettings,
    required this.onSettingsUpdated,
  });

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final ApiService _apiService = ApiService();
  late Settings _settings;
  bool _isLoading = true;
  String _errorMessage = '';

  List<String> _availableModels = [];
  final List<String> _availableLocales = ['en'];
  bool _isApiKeyVisible = false;

  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ??
        Settings(
          userElo: 0,
          maxEvaluationStrength: 0,
          pieceSet: 'default',
          boardTheme: 'blue',
          apiKey: '',
          userLocale: 'en',
          model: '',
        );
    _apiKeyController = TextEditingController(text: _settings.apiKey);
    _loadInitialData();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _apiService.getSettings(),
        _apiService.getOpenRouterModels(),
      ]);
      Settings fetchedSettings = results[0] as Settings;
      final models = results[1] as List<String>;
      
      // --- Identify and list available piece set names ---
      final List<String> availablePieceSetNames = PieceSet.values.map((e) => e.name).toList();
      print('Available Piece Set Names: $availablePieceSetNames'); // Log available names
      
      // Determine the default piece set name based on user request
      String defaultPieceSetName = 'maestro'; // User requested to try 'maestro'
      // Ensure 'maestro' is actually available, otherwise fall back to the first available name
      if (availablePieceSetNames.isNotEmpty && !availablePieceSetNames.contains('maestro')) {
        defaultPieceSetName = availablePieceSetNames.first; 
      }
      // --- End of new logic ---

      // Validate pieceSet from fetched settings
      String validatedPieceSet = fetchedSettings.pieceSet;
      if (validatedPieceSet.isEmpty || !availablePieceSetNames.contains(validatedPieceSet)) {
        validatedPieceSet = defaultPieceSetName; // Fallback to the determined default
      }
      
      // Create a new Settings object with the validated pieceSet
      final updatedSettings = fetchedSettings.copyWith(pieceSet: validatedPieceSet);

      setState(() {
        _settings = updatedSettings; // Assign the validated settings
        _apiKeyController.text = _settings.apiKey;
        _availableModels = models;
        if (!_availableModels.contains(_settings.model) && _settings.model.isNotEmpty) {
          _availableModels.insert(0, _settings.model);
        }
      });
      widget.onSettingsUpdated(updatedSettings);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load initial data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final newSettings = _settings.copyWith(apiKey: _apiKeyController.text);
      await _apiService.updateSettings(newSettings);
      if (mounted) {
        widget.onSettingsUpdated(newSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
        setState(() {
          _settings = newSettings;
        });

        // Defer the pop until after the build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop(_settings);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save settings: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading
              ? null
              : () {
                  // When the back button is pressed, return the current settings
                  Navigator.of(context).pop(_settings);
                },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      children: [
                        SettingOptionWidget(
                          label: 'User Elo',
                          helperText: 'Your chess rating',
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: _settings.userElo.toString(),
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  userElo: int.tryParse(value) ?? _settings.userElo,
                                );
                              });
                            },
                            decoration: const InputDecoration.collapsed(hintText: 'Enter your Elo'),
                          ),
                        ),
                        SettingOptionWidget(
                          label: 'Max Evaluation Strength',
                          helperText: 'Stockfish evaluation limit',
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: _settings.maxEvaluationStrength.toString(),
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  maxEvaluationStrength:
                                      int.tryParse(value) ?? _settings.maxEvaluationStrength,
                                );
                              });
                            },
                            decoration: const InputDecoration.collapsed(hintText: 'Enter evaluation strength'),
                          ),
                        ),
                        SettingOptionWidget(
                          label: 'Board Theme',
                          child: DropdownButton<String>(
                            value: _settings.boardTheme,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            items: BoardTheme.values.map((e) => e.name).toList().map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _settings = _settings.copyWith(boardTheme: value);
                                });
                              }
                            },
                          ),
                        ),
                        SettingOptionWidget(
                          label: 'Piece Set',
                          child: () {
                            final List<String> availablePieceSetNames = PieceSet.values.map((e) => e.name).toList();
                            String currentPieceSetValue = _settings.pieceSet;

                            // If no piece sets are available, display a message instead of a dropdown.
                            if (availablePieceSetNames.isEmpty) {
                              return const Text('No piece sets available');
                            }

                            // Ensure the currentPieceSetValue is valid and exists in the available options
                            if (currentPieceSetValue.isEmpty || !availablePieceSetNames.contains(currentPieceSetValue)) {
                              // If it's invalid or empty, try to set it to the first available piece set name.
                              currentPieceSetValue = availablePieceSetNames.first;
                            }

                            return DropdownButton<String>(
                              value: currentPieceSetValue, // This value is now guaranteed to be in availablePieceSetNames
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: availablePieceSetNames.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _settings = _settings.copyWith(pieceSet: value);
                                  });
                                }
                              },
                            );
                          }(), // Immediately invoke the function to get the widget
                        ),
                        SettingOptionWidget(
                          label: 'API Key',
                          helperText: 'Key for external services',
                          child: TextFormField(
                            controller: _apiKeyController,
                            obscureText: !_isApiKeyVisible,
                            decoration: InputDecoration(
                              hintText: 'Enter your API Key',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isApiKeyVisible ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isApiKeyVisible = !_isApiKeyVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SettingOptionWidget(
                          label: 'User Locale',
                          child: DropdownButton<String>(
                            value: _settings.userLocale,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            items: _availableLocales.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _settings = _settings.copyWith(userLocale: value);
                                });
                              }
                            },
                          ),
                        ),
                        if (_availableModels.isNotEmpty)
                          SettingOptionWidget(
                            label: 'AI Model',
                            child: DropdownButton<String>(
                              value: _settings.model,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              items: _availableModels.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _settings = _settings.copyWith(model: value);
                                  });
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
