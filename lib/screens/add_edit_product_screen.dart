// lib/screens/add_edit_product_screen.dart
// Add/Edit product screen with form validation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/notification_service.dart';

/// Screen for adding a new product or editing an existing one
class AddEditProductScreen extends StatefulWidget {
  final Product? product; // null = add mode, non-null = edit mode

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  // Form state
  ProductCategory _selectedCategory = ProductCategory.grocery;
  DateTime _selectedExpiryDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields();
    }
  }

  /// Populate form fields with existing product data (edit mode)
  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _quantityController.text = product.quantity.toString();
    _selectedCategory = product.category;
    _selectedExpiryDate = product.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Show date picker and update selected date
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  /// Validate and save product
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productService = context.read<ProductService>();
      final notificationService = context.read<NotificationService>();

      final product = Product(
        id: widget.product?.id ??
            '', // Will be set by Firestore for new products
        name: _nameController.text.trim(),
        category: _selectedCategory,
        quantity: int.parse(_quantityController.text),
        expiryDate: _selectedExpiryDate,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (_isEditMode) {
        // Update existing product
        await productService.updateProduct(product);
        // Reschedule notifications
        await notificationService.cancelReminders(product.id);
        await notificationService.scheduleReminders(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated')),
          );
        }
      } else {
        // Add new product
        final productId = await productService.addProduct(product);
        // Schedule notifications with the new ID
        final newProduct = product.copyWith(id: productId);
        await notificationService.scheduleReminders(newProduct);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit product' : 'Add product'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: constraints.maxWidth > 720 ? 680 : constraints.maxWidth,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F2EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF34785A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditMode
                                  ? 'Update your item'
                                  : 'What would you like to track?',
                              style: const TextStyle(
                                color: Color(0xFF29372F),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add groceries, medicine, soap, skincare, or another everyday essential.',
                              style: TextStyle(
                                color: Color(0xFF7B887F),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product name',
                                prefixIcon: Icon(Icons.sell_outlined),
                                hintText: 'e.g. Milk, Aspirin, Face cream',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a product name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ProductCategory>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: ProductCategory.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCategory = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: Icon(Icons.numbers_outlined),
                                hintText: 'e.g. 1, 2, 10',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter quantity';
                                }
                                final quantity = int.tryParse(value.trim());
                                if (quantity == null || quantity < 1) {
                                  return 'Enter a valid quantity (1 or more)';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Expiry date',
                                  prefixIcon: Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  suffixIcon:
                                      Icon(Icons.edit_calendar_outlined),
                                ),
                                child: Text(
                                  DateFormat('EEEE, MMM d, yyyy')
                                      .format(_selectedExpiryDate),
                                  style: const TextStyle(
                                    color: Color(0xFF29372F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildExpiryPreview(),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _isLoading ? null : _save,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _isEditMode
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                    ),
                              label: Text(
                                _isEditMode ? 'Save changes' : 'Add product',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpiryPreview() {
    final notificationService = context.read<NotificationService>();
    final today = DateTime.now();
    final expiry = DateTime(
      _selectedExpiryDate.year,
      _selectedExpiryDate.month,
      _selectedExpiryDate.day,
    );
    final daysLeft =
        expiry.difference(DateTime(today.year, today.month, today.day)).inDays;
    final color =
        daysLeft <= 7 ? const Color(0xFFB76A14) : const Color(0xFF34785A);
    final message = daysLeft == 0
        ? 'Expires today'
        : 'Expires in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}';
    final reminderMessage = !notificationService.isSupported
        ? 'Item tracking works here; scheduled expiry reminders need the Android or iOS app.'
        : !notificationService.notificationsEnabled
            ? 'Enable notifications from the reminder card on the home screen to get expiry alerts.'
            : 'Reminder plan: 7 days before, 3 days before, and on expiry day at 9 AM.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            notificationService.isSupported &&
                    notificationService.notificationsEnabled
                ? Icons.notifications_active_outlined
                : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reminderMessage,
                  style: const TextStyle(
                    color: Color(0xFF68756D),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
