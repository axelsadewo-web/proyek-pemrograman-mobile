import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_habit_model.dart';
import '../providers/search_provider.dart';
import '../providers/habits_riverpod.dart';
import '../services/habit_templates_service.dart';

class HabitTemplatesScreen extends ConsumerStatefulWidget {
  const HabitTemplatesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HabitTemplatesScreen> createState() =>
      _HabitTemplatesScreenState();
}

class _HabitTemplatesScreenState extends ConsumerState<HabitTemplatesScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  late TextEditingController _searchController;
  final Set<String> _selectedTemplates =
      {}; // Track selected templates for bulk add
  bool _isBulkMode = false; // Toggle between single and bulk mode

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
    final templates = _getFilteredTemplates();
    final categories = HabitTemplatesService.getAllCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Kebiasaan'),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        actions: [
          if (_isBulkMode) ...[
            TextButton.icon(
              onPressed: _selectedTemplates.isEmpty ? null : _addSelectedHabits,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Tambah (${_selectedTemplates.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isBulkMode = false;
                  _selectedTemplates.clear();
                });
              },
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ] else
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isBulkMode = true;
                });
              },
              icon: const Icon(Icons.playlist_add, color: Colors.white),
              label: const Text(
                'Tambah Banyak',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
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
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari template...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category filter
              const Text(
                'Kategori:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Popular templates section (if no search/filter)
              if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                const Text(
                  'Template Populer ⭐',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._buildPopularTemplates(),
                const SizedBox(height: 24),
              ],

              // All templates
              Text(
                'Semua Template (${_computeCount()})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (templates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Tidak ada template yang cocok',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return _buildTemplateCard(template);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<HabitTemplate> _getFilteredTemplates() {
    var templates = HabitTemplatesService.getAllTemplates();

    if (_searchQuery.isNotEmpty) {
      templates = HabitTemplatesService.searchTemplates(_searchQuery);
    }

    if (_selectedCategory != null) {
      templates = templates
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    return templates;
  }

  int _computeCount() {
    return _getFilteredTemplates().length;
  }

  List<Widget> _buildPopularTemplates() {
    final popular = HabitTemplatesService.getPopularTemplates();
    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...popular.map(
              (template) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 150,
                  child: _buildTemplateCard(template),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildTemplateCard(HabitTemplate template) {
    final isSelected = _selectedTemplates.contains(template.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isBulkMode && isSelected
            ? const BorderSide(color: Colors.blueAccent, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isBulkMode
            ? () => _toggleTemplateSelection(template.id)
            : () => _showTemplateDetails(template),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(template.icon, style: const TextStyle(fontSize: 28)),
                  if (_isBulkMode) ...[
                    const Spacer(),
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          _toggleTemplateSelection(template.id),
                      activeColor: Colors.blueAccent,
                    ),
                  ] else
                    const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        template.difficulty,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.difficulty,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(template.difficulty),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    template.category,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    '🔥 ${template.averageStreak}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTemplateSelection(String templateId) {
    setState(() {
      if (_selectedTemplates.contains(templateId)) {
        _selectedTemplates.remove(templateId);
      } else {
        _selectedTemplates.add(templateId);
      }
    });
  }

  void _addSelectedHabits() async {
    if (_selectedTemplates.isEmpty) return;

    final templates = HabitTemplatesService.getAllTemplates()
        .where((t) => _selectedTemplates.contains(t.id))
        .toList();

    int addedCount = 0;
    for (final template in templates) {
      try {
        final habit = template.toHabit();
        await ref.read(dailyHabitsProvider.notifier).addHabit(habit);
        addedCount++;
      } catch (e) {
        debugPrint('Error adding habit ${template.name}: $e');
      }
    }

    setState(() {
      _isBulkMode = false;
      _selectedTemplates.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount kebiasaan berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showTemplateDetails(HabitTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(template.icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          template.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(template.description, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...template.tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(tip, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final habit = template.toHabit();
                    ref.read(dailyHabitsProvider.notifier).addHabit(habit);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kebiasaan "${template.name}" berhasil ditambahkan!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambahkan Kebiasaan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Mudah':
        return Colors.green;
      case 'Sedang':
        return Colors.orange;
      case 'Sulit':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
