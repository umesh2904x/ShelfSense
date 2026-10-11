// lib/models/product.dart
// Data model for a product with expiry tracking

import 'package:cloud_firestore/cloud_firestore.dart';

/// Product categories available in the app
enum ProductCategory {
  grocery('Grocery'),
  medicine('Medicine'),
  cosmetics('Cosmetics'),
  other('Other');

  const ProductCategory(this.displayName);
  final String displayName;

  /// Convert string from Firestore to enum
  static ProductCategory fromString(String value) {
    return ProductCategory.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => ProductCategory.other,
    );
  }
}

/// Status of product based on days left until expiry
enum ExpiryStatus {
  safe,      // More than 7 days left
  warning,   // 7 days or less left
  expired,   // Already expired
}

/// Product model representing an item with expiry date
class Product {
  final String id;
  final String name;
  final ProductCategory category;
  final int quantity;
  final DateTime expiryDate;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    required this.createdAt,
  });

  /// Create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: ProductCategory.fromString(data['category'] ?? 'Other'),
      quantity: data['quantity'] ?? 1,
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert Product to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category.displayName,
      'quantity': quantity,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Calculate days left until expiry (negative if expired)
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// Get expiry status based on days left
  ExpiryStatus get status {
    if (daysLeft < 0) return ExpiryStatus.expired;
    if (daysLeft <= 7) return ExpiryStatus.warning;
    return ExpiryStatus.safe;
  }

  /// Get color for the status chip
  /// Green = safe, Orange = warning, Red = expired
  // ignore: library_private_types_in_public_api
  _StatusColor get statusColor {
    switch (status) {
      case ExpiryStatus.safe:
        return const _StatusColor(0xFF4CAF50); // Green
      case ExpiryStatus.warning:
        return const _StatusColor(0xFFFF9800); // Orange
      case ExpiryStatus.expired:
        return const _StatusColor(0xFFF44336); // Red
    }
  }

  /// Create a copy of this product with updated fields
  Product copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    int? quantity,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Simple wrapper for status color to keep Product model clean
class _StatusColor {
  final int value;
  const _StatusColor(this.value);
}