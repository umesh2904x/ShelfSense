// lib/services/product_service.dart
// Handles all Firestore operations for products

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

/// Service class for product CRUD operations
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's products collection reference
  CollectionReference<Map<String, dynamic>> get _productsRef {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products');
  }

  /// Get the current user's document reference (for name/email)
  DocumentReference<Map<String, dynamic>> get _userDocRef {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid);
  }

  /// Stream of all products for the current user, sorted by expiry date (nearest first)
  /// Used in HomeScreen with StreamBuilder for real-time updates
  Stream<List<Product>> getProductsStream() {
    return _productsRef
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// Stream of products filtered by category
  Stream<List<Product>> getProductsStreamByCategory(ProductCategory? category) {
    Query<Map<String, dynamic>> query = _productsRef.orderBy('expiryDate');

    if (category != null) {
      query = query.where('category', isEqualTo: category.displayName);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
    );
  }

  /// Add a new product
  /// Returns the document ID of the created product
  Future<String> addProduct(Product product) async {
    final docRef = await _productsRef.add(product.toFirestore());
    return docRef.id;
  }

  /// Update an existing product
  Future<void> updateProduct(Product product) async {
    await _productsRef.doc(product.id).update(product.toFirestore());
  }

  /// Delete a product by ID
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  /// Create or update user profile document (called on signup)
  Future<void> createUserProfile({
    required String name,
    required String email,
  }) async {
    await _userDocRef.set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}