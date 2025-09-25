import 'package:flutter/material.dart';
import 'package:edubee_app/screens/quiz_screen.dart';
import 'package:edubee_app/screens/settings_screen.dart';
import 'package:edubee_app/screens/tutorial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      label: 'Welcome to Edubee App',
                      child: const Text(
                        'Welcome to Edubee',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'App Description',
                      child: Text(
                        'Your interactive learning companion',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate([
                  _buildCard(
                    context,
                    'Tutorial',
                    'Learn the basics',
                    Icons.school,
                    [Colors.blue.shade400, Colors.blue.shade700],
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TutorialScreen()),
                    ),
                    'Open tutorial section to learn how to use the app',
                  ),
                  _buildCard(
                    context,
                    'Quiz',
                    'Test your knowledge',
                    Icons.quiz,
                    [Colors.purple.shade400, Colors.purple.shade700],
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    ),
                    'Start a new quiz to test your knowledge',
                  ),
                  _buildCard(
                    context,
                    'Settings',
                    'Customize your experience',
                    Icons.settings,
                    [Colors.orange.shade400, Colors.orange.shade700],
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                    'Open settings to customize app preferences',
                  ),
                  _buildCard(
                    context,
                    'Stats',
                    'Track your progress',
                    Icons.bar_chart,
                    [Colors.green.shade400, Colors.green.shade700],
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    'Statistics feature coming soon',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      List<Color> gradientColors,
      VoidCallback onTap,
      String semanticLabel,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Semantics(
          label: '$title, $subtitle',
          hint: semanticLabel,
          button: true,
          excludeSemantics: true,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha((0.9 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}