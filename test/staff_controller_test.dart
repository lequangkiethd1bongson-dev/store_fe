import 'package:flutter_test/flutter_test.dart';
import 'package:smartmart_frontend/data/sample_data.dart';
import 'package:smartmart_frontend/state/staff_controller.dart';

void main() {
  group('StaffController demo inventory', () {
    late StaffController staff;

    setUp(() => staff = StaffController(products: sampleProducts));
    tearDown(() => staff.dispose());

    test('maps demo product barcodes and totals stock by location', () {
      expect(staff.productFromBarcode('8938501001001')?.id, 'milk');
      expect(staff.warehouseQuantity('milk'), 24);
      expect(staff.shelfQuantity('A1', 'milk'), 24);
      expect(staff.shelfTierQuantity('A1', 1, 'milk'), 24);
      expect(staff.shelfTierQuantity('A1', 2, 'eggs'), 5);
      expect(staff.shelfTierContents('A1', 3), isEmpty);
      expect(staff.locationForProduct('eggs')?.shelfCode, 'A1');
      expect(staff.locationForProduct('eggs')?.tier, 2);
      expect(staff.shelfItemCount, 113);
    });

    test('receipts record a date and moved stock is assigned to one tier', () {
      final milk = staff.productById('milk');

      staff.receiveStock(milk, 10);
      final receipt = staff.receiptsForProduct('milk').last;
      staff.moveToShelf(shelfCode: 'A1', tier: 3, product: milk, quantity: 6);

      expect(staff.warehouseQuantity('milk'), 28);
      expect(staff.shelfTierQuantity('A1', 3, 'milk'), 6);
      expect(staff.shelfQuantity('A1', 'milk'), 30);
      expect(staff.getShelfFillPercent('A1'), 29);
      expect(staff.intakeCount, 1);
      expect(receipt.quantity, 10);
      expect(receipt.receivedAt, isNotNull);
    });

    test('sale invoice deducts products from shelves and is retained', () {
      staff.addSaleByBarcode('8938501001001', quantity: 2);
      final sale = staff.completeSale();

      expect(sale.invoiceNumber, startsWith('SSM-'));
      expect(sale.lines.single.product.id, 'milk');
      expect(sale.lines.single.quantity, 2);
      expect(sale.total, 73000);
      expect(staff.shelfQuantity('A1', 'milk'), 22);
      expect(staff.saleLines, isEmpty);
      expect(staff.sales, contains(sale));
    });

    test('alerts when a shelf tier falls below five units', () {
      staff.addSaleByBarcode('8938501001003', quantity: 2);
      staff.completeSale();

      expect(staff.shelfTierQuantity('A1', 2, 'eggs'), 3);
      expect(staff.lowStockLines('A1').single.product.id, 'eggs');
      expect(staff.lowStockLines('A1').single.quantity, 3);
    });

    test('does not move or sell more units than available or mix a tier', () {
      expect(
        () => staff.moveToShelf(
          shelfCode: 'A1',
          tier: 3,
          product: staff.productById('milk'),
          quantity: 25,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => staff.addSaleByBarcode('8938501001004', quantity: 14),
        throwsA(isA<StateError>()),
      );
      expect(
        () => staff.moveToShelf(
          shelfCode: 'A1',
          tier: 1,
          product: staff.productById('eggs'),
          quantity: 1,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => staff.moveToShelf(
          shelfCode: 'A1',
          tier: 5,
          product: staff.productById('milk'),
          quantity: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
