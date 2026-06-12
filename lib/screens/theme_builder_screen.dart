import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/theme_factory.dart';
import '../models/theme_settings.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_card.dart';
import '../widgets/tracked_list_view.dart';

class ThemeBuilderScreen extends StatefulWidget {
  const ThemeBuilderScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ThemeBuilderScreen> createState() => _ThemeBuilderScreenState();
}

class _ThemeBuilderScreenState extends State<ThemeBuilderScreen> {
  late final TextEditingController _name;
  late int _seedColor;
  late bool _darkMode;

  static const _colorOptions = [
    0xFF2563EB,
    0xFF0F766E,
    0xFFBE123C,
    0xFF7C3AED,
    0xFFB45309,
    0xFF475569,
  ];

  @override
  void initState() {
    super.initState();
    final theme = widget.controller.activeTheme;
    _name = TextEditingController(text: theme.name);
    _seedColor = theme.seedColor;
    _darkMode = theme.darkMode;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: TrackedListView(
        controller: widget.controller,
        screenName: 'Themes',
        children: [
          Text(
            'Theme builder',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Saved themes',
            subtitle: '${widget.controller.savedThemes.length} available',
            icon: Icons.style,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final theme in widget.controller.savedThemes)
                  ChoiceChip(
                    label: Text(theme.name),
                    selected: theme.sameLookAs(widget.controller.activeTheme),
                    onSelected: (_) => _selectTheme(theme),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Build a theme',
            subtitle: _darkMode ? 'Dark' : 'Light',
            icon: Icons.tune,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Theme name'),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final colorValue in _colorOptions)
                      _ColorSwatch(
                        colorValue: colorValue,
                        selected: colorValue == _seedColor,
                        onPressed: () =>
                            setState(() => _seedColor = colorValue),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  value: _darkMode,
                  onChanged: (value) => setState(() => _darkMode = value),
                ),
                const SizedBox(height: 12),
                _ThemePreviewPanel(theme: _draftTheme),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.check),
                        label: const Text('Apply'),
                        onPressed: widget.controller.busy ? null : _applyTheme,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: widget.controller.busy ? null : _saveTheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ThemeSettings get _draftTheme {
    return ThemeSettings(
      darkMode: _darkMode,
      name: _name.text.trim().isEmpty ? 'Custom' : _name.text.trim(),
      seedColor: _seedColor,
    );
  }

  Future<void> _applyTheme() {
    return widget.controller.selectTheme(_draftTheme);
  }

  Future<void> _saveTheme() {
    return widget.controller.saveTheme(_draftTheme);
  }

  Future<void> _selectTheme(ThemeSettings theme) async {
    setState(() {
      _darkMode = theme.darkMode;
      _name.text = theme.name;
      _seedColor = theme.seedColor;
    });
    await widget.controller.selectTheme(theme);
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.colorValue,
    required this.onPressed,
    required this.selected,
  });

  final int colorValue;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      isSelected: selected,
      onPressed: onPressed,
      icon: CircleAvatar(backgroundColor: Color(colorValue), radius: 12),
    );
  }
}

class _ThemePreviewPanel extends StatelessWidget {
  const _ThemePreviewPanel({required this.theme});

  final ThemeSettings theme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeFactory.fromSettings(theme),
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.primaryContainer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.palette,
                          color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(theme.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _PreviewDot(color: colorScheme.primary),
                            _PreviewDot(color: colorScheme.secondary),
                            _PreviewDot(color: colorScheme.tertiary),
                            _PreviewDot(
                                color: colorScheme.surfaceContainerHighest),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: null,
                    child: Text(theme.darkMode ? 'Dark' : 'Light'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(backgroundColor: color, radius: 7);
  }
}
