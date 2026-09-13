import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/clothing_item.dart';
import '../services/api_service.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _notesController = TextEditingController();

  late Future<List<String>> _occasionTypesFuture;
  String? _selectedOccasion;

  bool _isLoading = false;
  String? _errorMessage;

  // Result state
  List<ClothingItem>? _suggestedItems;
  String? _explanation;

  @override
  void initState() {
    super.initState();
    _occasionTypesFuture = ApiService.getOccasionTypes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getSuggestion() async {
    if (_selectedOccasion == null) {
      setState(() => _errorMessage = 'Pick an occasion first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestedItems = null;
      _explanation = null;
    });

    try {
      // Fetch both in parallel - the suggestion gives us ids, the wardrobe
      // list lets us show the actual item names/images for those ids.
      final results = await Future.wait([
        ApiService.getSuggestion(
          occasion: _selectedOccasion!,
          notes: _notesController.text.trim(),
        ),
        ApiService.getClothingItems(),
      ]);

      final suggestion = results[0] as ({List<String> itemIds, String explanation});
      final allItems = results[1] as List<ClothingItem>;

      final matched = allItems.where((item) => suggestion.itemIds.contains(item.id)).toList();

      setState(() {
        _suggestedItems = matched;
        _explanation = suggestion.explanation;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Outfit Suggestion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.aiHighlight, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Powered by Gemini AI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.aiHighlight),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Occasion picker
            FutureBuilder<List<String>>(
              future: _occasionTypesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text(
                    'Could not load occasion types',
                    style: TextStyle(color: AppColors.error),
                  );
                }

                final occasions = snapshot.data!;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: occasions.map((occasion) {
                    final isSelected = _selectedOccasion == occasion;
                    return ChoiceChip(
                      label: Text(occasion),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedOccasion = occasion),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. outdoor, evening, cold weather',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),

            ElevatedButton(
              onPressed: _isLoading ? null : _getSuggestion,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                    )
                  : const Text('Get Suggestion'),
            ),

            // Result
            if (_explanation != null) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.aiHighlight.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.aiHighlight, size: 18),
                        const SizedBox(width: 6),
                        Text('Suggestion', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_explanation!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_suggestedItems != null && _suggestedItems!.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestedItems!.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = _suggestedItems![index];
                      return _SuggestedItemCard(item: item);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestedItemCard extends StatelessWidget {
  final ClothingItem item;
  const _SuggestedItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: AppColors.background,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                      )
                    : const Icon(Icons.checkroom, color: AppColors.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
