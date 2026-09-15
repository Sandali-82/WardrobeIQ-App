import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/api_service.dart';

class StylingGuideScreen extends StatefulWidget {
  const StylingGuideScreen({super.key});

  @override
  State<StylingGuideScreen> createState() => _StylingGuideScreenState();
}

class _StylingGuideScreenState extends State<StylingGuideScreen> {
  Future<({
    String necklines,
    String hairstyles,
    String sleeves,
    String silhouettes,
    String colors,
    String avoid,
  })>? _guideFuture;

  bool _hasRequested = false;

  void _loadGuide() {
    setState(() {
      _hasRequested = true;
      _guideFuture = ApiService.getStylingGuide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Styling Guide')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: !_hasRequested
            ? _IntroState(onGenerate: _loadGuide)
            : FutureBuilder(
                future: _guideFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString().replaceFirst('Exception: ', ''),
                      onRetry: _loadGuide,
                    );
                  }

                  final guide = snapshot.data!;
                  return ListView(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.aiHighlight, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Based on your face shape, body shape & undertone',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.aiHighlight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _GuideSection(icon: Icons.face_retouching_natural, title: 'Necklines & Collars', text: guide.necklines),
                      _GuideSection(icon: Icons.content_cut, title: 'Hairstyles', text: guide.hairstyles),
                      _GuideSection(icon: Icons.checkroom, title: 'Sleeves', text: guide.sleeves),
                      _GuideSection(icon: Icons.accessibility_new, title: 'Silhouettes', text: guide.silhouettes),
                      _GuideSection(icon: Icons.palette, title: 'Colors', text: guide.colors),
                      _GuideSection(
                        icon: Icons.block,
                        title: 'What to Avoid',
                        text: guide.avoid,
                        accentColor: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _loadGuide,
                          child: const Text('Regenerate'),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _IntroState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _IntroState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 48, color: AppColors.aiHighlight),
          const SizedBox(height: 16),
          Text(
            'Get a personalized styling guide built from your saved face shape, '
            'body shape, and skin undertone.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onGenerate,
            child: const Text('Generate My Styling Guide'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color? accentColor;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.text,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
