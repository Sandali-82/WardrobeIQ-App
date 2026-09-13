import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/clothing_item.dart';
import '../services/api_service.dart';

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  final _nameController = TextEditingController();
  late Future<List<ClothingItem>> _itemsFuture;
  final Set<String> _selectedIds = {};

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _itemsFuture = ApiService.getClothingItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _saveOutfit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Give this outfit a name');
      return;
    }
    if (_selectedIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one item');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ApiService.createOutfit(
        name: _nameController.text.trim(),
        itemIds: _selectedIds.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true); // tell the outfits list to refresh
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build an Outfit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Outfit name'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_selectedIds.length} item(s) selected — tap items below to select',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: FutureBuilder<List<ClothingItem>>(
              future: _itemsFuture,
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

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Add some wardrobe items first.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedIds.contains(item.id);
                    return _SelectableItemCard(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => _toggleSelection(item.id),
                    );
                  },
                );
              },
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveOutfit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                    )
                  : const Text('Save Outfit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableItemCard extends StatelessWidget {
  final ClothingItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                            )
                          : const Icon(Icons.checkroom, color: AppColors.textSecondary),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
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
            ),
            if (isSelected)
              const Positioned(
                top: 4, right: 4,
                child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
