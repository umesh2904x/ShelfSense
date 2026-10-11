import 'package:flutter_test/flutter_test.dart';
import 'package:shelfsense/models/product.dart';

void main() {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  Product productExpiringIn(int days) {
    return Product(
      id: 'test',
      name: 'Test item',
      category: ProductCategory.other,
      quantity: 1,
      expiryDate: todayDate.add(Duration(days: days)),
      createdAt: todayDate,
    );
  }

  test('classifies items by days remaining until expiry', () {
    expect(productExpiringIn(8).status, ExpiryStatus.safe);
    expect(productExpiringIn(7).status, ExpiryStatus.warning);
    expect(productExpiringIn(0).status, ExpiryStatus.warning);
    expect(productExpiringIn(-1).status, ExpiryStatus.expired);
  });

  test('calculates expiry days without time-of-day drift', () {
    expect(productExpiringIn(3).daysLeft, 3);
    expect(productExpiringIn(0).daysLeft, 0);
    expect(productExpiringIn(-2).daysLeft, -2);
  });
}
