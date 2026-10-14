import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../state/store_controller.dart';
import '../theme/app_theme.dart';

/// hiện thông báo ngắn có biểu tượng và hành động tùy chọn.
void showSmartMartNotice(
  BuildContext context, {
  required String message,
  IconData icon = Icons.check_circle_outline_rounded,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      elevation: 8,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      content: Row(
        children: [
          Icon(icon, color: AppColors.blue700, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: AppColors.blue700,
              onPressed: onAction ?? () {},
            ),
    ),
  );
}

/// hiển thị logo ssm4 theo kích thước và nền được yêu cầu.
class SmartMartLogo extends StatelessWidget {
  const SmartMartLogo({
    super.key,
    this.compact = false,
    this.onTap,
    this.onDark = false,
    this.logoSize,
  });

  final bool compact;
  final VoidCallback? onTap;
  final bool onDark;
  final double? logoSize;

  /// dựng logo theo kích thước, chế độ nền và thao tác được truyền vào.
  @override
  Widget build(BuildContext context) {
    final imageSize = logoSize ?? (compact ? 42.0 : 48.0);
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_ssms4.png',
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
              Container(
                width: imageSize,
                height: imageSize,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: onDark ? Colors.transparent : AppColors.blue700,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: child,
              ),
        ),
        if (!compact) ...[
          const SizedBox(width: 7),
          Text(
            'SSM4',
            style: TextStyle(
              color: onDark ? Colors.white : AppColors.blue900,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
        ],
      ],
    );
    if (onTap == null) return logo;
    return Semantics(
      button: true,
      label: 'Mở menu tài khoản',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(2), child: logo),
      ),
    );
  }
}

/// tạo nút kính mờ có nhãn và biểu tượng tùy chọn.
class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// dựng nút kính mờ có hiệu ứng nền, viền và bóng nhẹ.
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.55),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue900.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: AppColors.blue800),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.blue900,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// hiển thị tiêu đề khu vực cùng nút hành động tùy chọn.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  /// dựng tiêu đề khu vực và thêm liên kết nếu được cung cấp.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blue700,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// tạo ô tìm kiếm và chuyển nội dung nhập về nơi sử dụng.
class SearchField extends StatelessWidget {
  const SearchField({
    this.controller,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  /// dựng ô tìm kiếm và chuyển thao tác nhập về callback tương ứng.
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Bạn muốn tìm gì?',
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 21),
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFDCE7F4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFDCE7F4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.blue600, width: 1.4),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(5),
          child: IconButton.filled(
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: AppColors.blue700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
          ),
        ),
      ),
    );
  }
}

/// trình bày ảnh, tên, giá và nút thêm giỏ của một sản phẩm.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.store,
    required this.onTap,
    super.key,
  });

  final Product product;
  final StoreController store;
  final VoidCallback onTap;

  /// dựng thẻ sản phẩm và kết nối nút thêm vào giỏ hàng.
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onTap,
                child: AspectRatio(
                  aspectRatio: 1.25,
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFE49A1B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatVnd(product.price),
                        style: const TextStyle(
                          color: AppColors.blue800,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (product.oldPrice case final oldPrice?)
                        Text(
                          formatVnd(oldPrice),
                          style: const TextStyle(
                            color: Color(0xFF9BA49F),
                            fontSize: 9,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (product.discountPercent case final discount?)
            Positioned(
              left: 8,
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 8,
            top: 7,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white.withValues(alpha: 0.92),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 17,
                color: AppColors.muted,
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: IconButton.filled(
              onPressed: () {
                store.addToCart(product);
                showSmartMartNotice(
                  context,
                  message: 'Đã thêm ${product.name} vào giỏ hàng',
                  icon: Icons.shopping_bag_outlined,
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.blue100,
                foregroundColor: AppColors.blue700,
                fixedSize: const Size(35, 35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// tải ảnh sản phẩm từ mạng và dùng nội dung thay thế khi cần.
class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;

  /// tải ảnh sản phẩm và hiển thị khung thay thế khi cần.
  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const NetworkImagePlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const NetworkImagePlaceholder();
      },
    );
  }
}

/// dựng khung giả lập mờ khi ảnh đang tải hoặc không tải được.
class NetworkImagePlaceholder extends StatelessWidget {
  const NetworkImagePlaceholder({super.key});

  /// dựng các khối mờ cùng logo ở giữa làm trạng thái chờ ảnh.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        color: const Color(0xFFE7EFF8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: constraints.maxWidth * 0.08,
              top: constraints.maxHeight * 0.12,
              child: _placeholderBlock(
                constraints.maxWidth * 0.33,
                constraints.maxHeight * 0.2,
              ),
            ),
            Positioned(
              right: constraints.maxWidth * 0.08,
              top: constraints.maxHeight * 0.12,
              child: _placeholderBlock(
                constraints.maxWidth * 0.43,
                constraints.maxHeight * 0.2,
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.08,
              bottom: constraints.maxHeight * 0.12,
              child: _placeholderBlock(
                constraints.maxWidth * 0.43,
                constraints.maxHeight * 0.2,
              ),
            ),
            Positioned(
              right: constraints.maxWidth * 0.08,
              bottom: constraints.maxHeight * 0.12,
              child: _placeholderBlock(
                constraints.maxWidth * 0.33,
                constraints.maxHeight * 0.2,
              ),
            ),
            Center(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.blue800.withValues(alpha: 0.74),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo_ssms4.png',
                    width: constraints.maxWidth * 0.24,
                    height: constraints.maxHeight * 0.42,
                    fit: BoxFit.contain,
                    opacity: const AlwaysStoppedAnimation(0.78),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// tạo một khối nền riêng trong khung chờ ảnh.
  Widget _placeholderBlock(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}

/// tổng hợp tiền hàng, phí giao và số tiền phải trả.
class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({required this.store, super.key});

  final StoreController store;

  /// trình bày tiền hàng, phí giao và tổng thanh toán.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết thanh toán',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Tạm tính', value: formatVnd(store.subtotal)),
            const SizedBox(height: 9),
            _SummaryRow(
              label: 'Phí giao hàng',
              value: formatVnd(store.deliveryFee),
            ),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Tổng cộng',
              value: formatVnd(store.total),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  /// trình bày một nhãn và giá trị trong bảng tổng tiền.
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: emphasized ? AppColors.blue800 : AppColors.ink,
      fontSize: emphasized ? 14 : 11,
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? AppColors.ink : AppColors.muted,
              fontSize: style.fontSize,
            ),
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}

/// hiển thị thông tin địa chỉ và thao tác liên quan.
class AddressCard extends StatelessWidget {
  const AddressCard({super.key});

  /// dựng thẻ địa chỉ giao hàng đang được minh họa.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.blue700,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nguyễn Minh Anh  ·  Nhà riêng',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 5),
                  Text('090 123 4567', style: TextStyle(fontSize: 10)),
                  SizedBox(height: 4),
                  Text(
                    '21 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 19),
          ],
        ),
      ),
    );
  }
}

/// đặt nút hành động ở cuối màn hình bên dưới phần nội dung.
class PageBottomAction extends StatelessWidget {
  const PageBottomAction({
    required this.label,
    required this.total,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String total;
  final VoidCallback? onPressed;

  /// dựng vùng tổng tiền và nút hành động cố định cuối trang.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total,
                    style: const TextStyle(
                      color: AppColors.blue800,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: onPressed, child: Text(label)),
          ],
        ),
      ),
    );
  }
}
