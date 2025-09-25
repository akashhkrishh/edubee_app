import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edubee_app/providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            // Use an accent color from the theme for high contrast
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: child,
    );
  }


  Color _getIconColor(BuildContext context) {
      return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          label: 'Settings Screen',
          child: const Text('Settings'),
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingCard(
            Consumer<SettingsProvider>(
              builder: (context, settings, child) => MergeSemantics(
                child: SwitchListTile(
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    settings.themeMode == ThemeMode.dark
                        ? 'Using dark theme'
                        : 'Using light theme',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  secondary: Icon(
                    settings.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: iconColor,
                  ),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (value) async {
                    await settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ),
            ),
          ),
          _buildSettingCard(
            Consumer<SettingsProvider>(
              builder: (context, settings, child) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MergeSemantics(
                    child: ListTile(
                      title: const Text(
                        'Font Size',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Adjust text size throughout the app',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      leading: Icon(
                        Icons.format_size,
                        color: iconColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(Icons.text_decrease, size: 20, color: iconColor),
                        ),
                        Expanded(
                          child: Semantics(
                            slider: true,
                            value: '${(settings.fontScale * 100).round()}% text size',
                            increasedValue: '${((settings.fontScale + 0.05) * 100).round()}% text size',
                            decreasedValue: '${((settings.fontScale - 0.05) * 100).round()}% text size',
                            child: Slider(
                              value: settings.fontScale,
                              min: 0.8,
                              max: 1.2,
                              divisions: 7,
                              onChanged: (value) async {
                                await settings.setFontScale(value);
                              },
                            ),
                          ),
                        ),
                        ExcludeSemantics(
                          child: Icon(Icons.text_increase, size: 20, color: iconColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildSectionHeader(context, 'Audio'),
          _buildSettingCard(
            Consumer<SettingsProvider>(
              builder: (context, settings, child) => MergeSemantics(
                child: SwitchListTile(
                  title: const Text(
                    'Background Music',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  secondary: Icon(
                    Icons.music_note,
                    color: iconColor,
                  ),
                  value: settings.isMusicEnabled,
                  onChanged: (value) async {
                    await settings.setMusicEnabled(value);
                  },
                ),
              ),
            ),
          ),
          _buildSettingCard(
            Consumer<SettingsProvider>(
              builder: (context, settings, child) => MergeSemantics(
                child: SwitchListTile(
                  title: const Text(
                    'Sound Effects',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  secondary: Icon(
                    Icons.volume_up,
                    color: iconColor,
                  ),
                  value: settings.isSfxEnabled,
                  onChanged: (value) async {
                    await settings.setSfxEnabled(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}