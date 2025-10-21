import 'dart:io';

/// Flutter layered architecture structure (empty files)
final List<String> structure = [
  // CORE
  'lib/core/di/injector.dart',
  'lib/core/error/exceptions.dart',
  'lib/core/error/failure.dart',
  'lib/core/routes/app_router.dart',

  // DATA
  'lib/data/datasources/question_local_data_source.dart',
  'lib/data/datasources/settings_local_data_source.dart',
  'lib/data/models/question_model.dart',
  'lib/data/models/settings_model.dart',
  'lib/data/repositories/question_repository_impl.dart',
  'lib/data/repositories/settings_repository_impl.dart',

  // DOMAIN
  'lib/domain/entities/question.dart',
  'lib/domain/entities/settings.dart',
  'lib/domain/repositories/question_repository.dart',
  'lib/domain/repositories/settings_repository.dart',
  'lib/domain/usecases/get_all_questions.dart',
  'lib/domain/usecases/get_categories.dart',
  'lib/domain/usecases/get_settings.dart',
  'lib/domain/usecases/save_settings.dart',

  // PRESENTATION
  'lib/presentation/providers/quiz_provider.dart',
  'lib/presentation/providers/settings_provider.dart',
  'lib/presentation/providers/tutorial_provider.dart',
  'lib/presentation/screens/home/home_screen.dart',
  'lib/presentation/screens/quiz/question_screen.dart',
  'lib/presentation/screens/quiz/quiz_screen.dart',
  'lib/presentation/screens/quiz/results_screen.dart',
  'lib/presentation/screens/settings/settings_screen.dart',
  'lib/presentation/screens/tutorial/tutorial_screen.dart',
  'lib/presentation/themes/app_theme.dart',
  'lib/presentation/widgets/media_widget.dart',

  // SERVICES
  'lib/services/audio/background_music_service.dart',
  'lib/services/audio/sound_service.dart',
  'lib/services/usb/usb_controller.dart',

  // MAIN
  'lib/main.dart',
];

void main() {
  print('🚀 Generating Flutter project structure...\n');

  for (final path in structure) {
    final file = File(path);
    final dir = file.parent;

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('📁 Created directory: ${dir.path}');
    }

    if (!file.existsSync()) {
      file.createSync();
      print('📝 Created file: ${file.path}');
    } else {
      print('⚠️ File already exists: ${file.path}');
    }
  }

  print('\n✅ All directories and empty files created successfully!');
}
