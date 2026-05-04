import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_habit_model.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final DailyHabit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedTarget;
  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = [
    'Olahraga',
    'Belajar',
    'Kesehatan',
    'Produktivitas',
    'Sosial',
    'Spiritual',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Olahraga': Icons.sports_soccer,
    'Belajar': Icons.school,
    'Kesehatan': Icons.favorite,
    'Produktivitas': Icons.trending_up,
    'Sosial': Icons.people,
    'Spiritual': Icons.spa,
  };

  final List<String> _targets = ['Harian', 'Mingguan'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.habit != null) {
      _nameController = TextEditingController(text: widget.habit!.name);
      _descriptionController = TextEditingController(
        text: widget.habit!.description,
      );
      _selectedCategory = widget.habit!.category;
      _selectedTarget = widget.habit!.target;
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedCategory = _categories.first;
      _selectedTarget = _targets.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      final habit = DailyHabit(
        id:
            widget.habit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        target: _selectedTarget,
      );

      await ref.read(dailyHabitsProvider.notifier).addHabit(habit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.habit != null
                  ? 'Kebiasaan berhasil diperbarui!'
                  : 'Kebiasaan baru berhasil ditambahkan!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.habit != null ? 'Edit Kebiasaan' : 'Tambah Kebiasaan',
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama Kebiasaan',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Berlari pagi',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Nama tidak boleh kosong';
                  if (value.trim().length < 3) return 'Minimal 3 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Deskripsi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Tulis deskripsi (opsional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 24),
              Text(
                'Kategori',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(_categoryIcons[category], size: 20),
                          const SizedBox(width: 12),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null)
                      setState(() => _selectedCategory = value);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Target',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _targets.map((target) {
                    return RadioListTile<String>(
                      title: Text(target),
                      value: target,
                      groupValue: _selectedTarget,
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedTarget = value);
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveHabit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle),
                      const SizedBox(width: 8),
                      Text(
                        widget.habit != null
                            ? 'Perbarui Kebiasaan'
                            : 'Simpan Kebiasaan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
