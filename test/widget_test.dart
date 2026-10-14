// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartmart_frontend/main.dart';

Future<void> _pumpReadyApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'session.loggedIn': true,
    'session.userName': 'Khách hàng',
    'session.userEmail': 'Đăng nhập để đồng bộ đơn hàng',
  });
  await tester.pumpWidget(const SmartMartApp());
  await tester.pump(const Duration(milliseconds: 3000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('delivery rider enters on launch before exiting', (tester) async {
    SharedPreferences.setMockInitialValues({
      'session.loggedIn': true,
      'session.userName': 'Khách hàng',
      'session.userEmail': 'Đăng nhập để đồng bộ đơn hàng',
    });
    await tester.pumpWidget(const SmartMartApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('delivery-rider')), findsOneWidget);
    final riderSlide = find.ancestor(
      of: find.byKey(const ValueKey('delivery-rider')),
      matching: find.byType(SlideTransition),
    );
    expect(
      tester.widget<SlideTransition>(riderSlide.first).position.value.dx,
      lessThan(0),
    );
    expect(
      find.text('Đang chuẩn bị trải nghiệm mua sắm của bạn'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first launch asks the customer to log in before opening app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SmartMartApp());
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
    expect(
      find.text('Đăng nhập để tiếp tục mua sắm cùng SSM4'),
      findsOneWidget,
    );
    expect(find.text('Trang chủ'), findsNothing);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'minhanh@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('session.loggedIn'), isTrue);
    expect(preferences.getString('session.userEmail'), 'minhanh@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('employee area opens from account menu and keeps shopper app', (
    tester,
  ) async {
    await _pumpReadyApp(tester);
    await tester.tap(find.bySemanticsLabel('Mở menu tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khu vực nhân viên · Demo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('staff-dashboard')), findsOneWidget);
    expect(find.text('Khu vực trưng bày'), findsOneWidget);
    final firstShelf = find.byKey(const ValueKey('staff-shelf-A1'));
    await tester.ensureVisible(firstShelf);
    expect(firstShelf, findsOneWidget);
    expect(find.text('Kho hàng'), findsOneWidget);
    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.text('Chấm công'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('staff-exit')));
    await tester.pumpAndSettle();
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staff shelf map and warehouse search show detailed stock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);
    await tester.tap(find.bySemanticsLabel('Mở menu tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khu vực nhân viên · Demo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('staff-shelf-search')));
    await tester.tap(find.byKey(const ValueKey('staff-shelf-search')));
    await tester.enterText(
      find.byKey(const ValueKey('staff-shelf-search')),
      'sữa tươi',
    );
    await tester.pumpAndSettle();
    final searchResult = find.byKey(
      const ValueKey('staff-shelf-search-result-milk'),
    );
    expect(searchResult, findsOneWidget);
    await tester.ensureVisible(searchResult);
    await tester.tap(searchResult);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết Kệ A1'), findsOneWidget);
    for (var tier = 1; tier <= 4; tier++) {
      expect(
        find.byKey(ValueKey('shelf-tier-A1-$tier')),
        findsOneWidget,
      );
    }
    expect(find.text('Kệ trống'), findsNWidgets(2));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kho hàng'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('staff-inventory-search')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('staff-inventory-search')),
      'vinamilk',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('inventory-product-milk')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('inventory-product-milk')));
    await tester.pumpAndSettle();
    expect(find.text('Lịch sử nhập kho'), findsOneWidget);
    expect(find.text('Thương hiệu: VINAMILK'), findsOneWidget);
    expect(find.textContaining('Nhập 24 sản phẩm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows SSM4 home and bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 32);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    await _pumpReadyApp(tester);

    expect(find.text('SSM4'), findsOneWidget);
    expect(find.byTooltip('Thông báo'), findsOneWidget);
    expect(find.byTooltip('Ghi chú'), findsOneWidget);
    expect(find.text('Tươi ngon mỗi ngày'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Quét mã QR'), findsOneWidget);
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Khuyến mãi hôm nay'), findsOneWidget);
    expect(find.text('Mua lại lần trước'), findsOneWidget);
    expect(find.text('Ưu đãi dành cho bạn'), findsOneWidget);
    final firstCategoryFace = find.descendant(
      of: find.byKey(const ValueKey('home-category-Rau củ quả')),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(firstCategoryFace), const Size(104, 104));
  });

  testWidgets('home banner overlaps the blue header without a blank gap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 32);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    await _pumpReadyApp(tester);

    final headerRect = tester.getRect(
      find.byKey(const ValueKey('home-collapsing-header')),
    );
    final bannerRect = tester.getRect(
      find.byKey(const ValueKey('home-promo-banner')),
    );
    final blueBackgroundRect = tester.getRect(
      find.byKey(const ValueKey('home-header-blue-background')),
    );

    expect(headerRect.height, greaterThan(350));
    expect(bannerRect.top, lessThan(headerRect.bottom));
    expect(bannerRect.bottom, closeTo(headerRect.bottom, 1));
    expect(blueBackgroundRect.bottom, closeTo(headerRect.bottom - 84, 1));
    expect(bannerRect.top, lessThan(blueBackgroundRect.bottom));
    expect(bannerRect.bottom, greaterThan(blueBackgroundRect.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('home note button responds while search remains in the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 32);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    await _pumpReadyApp(tester);

    await tester.tap(find.byTooltip('Ghi chú'));
    await tester.pump();
    expect(find.text('Ghi chú mua sắm sẽ sớm có mặt.'), findsOneWidget);
    final notice = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(notice.duration, const Duration(seconds: 2));
    expect(notice.behavior, SnackBarBehavior.floating);
    expect(notice.backgroundColor, Colors.white);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -460),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField).first, findsOneWidget);
    expect(tester.getTopLeft(find.byType(TextField).first).dy, lessThan(150));
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('home-collapsing-header')),
    );
    final blueBackgroundRect = tester.getRect(
      find.byKey(const ValueKey('home-header-blue-background')),
    );
    final searchRect = tester.getRect(find.byType(TextField).first);
    expect(blueBackgroundRect.top, headerRect.top);
    expect(
      blueBackgroundRect.bottom - searchRect.bottom,
      greaterThanOrEqualTo(12),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation opens the shared cart screen', (tester) async {
    await _pumpReadyApp(tester);

    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Giỏ hàng'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Thanh toán'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping a cart item left removes it and supports undo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);

    await tester.tap(find.byKey(const ValueKey('main-tab-3')));
    await tester.pumpAndSettle();
    expect(find.text('Sữa tươi Vinamilk 1L'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('cart-line-milk')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sữa tươi Vinamilk 1L'), findsNothing);
    expect(find.textContaining('Đã xóa Sữa tươi Vinamilk 1L'), findsOneWidget);
    final notice = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(notice.duration, const Duration(seconds: 2));
    expect(notice.behavior, SnackBarBehavior.floating);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('Sữa tươi Vinamilk 1L'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product details show favorite, share, and cart actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);

    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thịt cá').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thịt bò Úc 500g'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Yêu thích'), findsOneWidget);
    expect(find.byTooltip('Chia sẻ sản phẩm'), findsOneWidget);
    expect(find.byTooltip('Mở giỏ hàng'), findsOneWidget);
    await tester.tap(find.byTooltip('Yêu thích'));
    await tester.pump();
    expect(find.byTooltip('Bỏ yêu thích'), findsOneWidget);

    await tester.tap(find.byTooltip('Chia sẻ sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-share-sheet')), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('product-share-sheet'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm vào giỏ'));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(const ValueKey('flying-product-image')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Đã thêm Thịt bò Úc 500g vào giỏ hàng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('QR scanner is centered in navigation and opens its prompt', (
    tester,
  ) async {
    await _pumpReadyApp(tester);

    final qrButton = find.byKey(const ValueKey('main-tab-2'));
    expect(
      tester.getCenter(qrButton).dx,
      closeTo(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
        2,
      ),
    );
    await tester.tap(qrButton);
    await tester.pumpAndSettle();

    expect(find.text('Quét mã QR'), findsNWidgets(2));
    expect(
      find.text('Chức năng mở camera để quét mã QR sẽ được kết nối sau.'),
      findsOneWidget,
    );
  });

  testWidgets('category page has a full-width carousel and no search field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 32);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    await _pumpReadyApp(tester);

    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();

    final banner = find.byKey(const ValueKey('category-promo-banner'));
    final bannerRect = tester.getRect(banner);
    expect(bannerRect.width, closeTo(tester.view.physicalSize.width, 1));
    expect(bannerRect.top, closeTo(0, 1));
    expect(bannerRect.height, closeTo(305, 1));
    expect(
      find.byKey(const ValueKey('category-banner-heading')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(
      find.byKey(const ValueKey('category-promo-title-0')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('category-banner-pages')),
      const Offset(-340, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-promo-title-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-promo-dot-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home search stays pinned while the page scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 32);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    await _pumpReadyApp(tester);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -460),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField).first, findsOneWidget);
    expect(tester.getTopLeft(find.byType(TextField).first).dy, lessThan(150));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the logo opens the slide-out account menu', (
    tester,
  ) async {
    await _pumpReadyApp(tester);

    await tester.tap(find.bySemanticsLabel('Mở menu tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Khách hàng'), findsOneWidget);
    expect(find.text('Đơn hàng của tôi'), findsOneWidget);
    expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);
  });

  testWidgets('demo sign-up completes with a full-screen welcome transition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);

    await tester.tap(find.bySemanticsLabel('Mở menu tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập / Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('ShoppongSmartMart4'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-rider-art')), findsOneWidget);
    final registerLink = find.text('Chưa có tài khoản? Đăng ký ngay');
    await tester.drag(find.byType(ListView).last, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Minh Anh');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'minhanh@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    expect(tester.state<FormState>(find.byType(Form).last).validate(), isTrue);
    final submitButton = find.text('Tạo tài khoản').last;
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .validator!
          .call('Minh Anh'),
      isNull,
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Vui lòng nhập tên hiển thị'), findsNothing);
    expect(find.text('Vui lòng nhập email hoặc số điện thoại'), findsNothing);
    expect(find.text('Mật khẩu cần có ít nhất 6 ký tự'), findsNothing);
    expect(find.text('Chào mừng bạn quay lại'), findsOneWidget);
    expect(find.byKey(const ValueKey('delivery-rider')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Khuyến mãi hôm nay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pulling down at the top refreshes without layout errors', (
    tester,
  ) async {
    await _pumpReadyApp(tester);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 260),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SSM4'), findsOneWidget);
  });

  testWidgets('home search accepts text and shows the empty results panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);

    await tester.enterText(find.byType(TextField).first, 'cà phê');
    await tester.pump();

    expect(find.byKey(const ValueKey('home-search-results')), findsOneWidget);
    expect(find.text('Chưa có sản phẩm phù hợp với “cà phê”'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home address selector lets the shopper choose a saved address', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);

    await tester.tap(find.byKey(const ValueKey('home-address-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Chọn địa chỉ giao hàng'), findsOneWidget);
    await tester.tap(find.text('Ký túc xá, TP. Thủ Đức'));
    await tester.pumpAndSettle();

    expect(find.text('Ký túc xá, TP. Thủ Đức'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home address selector can add and select a new address', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);

    await tester.tap(find.byKey(const ValueKey('home-address-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm địa chỉ mới'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '45 Lê Lợi, Quận 1');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('45 Lê Lợi, Quận 1'));
    await tester.pumpAndSettle();

    expect(find.text('45 Lê Lợi, Quận 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meat promo slide opens its matching product category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpReadyApp(tester);

    await tester.drag(find.byType(PageView).first, const Offset(-320, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('promo-buy-Thịt cá')));
    await tester.pumpAndSettle();

    expect(find.text('Thịt cá'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
