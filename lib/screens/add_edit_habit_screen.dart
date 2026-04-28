import 'package:flutter/material.dart';

/// Extended Habit Model dengan field tambahan untuk form
class Habit {
  int? id;
  String name;
  String description;
  String category;
  String target; // 'Harian' atau 'Mingguan'
  DateTime? createdAt;

  Habit({
    this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.target,
    this.createdAt,
  });

  /// Convert Habit to JSON for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'target': target,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Create Habit from JSON
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Olahraga',
      target: map['target'] ?? 'Harian',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Create a copy of Habit with modified fields
  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? target,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Main Screen untuk Add & Edit Habit
class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit; // null jika mode Add, non-null jika mode Edit

  const AddEditHabitScreen({Key? key, this.habit}) : super(key: key);

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedTarget;
  final _formKey = GlobalKey<FormState>();

  // Available options
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

  /// Inisialisasi form dengan data edit atau kosong untuk mode add
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

  /// Save habit dan return ke previous screen
  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      // Create Habit object
      final habit = Habit(
        id: widget.habit?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        target: _selectedTarget,
        createdAt: widget.habit?.createdAt ?? DateTime.now(),
      );

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.habit != null
                ? 'Kebiasaan berhasil diperbarui!'
                : 'Kebiasaan berhasil ditambahkan!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Pop dengan result
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context, habit);
        }
      });
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
              // Nama Kebiasaan - Required
              _buildSectionTitle('Nama Kebiasaan'),
              const SizedBox(height: 8),
              _buildNameTextField(),
              const SizedBox(height: 24),

              // Deskripsi - Optional
              _buildSectionTitle('Deskripsi'),
              const SizedBox(height: 8),
              _buildDescriptionTextField(),
              const SizedBox(height: 24),

              // Kategori - Dropdown dengan Icon
              _buildSectionTitle('Kategori'),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),

              // Target - Radio Button
              _buildSectionTitle('Target'),
              const SizedBox(height: 8),
              _buildTargetRadioButtons(),
              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section title widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Build nama kebiasaan text field
  Widget _buildNameTextField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Contoh: Berlari pagi',
        prefixIcon: const Icon(Icons.label),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      maxLength: 50,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nama kebiasaan tidak boleh kosong';
        }
        if (value.trim().length < 3) {
          return 'Nama kebiasaan minimal 3 karakter';
        }
        return null;
      },
    );
  }

  /// Build deskripsi text field
  Widget _buildDescriptionTextField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        hintText: 'Tulis deskripsi kebiasaan (opsional)',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      maxLines: 3,
      maxLength: 200,
    );
  }

  /// Build kategori dropdown dengan icon
  Widget _buildCategoryDropdown() {
    return Container(
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
          if (value != null) {
            setState(() {
              _selectedCategory = value;
            });
          }
        },
      ),
    );
  }

  /// Build target radio buttons
  Widget _buildTargetRadioButtons() {
    return Container(
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
              if (value != null) {
                setState(() {
                  _selectedTarget = value;
                });
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          );
        }).toList(),
      ),
    );
  }

  /// Build save button
  Widget _buildSaveButton() {
    return SizedBox(
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
              widget.habit != null ? 'Perbarui Kebiasaan' : 'Simpan Kebiasaan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
