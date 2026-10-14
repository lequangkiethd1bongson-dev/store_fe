import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../state/store_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// hiển thị các mặt hàng trong giỏ và mở bước thanh toán.
class CartScreen extends StatelessWidget {
  const CartScreen({required this.store, required this.onCheckout, super.key});

  final StoreController store;
  final VoidCallback onCheckout;

  /// dựng giỏ hàng, tổng tiền và nút chuyển sang thanh toán.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Giỏ hàng'),
          actions: [
            if (store.cartLines.isNotEmpty)
              TextButton(
                onPressed: () => _confirmClear(context),
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(color: Color(0xFFE45858), fontSize: 11),
                ),
              ),
          ],
        ),
        body: store.cartLines.isEmpty
            ? _EmptyCart(
                onContinue: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  Row(
                    children: [
                      Text(
                        '${store.cartCount} sản phẩm trong giỏ',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${store.cartLines.length} mặt hàng',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...store.cartLines.map(
                    (line) => _CartLineTile(store: store, line: line),
                  ),
                ],
              ),
        bottomNavigationBar: store.cartLines.isEmpty
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng cộng',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatVnd(store.total),
                              style: const TextStyle(
                                color: AppColors.blue800,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: onCheckout,
                        child: Text('Thanh toán (${store.cartCount})'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// hỏi xác nhận trước khi xóa toàn bộ sản phẩm khỏi giỏ.
  Future<void> _confirmClear(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giỏ hàng?'),
        content: const Text('Bạn có muốn xóa tất cả sản phẩm trong giỏ không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (shouldClear == true) store.clearCart();
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onContinue});

  final VoidCallback onContinue;

  /// hướng người dùng quay lại mua sắm khi chưa có sản phẩm trong giỏ.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.blue600,
            ),
            const SizedBox(height: 14),
            const Text(
              'Giỏ hàng đang trống',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thêm sản phẩm bạn yêu thích để bắt đầu mua sắm.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onContinue,
              child: const Text('Tiếp tục mua sắm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.store, required this.line});

  final StoreController store;
  final CartLine line;

  /// dựng một dòng giỏ hàng, hỗ trợ đổi số lượng và vuốt để xóa.
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('cart-line-${line.product.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.28},
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9E9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFD83D4D)),
            SizedBox(height: 3),
            Text(
              'Xóa',
              style: TextStyle(
                color: Color(0xFFD83D4D),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        store.removeFromCart(line.product);
        showSmartMartNotice(
          context,
          message: 'Đã xóa ${line.product.name} khỏi giỏ hàng',
          icon: Icons.delete_outline_rounded,
          actionLabel: 'Hoàn tác',
          onAction: () =>
              store.addToCart(line.product, quantity: line.quantity),
        );
      },
      child: Container(
        key: ValueKey('cart-line-card-${line.product.id}'),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue900.withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: 70,
                height: 76,
                child: ProductImage(imageUrl: line.product.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    line.product.category,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    formatVnd(line.product.price),
                    style: const TextStyle(
                      color: AppColors.blue800,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _MiniQuantityControl(
                    quantity: line.quantity,
                    onDecrement: () =>
                        store.setQuantity(line.product, line.quantity - 1),
                    onIncrement: () =>
                        store.setQuantity(line.product, line.quantity + 1),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('remove-cart-${line.product.id}'),
              tooltip: 'Xóa sản phẩm',
              visualDensity: VisualDensity.compact,
              onPressed: () => store.removeFromCart(line.product),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniQuantityControl extends StatelessWidget {
  const _MiniQuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  /// hiển thị nút giảm, số lượng hiện tại và nút tăng.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            icon: const Icon(Icons.remove, size: 13),
          ),
          SizedBox(
            width: 25,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            icon: const Icon(Icons.add, size: 13),
          ),
        ],
      ),
    );
  }
}

/// thu thập địa chỉ, hình thức giao hàng và phương thức thanh toán.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.store,
    required this.onOrderPlaced,
    super.key,
  });

  final StoreController store;
  final ValueChanged<StoreOrder> onOrderPlaced;

  /// tạo trạng thái cho các lựa chọn giao hàng và thanh toán.
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _payment = 'cod';
  String _delivery = 'standard';
  final _noteController = TextEditingController();

  /// giải phóng bộ điều khiển biểu mẫu khi kết thúc thanh toán.
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// dựng thông tin giao hàng, lựa chọn thanh toán và tổng tiền đơn.
  @override
  Widget build(BuildContext context) {
    final deliveryPrice = _delivery == 'standard' ? 10000 : 25000;
    final amount = widget.store.subtotal + deliveryPrice;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Thanh toán'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        children: [
          const SectionHeading(title: 'Địa chỉ nhận hàng', action: 'Thay đổi'),
          const AddressCard(),
          const SectionHeading(title: 'Phương thức giao hàng', action: null),
          _DeliveryOption(
            selected: _delivery == 'standard',
            title: 'Giao hàng tiêu chuẩn',
            subtitle: 'Nhận hàng trong 2–3 giờ',
            fee: '10.000đ',
            icon: Icons.local_shipping_outlined,
            onTap: () => setState(() => _delivery = 'standard'),
          ),
          const SizedBox(height: 8),
          _DeliveryOption(
            selected: _delivery == 'express',
            title: 'Giao hàng nhanh',
            subtitle: 'Nhận hàng trong 60 phút',
            fee: '25.000đ',
            icon: Icons.schedule_rounded,
            onTap: () => setState(() => _delivery = 'express'),
          ),
          const SectionHeading(title: 'Phương thức thanh toán', action: null),
          _PaymentOption(
            id: 'cod',
            selected: _payment,
            title: 'Thanh toán khi nhận hàng',
            subtitle: 'Thanh toán bằng tiền mặt',
            icon: Icons.account_balance_wallet_outlined,
            onSelected: _selectPayment,
          ),
          _PaymentOption(
            id: 'bank',
            selected: _payment,
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'Hỗ trợ tất cả ngân hàng',
            icon: Icons.credit_card_outlined,
            onSelected: _selectPayment,
          ),
          _PaymentOption(
            id: 'ewallet',
            selected: _payment,
            title: 'Ví điện tử',
            subtitle: 'MoMo, ZaloPay, VNPay',
            icon: Icons.wallet_outlined,
            onSelected: _selectPayment,
          ),
          SectionHeading(
            title: 'Đơn hàng của bạn · ${widget.store.cartCount} sản phẩm',
            action: null,
          ),
          SizedBox(
            height: 65,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.store.cartLines.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final line = widget.store.cartLines[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 62,
                    height: 62,
                    child: ProductImage(imageUrl: line.product.imageUrl),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _CheckoutSummaryRow(
                    'Tạm tính',
                    formatVnd(widget.store.subtotal),
                  ),
                  const SizedBox(height: 9),
                  _CheckoutSummaryRow(
                    'Phí giao hàng',
                    formatVnd(deliveryPrice),
                  ),
                  const Divider(height: 20),
                  _CheckoutSummaryRow(
                    'Tổng cộng',
                    formatVnd(amount),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Ghi chú cho tài xế',
              hintText: 'Ví dụ: Gọi tôi khi đến nơi...',
            ),
          ),
        ],
      ),
      bottomNavigationBar: PageBottomAction(
        label: 'Đặt hàng',
        total: formatVnd(amount),
        onPressed: widget.store.cartLines.isEmpty ? null : _placeOrder,
      ),
    );
  }

  /// lưu phương thức thanh toán đang được người mua chọn.
  void _selectPayment(String value) => setState(() => _payment = value);

  /// kiểm tra thông tin cần thiết rồi tạo đơn hàng mẫu.
  void _placeOrder() {
    try {
      final order = widget.store.placeDemoOrder(
        deliveryFee: _delivery == 'standard' ? 10000 : 25000,
      );
      widget.onOrderPlaced(order);
    } on StateError catch (error) {
      showSmartMartNotice(
        context,
        message: error.message,
        icon: Icons.error_outline_rounded,
      );
    }
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.fee,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String fee;
  final IconData icon;
  final VoidCallback onTap;

  /// hiển thị một phương thức giao hàng cùng phí tương ứng.
  @override
  Widget build(BuildContext context) {
    return _OptionCard(
      selected: selected,
      onTap: onTap,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Text(
        fee,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.id,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
  });

  final String id;
  final String selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String> onSelected;

  /// dựng thẻ lựa chọn phương thức thanh toán bằng biểu tượng phù hợp.
  @override
  Widget build(BuildContext context) => _OptionCard(
    selected: selected == id,
    onTap: () => onSelected(id),
    icon: icon,
    title: title,
    subtitle: subtitle,
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  /// dựng thẻ tùy chọn và đánh dấu trạng thái đang được chọn.
  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? AppColors.blue50 : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 19,
                color: selected ? AppColors.blue700 : AppColors.muted,
              ),
              const SizedBox(width: 9),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.blue100,
                child: Icon(icon, color: AppColors.blue700, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSummaryRow extends StatelessWidget {
  const _CheckoutSummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  /// trình bày tên khoản thu và giá trị trong phần tổng kết.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.ink : AppColors.muted,
              fontSize: bold ? 12 : 10,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: bold ? AppColors.blue800 : AppColors.ink,
            fontSize: bold ? 14 : 10,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// thông báo kết quả đặt hàng và các lựa chọn tiếp theo.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    required this.order,
    required this.onContinueShopping,
    required this.onViewOrders,
    super.key,
  });

  final StoreOrder order;
  final VoidCallback onContinueShopping;
  final VoidCallback onViewOrders;

  /// dựng xác nhận thành công cùng nút xem đơn hoặc tiếp tục mua sắm.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: const BoxDecoration(
                    color: AppColors.blue100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 70,
                    color: AppColors.blue600,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Đặt hàng thành công!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Cảm ơn bạn đã mua sắm tại SSM4.\nĐơn hàng đang được chuẩn bị.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 23),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MÃ ĐƠN HÀNG',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '#${order.id}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Divider(height: 22),
                        const Text(
                          'Thời gian giao dự kiến',
                          style: TextStyle(color: AppColors.muted, fontSize: 9),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hôm nay, 16:30 – 17:00',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${order.lines.length} mặt hàng · ${formatVnd(order.total)}',
                          style: const TextStyle(
                            color: AppColors.blue800,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onViewOrders,
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Theo dõi đơn hàng'),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onContinueShopping,
                    child: const Text('Tiếp tục mua sắm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
