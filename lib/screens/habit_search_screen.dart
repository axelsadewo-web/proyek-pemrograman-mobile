import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_habit_model.dart';
import '../providers/search_provider.dart';
import '../services/habit_search_service.dart';

class HabitSearchScreen extends ConsumerStatefulWidget {
  const HabitSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HabitSearchScreen> createState() => _HabitSearchScreenState();
}

class _HabitSearchScreenState extends ConsumerState<HabitSearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabits = ref.watch(filteredHabitsProvider);
    final allCategories = ref.watch(allCategoriesProvider);
    final filterSummary = ref.watch(filterSummaryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final completionFilter = ref.watch(completionFilterProvider);
    final sortBy = ref.watch(sortByProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian & Filter'),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Cari kebiasaan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        filterSummary,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (searchQuery.isNotEmpty ||
                        selectedCategory != null ||
                        completionFilter != null ||
                        sortBy != SortBy.nameAsc)
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(categoryFilterProvider.notifier).state =
                              null;
                          ref.read(completionFilterProvider.notifier).state =
                              null;
                          ref.read(minStreakFilterProvider.notifier).state = 0;
                          ref.read(sortByProvider.notifier).state =
                              SortBy.nameAsc;
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reset'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Filter options header
              const Text(
                'Filter Lanjutan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Category filter
              const Text(
                'Kategori:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: selectedCategory == null,
                    onSelected: (selected) {
                      ref.read(categoryFilterProvider.notifier).state = null;
                    },
                  ),
                  ...allCategories.map(
                    (category) => FilterChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        ref.read(categoryFilterProvider.notifier).state =
                            selected ? category : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Completion status filter
              const Text(
                'Status:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: completionFilter == null,
                    onSelected: (selected) {
                      ref.read(completionFilterProvider.notifier).state = null;
                    },
                  ),
                  FilterChip(
                    label: const Text('✓ Selesai'),
                    selected: completionFilter == true,
                    onSelected: (selected) {
                      ref.read(completionFilterProvider.notifier).state =
                          selected ? true : null;
                    },
                  ),
                  FilterChip(
                    label: const Text('✗ Belum'),
                    selected: completionFilter == false,
                    onSelected: (selected) {
                      ref.read(completionFilterProvider.notifier).state =
                          selected ? false : null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sort option
              const Text(
                'Urutkan Berdasarkan:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButton<SortBy>(
                value: sortBy,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: SortBy.nameAsc,
                    child: const Text('Nama (A-Z)'),
                  ),
                  DropdownMenuItem(
                    value: SortBy.nameDesc,
                    child: const Text('Nama (Z-A)'),
                  ),
                  DropdownMenuItem(
                    value: SortBy.streakDesc,
                    child: const Text('Streak (Tertinggi)'),
                  ),
                  DropdownMenuItem(
                    value: SortBy.streakAsc,
                    child: const Text('Streak (Terendah)'),
                  ),
                  DropdownMenuItem(
                    value: SortBy.createdNewest,
                    child: const Text('Terbaru Dibuat'),
                  ),
                  DropdownMenuItem(
                    value: SortBy.createdOldest,
                    child: const Text('Tertua Dibuat'),
                  ),
                  DropdownMenuItem(
                    value: SortBy.completedFirst,
                    child: const Text('Selesai Dulu'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(sortByProvider.notifier).state = value;
                  }
                },
              ),
              const SizedBox(height: 24),

              // Results header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hasil (${filteredHabits.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    filteredHabits.isEmpty ? 'Tidak ada' : '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Results list
              if (filteredHabits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada kebiasaan yang cocok',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredHabits.length,
                  itemBuilder: (context, index) {
                    final habit = filteredHabits[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            habit.getCategoryEmoji(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        title: Text(habit.name),
                        subtitle: Text(
                          '${habit.category} • Streak: ${habit.streak}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: habit.isDoneToday
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            habit.isDoneToday ? '✓ Selesai' : '⏳ Pending',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: habit.isDoneToday
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
