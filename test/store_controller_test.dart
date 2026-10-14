import 'package:flutter_test/flutter_test.dart';
import 'package:smartmart_frontend/data/sample_data.dart';
import 'package:smartmart_frontend/state/store_controller.dart';

void main() {
  group('StoreController demo cart', () {
    late StoreController store;

    setUp(() {
      store = StoreController(
        products: sampleProducts,
        initialCart: const {'milk': 1, 'apple': 2, 'eggs': 1},
      );
    });

    tearDown(() => store.dispose());

    test('calculates cart quantity, subtotal and standard delivery', () {
      expect(store.cartCount, 4);
      expect(store.subtotal, 246500);
      expect(store.deliveryFee, 10000);
      expect(store.total, 256500);
    });

    test('updates quantities and removes a line at zero', () {
      store.setQuantity(store.productById('apple'), 1);
      store.setQuantity(store.productById('milk'), 0);

      expect(store.cartCount, 2);
      expect(store.subtotal, 121000);
      expect(store.quantities.containsKey('milk'), isFalse);
    });

    test('places an order with the selected delivery fee and clears cart', () {
      final order = store.placeDemoOrder(deliveryFee: 25000);

      expect(order.lines, hasLength(3));
      expect(order.total, 271500);
      expect(store.cartLines, isEmpty);
      expect(store.cartCount, 0);
      expect(store.orders, contains(order));
    });
  });
}
