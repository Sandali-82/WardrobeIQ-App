import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_theme.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/worn_log.dart';
import '../services/api_service.dart';
import 'outfit_picker_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<String, WornLog> _logsByDate = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedMonth);
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> _loadMonth(DateTime month) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      final logs = await ApiService.getWornLogs(from: firstDay, to: lastDay);

      setState(() {
        _logsByDate = {for (final log in logs) _key(log.dateWorn): log};
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  WornLog? get _selectedLog => _logsByDate[_key(_selectedDay)];

  Future<void> _assignOutfit() async {
    final outfits = await ApiService.getOutfits();
    if (!mounted) return;

    if (outfits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Build an outfit first before logging one.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Outfit>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OutfitPickerSheet(outfits: outfits),
    );

    if (selected == null) return;

    try {
      await ApiService.logWornOutfit(outfitId: selected.id, dateWorn: _selectedDay);
      _loadMonth(_focusedMonth);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _removeLog(WornLog log) async {
    await ApiService.deleteWornLog(log.id);
    _loadMonth(_focusedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outfit Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedMonth,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedMonth = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedMonth = focused;
              _loadMonth(focused);
            },
            eventLoader: (day) => _logsByDate.containsKey(_key(day)) ? [true] : [],
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: AppColors.aiHighlight, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary),
              weekendStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: _selectedLog != null
                            ? _LoggedOutfitCard(
                                log: _selectedLog!,
                                selectedDay: _selectedDay,
                                onRemove: () => _removeLog(_selectedLog!),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.event_note, size: 40, color: AppColors.textSecondary),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No outfit logged for this day.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _assignOutfit,
                                      child: const Text('Log an Outfit'),
                                    ),
                                  ],
                                ),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _LoggedOutfitCard extends StatelessWidget {
  final WornLog log;
  final DateTime selectedDay;
  final VoidCallback onRemove;

  const _LoggedOutfitCard({
    required this.log,
    required this.selectedDay,
    required this.onRemove,
  });

  // Date-aware label instead of a hardcoded "Worn today" - the same card
  // is shown whether the log is in the past, today, or planned ahead.
  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    if (day.isAtSameMomentAs(today)) return 'Wearing today';
    if (day.isBefore(today)) return 'Worn on ${_formatDate(day)}';
    return 'Planned for ${_formatDate(day)}';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    Text(log.outfitName, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ClothingItem>>(
            future: ApiService.getClothingItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                );
              }

              // The WornLog only stores an outfitId, not its item list, so
              // fetch the outfit's items via the wardrobe + outfit lookup.
              return FutureBuilder<Outfit?>(
                future: _findOutfit(log.outfitId),
                builder: (context, outfitSnapshot) {
                  if (outfitSnapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  final outfit = outfitSnapshot.data;
                  if (outfit == null) {
                    return const Text(
                      'This outfit no longer exists.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    );
                  }

                  final allItems = snapshot.data ?? [];
                  final items = allItems.where((i) => outfit.itemIds.contains(i.id)).toList();

                  if (items.isEmpty) {
                    return const Text(
                      'None of these items exist in your wardrobe anymore.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    );
                  }

                  return SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 90,
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
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Outfit?> _findOutfit(String outfitId) async {
    final outfits = await ApiService.getOutfits();
    try {
      return outfits.firstWhere((o) => o.id == outfitId);
    } catch (_) {
      return null;
    }
  }
}