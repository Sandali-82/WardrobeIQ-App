import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/clothing_item.dart';
import '../services/api_service.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late Future<List<ClothingItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = ApiService.getClothingItems();
  }

  void _refresh() {
    setState(() {
      _itemsFuture = ApiService.getClothingItems();
    });
  }

  Future<void> _confirmDelete(ClothingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
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
      await ApiService.deleteClothingItem(item.id);
      _refresh();
    }
  }

  void _openAddItemSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddItemSheet(),
    );

    if (added == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wardrobe')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemSheet,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ClothingItem>>(
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.checkroom, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Your wardrobe is empty.\nTap + to add your first item.',
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
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _ClothingItemCard(
                  item: item,
                  onLongPress: () => _confirmDelete(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ClothingItemCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onLongPress;

  const _ClothingItemCard({required this.item, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
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
                    : const Icon(Icons.checkroom, size: 40, color: AppColors.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.category} • ${item.color}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet form for adding a new clothing item.
class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _colorController = TextEditingController();

  String _category = 'top';
  String _season = 'all-season';
  bool _isSaving = false;
  String? _errorMessage;

  static const _categories = ['top', 'bottom', 'shoes', 'outerwear', 'accessory'];
  static const _seasons = ['all-season', 'summer', 'winter'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ApiService.addClothingItem(
        name: _nameController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        category: _category,
        color: _colorController.text.trim(),
        season: _season,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Clothing Item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Image URL is required' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color (e.g. white, black)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Color is required' : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              dropdownColor: AppColors.surface,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _season,
              decoration: const InputDecoration(labelText: 'Season'),
              dropdownColor: AppColors.surface,
              items: _seasons
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _season = v!),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                    )
                  : const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
