import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartmart_frontend/core/constants/api_constants.dart';
import 'package:smartmart_frontend/core/network/api_client.dart';
import 'package:smartmart_frontend/services/restock_service.dart';

void main() {
  group('RestockService API contract', () {
    late List<http.Request> requests;
    late ApiClient apiClient;
    late RestockService service;

    setUp(() {
      requests = [];
      apiClient = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({
                'id': 'request-1',
                'exportId': 'export-1',
                'storeId': 'store-1',
                'warehouseId': 'warehouse-1',
                'status': 'pending',
                'createdAt': '2026-10-26T12:00:00Z',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/restock-requests')) {
            return http.Response(
              jsonEncode([]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'request-1',
              'storeId': 'store-1',
              'warehouseId': 'warehouse-1',
              'status': 'received',
              'createdAt': '2026-10-26T12:00:00Z',
              'items': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      service = RestockService(apiClient: apiClient);
    });

    tearDown(() {
      service.dispose();
      apiClient.dispose();
    });

    test(
      'loads store stock from the current-store products endpoint',
      () async {
        final stockApiClient = ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode([
                {
                  'id': 'product-1',
                  'name': 'Bánh',
                  'price': 15000,
                  'imageUrl': '',
                  'storeStockQuantity': 3,
                  'minQuantity': 5,
                  'lowStock': true,
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        final stockService = RestockService(apiClient: stockApiClient);

        try {
          final stock = await stockService.getStoreStock();

          expect(requests.single.method, 'GET');
          expect(requests.single.url.path, '/api/store/products');
          expect(stock.single.quantity, 3);
          expect(stock.single.minQuantity, 5);
        } finally {
          stockService.dispose();
          stockApiClient.dispose();
        }
      },
    );

    test(
      'uses store request endpoint and includes the selected status',
      () async {
        final list = await service.getRequests(status: 'pending');

        expect(requests.single.method, 'GET');
        expect(requests.single.url.path, '/api/store/restock-requests');
        expect(requests.single.url.queryParameters['status'], 'pending');
        expect(list, isEmpty);
      },
    );

    test('posts the create-request body to the store endpoint', () async {
      final request = await service.createRequest(
        warehouseId: 'warehouse-1',
        items: [
          {'productId': 'product-1', 'requestedQuantity': 4},
        ],
        note: 'Bổ sung',
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>;

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/store/restock-requests');
      expect(body['warehouseId'], 'warehouse-1');
      expect(body['note'], 'Bổ sung');
      expect(items.single['productId'], 'product-1');
      expect(items.single['requestedQuantity'], 4);
      expect(request.id, 'request-1');
    });

    test(
      'confirms by export id then reloads request details by request id',
      () async {
        final request = await service.confirmReceipt(
          exportId: 'export-1',
          requestId: 'request-1',
        );

        expect(requests.map((request) => request.method), ['POST', 'GET']);
        expect(
          requests.first.url.path,
          '/api/store/stock-exports/export-1/confirm-receipt',
        );
        expect(requests.last.url.path, '/api/store/restock-requests/request-1');
        expect(request.status, 'received');
      },
    );

    test('uses the documented endpoint constants', () {
      expect(ApiConstants.storeStock, '/store/products');
      expect(ApiConstants.restockRequests, '/store/restock-requests');
      expect(
        ApiConstants.confirmStockReceipt('export-1'),
        '/store/stock-exports/export-1/confirm-receipt',
      );
    });
  });
}
