import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../services/api_service.dart';
import 'outfit_builder_screen.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  late Future<List<Outfit>> _outfitsFuture;

  @override
  void initState() {
    super.initState();
    _outfitsFuture = ApiService.getOutfits();
  }

  void _refresh() {
    setState(() {
      _outfitsFuture = ApiService.getOutfits();
    });
  }

  Future<void> _openBuilder() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OutfitBuilderScreen()),
    );
    if (saved == true) _refresh();
  }

  Future<void> _confirmDelete(Outfit outfit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete outfit?'),
        content: Text('Remove "${outfit.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteOutfit(outfit.id);
      _refresh();
    }
  }

  // Shows the outfit's items in a bottom sheet. Fetches the full wardrobe
  // once and filters to the ids on this outfit - simpler than adding a
  // dedicated backend endpoint just for this.
  void _showOutfitDetails(Outfit outfit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OutfitDetailSheet(outfit: outfit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Outfits')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openBuilder,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Outfit>>(
        future: _outfitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final outfits = snapshot.data ?? [];
          if (outfits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.style, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'No outfits yet.\nTap + to build your first one.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: outfits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final outfit = outfits[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.style, color: AppColors.primary),
                    title: Text(outfit.name),
                    subtitle: Text('${outfit.itemIds.length} item(s) • tap to view'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _confirmDelete(outfit),
                    ),
                    onTap: () => _showOutfitDetails(outfit),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OutfitDetailSheet extends StatelessWidget {
  final Outfit outfit;
  const _OutfitDetailSheet({required this.outfit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<ClothingItem>>(
        future: ApiService.getClothingItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text(
              snapshot.error.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: AppColors.error),
            );
          }

          final allItems = snapshot.data ?? [];
          final items = allItems.where((i) => outfit.itemIds.contains(i.id)).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outfit.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Text(
                  'None of these items exist in your wardrobe anymore.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  color: AppColors.background,
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                              Icons.image_not_supported,
                                              color: AppColors.textSecondary),
                                        )
                                      : const Icon(Icons.checkroom, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}