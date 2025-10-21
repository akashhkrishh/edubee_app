import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edubee_app/providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader(title: 'Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) {
                settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
              secondary: Icon(
                settings.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                color: iconColor,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.format_size, color: iconColor),
                  title: const Text('Font Size'),
                  subtitle: Text('Current: ${(settings.fontScale * 100).round()}%'),
                ),
                Slider(
                  value: settings.fontScale,
                  min: 0.8,
                  max: 1.2,
                  divisions: 5,
                  label: '${(settings.fontScale * 100).round()}%',
                  onChanged: (value) {
                    settings.setFontScale(value);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const _SectionHeader(title: 'Audio'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              title: const Text('Background Music'),
              value: settings.isMusicEnabled,
              onChanged: (value) {
                settings.setMusicEnabled(value);
              },
              secondary: Icon(Icons.music_note, color: iconColor),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              title: const Text('Sound Effects'),
              value: settings.isSfxEnabled,
              onChanged: (value) {
                settings.setSfxEnabled(value);
              },
              secondary: Icon(Icons.volume_up, color: iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}