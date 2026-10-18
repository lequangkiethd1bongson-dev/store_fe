import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_data.dart';
import '../models/store_models.dart';
import '../state/store_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// hiển thị các nhóm sản phẩm và banner quảng bá của danh mục.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    required this.onSelectCategory,
    this.categories = sampleCategories,
    super.key,
  });

  final ValueChanged<String> onSelectCategory;
  final List<ProductCategory> categories;

  /// dựng banner toàn chiều ngang và lưới danh mục sản phẩm.
  @override
  Widget build(BuildContext context) {
    final list = categories.isNotEmpty ? categories : sampleCategories;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _CategoryBannerCarousel(onSelectCategory: onSelectCategory),
        ),
        SliverAppBar(
          pinned: true,
          title: const Text('Danh mục'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.blue900,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.list(
            children: [
              const SectionHeading(title: 'Tất cả danh mục', action: null),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.12,
                ),
                itemBuilder: (context, index) {
                  final category = list[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onSelectCategory(category.name),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: _categoryColor(index),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.blue100),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue900.withValues(alpha: 0.07),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                category.emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              category.count,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// chọn màu nền luân phiên để phân biệt các thẻ danh mục.
  Color _categoryColor(int index) {
    if (index % 3 == 1) return const Color(0xFFFFF6E9);
    if (index % 3 == 2) return const Color(0xFFEEF5FF);
    return AppColors.blue50;
  }
}

class _CategoryBannerCarousel extends StatefulWidget {
  const _CategoryBannerCarousel({required this.onSelectCategory});

  final ValueChanged<String> onSelectCategory;

  /// tạo trạng thái lưu trang banner hiện tại.
  @override
  State<_CategoryBannerCarousel> createState() =>
      _CategoryBannerCarouselState();
}

class _CategoryBannerCarouselState extends State<_CategoryBannerCarousel> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = <(String, String, String, String?)>[
    (
      'Bữa ăn tươi ngon,\nđủ đầy dinh dưỡng',
      'Khám phá rau củ quả tươi mỗi ngày',
      'Rau củ quả',
      null,
    ),
    (
      'Thịt cá tươi ngon\ncho cả gia đình',
      'Chọn nguyên liệu ngon cho bữa cơm',
      'Thịt cá',
      'assets/images/bannerThit.png',
    ),
    (
      'Đậm đà vị bếp,\nngon tròn món ăn',
      'Khám phá các loại gia vị yêu thích',
      'Gia vị',
      'assets/images/banner_giavi.png',
    ),
  ];

  /// giải phóng bộ điều khiển vuốt trang khi banner bị gỡ khỏi giao diện.
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// dựng banner vuốt ngang và cập nhật chỉ báo trang đang xem.
  @override
  Widget build(BuildContext context) {
    final bannerHeight = (MediaQuery.sizeOf(context).height / 3)
        .clamp(220.0, 320.0)
        .toDouble();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: SizedBox(
        key: const ValueKey('category-promo-banner'),
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const ValueKey('category-banner-pages'),
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (slide.$4 != null)
                      Image.asset(slide.$4!, fit: BoxFit.cover)
                    else
                      Image.network(
                        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=85',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(color: AppColors.blue800),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xF20B2E59),
                            Color(0xA60B2E59),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: [0, 0.62, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.paddingOf(context).top + 48,
                        20,
                        16,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GỢI Ý HÔM NAY',
                                style: TextStyle(
                                  color: Color(0xFFB9E1FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                slide.$1,
                                key: ValueKey('category-promo-title-$index'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slide.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 9),
                              FilledButton.icon(
                                key: ValueKey('category-promo-buy-${slide.$3}'),
                                onPressed: () =>
                                    widget.onSelectCategory(slide.$3),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.blue900,
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 17,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 19,
                                ),
                                label: const Text('Khám phá ngay'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 0,
              right: 0,
              child: const IgnorePointer(
                child: Center(
                  child: Text(
                    'Danh mục',
                    key: ValueKey('category-banner-heading'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Color(0x99000000), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final selected = index == _currentPage;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: 'Banner ${index + 1}',
                    child: InkWell(
                      key: ValueKey('category-promo-dot-$index'),
                      onTap: () => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: selected ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: selected ? 1 : 0.58,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// liệt kê sản phẩm theo nhóm và tiêu chí lọc được chọn.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    required this.store,
    required this.category,
    required this.onOpenProduct,
    required this.onOpenCart,
    super.key,
  });

  final StoreController store;
  final String category;
  final ValueChanged<Product> onOpenProduct;
  final VoidCallback onOpenCart;

  /// tạo trạng thái lưu bộ lọc đang áp dụng.
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _query = '';
  bool _sortByPrice = false;

  /// dựng danh sách sản phẩm phù hợp với nhóm hàng đã chọn.
  @override
  Widget build(BuildContext context) {
    final visibleProducts = widget.store.products.where((product) {
      final matchesCategory =
          widget.category == 'Rau củ quả' ||
          product.category == widget.category;
      final matchesQuery = product.name.toLowerCase().contains(
        _query.toLowerCase(),
      );
      return matchesCategory && matchesQuery;
    }).toList();
    if (_sortByPrice) {
      visibleProducts.sort((a, b) => a.price.compareTo(b.price));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.category),
        actions: [
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: widget.onOpenCart,
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SearchField(
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showFilter(context),
                    icon: const Icon(Icons.tune_rounded, size: 17),
                    label: const Text('Bộ lọc'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _sortByPrice = !_sortByPrice),
                    icon: const Icon(Icons.swap_vert_rounded, size: 17),
                    label: Text(_sortByPrice ? 'Giá thấp' : 'Phổ biến'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text(
                  '${visibleProducts.length} sản phẩm',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Sản phẩm tươi mới mỗi ngày',
                  style: TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleProducts.isEmpty
                ? const Center(child: Text('Không tìm thấy sản phẩm phù hợp'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: visibleProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.67,
                        ),
                    itemBuilder: (context, index) => ProductCard(
                      product: visibleProducts[index],
                      store: widget.store,
                      onTap: () => widget.onOpenProduct(visibleProducts[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// mở bộ lọc để người dùng chọn cách sắp xếp sản phẩm.
  void _showFilter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bộ lọc sản phẩm',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tình trạng',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('Còn hàng')),
                  Chip(label: Text('Đang khuyến mãi')),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// trình bày thông tin và thao tác mua một sản phẩm cụ thể.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    required this.store,
    required this.product,
    required this.onCheckout,
    required this.onOpenCart,
    required this.onOpenProduct,
    super.key,
  });

  final StoreController store;
  final Product product;
  final VoidCallback onCheckout;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onOpenProduct;

  /// tạo trạng thái cho số lượng sản phẩm và hoạt ảnh thêm giỏ.
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  int _quantity = 1;
  bool _isFavorite = false;
  final _cartTargetKey = GlobalKey();
  final _addToCartKey = GlobalKey();
  final _buyNowKey = GlobalKey();
  late final AnimationController _flyController;
  OverlayEntry? _flyingProduct;

  /// khởi tạo các bộ điều khiển phục vụ hoạt ảnh trên trang chi tiết.
  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  /// giải phóng tài nguyên hoạt ảnh khi đóng trang chi tiết.
  @override
  void dispose() {
    _flyingProduct?.remove();
    _flyController.dispose();
    super.dispose();
  }

  /// dựng ảnh, thông tin, số lượng và các nút thao tác sản phẩm.
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            leading: IconButton.filledTonal(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton.filledTonal(
                tooltip: _isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                onPressed: () => setState(() => _isFavorite = !_isFavorite),
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite ? Colors.redAccent : null,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Chia sẻ sản phẩm',
                onPressed: () => _showShareSheet(context, product),
                icon: const Icon(Icons.share_outlined),
              ),
              IconButton.filledTonal(
                key: _cartTargetKey,
                tooltip: 'Mở giỏ hàng',
                onPressed: widget.onOpenCart,
                icon: Badge(
                  isLabelVisible: widget.store.cartCount > 0,
                  label: Text('${widget.store.cartCount}'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImage(imageUrl: product.imageUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.brand ?? 'SMARTMART',
                        style: const TextStyle(
                          color: AppColors.blue700,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Còn hàng',
                          style: TextStyle(
                            color: AppColors.blue700,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFE49A1B),
                        size: 16,
                      ),
                      Text(
                        ' ${product.rating} ',
                        style: const TextStyle(
                          color: Color(0xFFE49A1B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '128 đánh giá  ·  Đã bán 1.2k',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      Text(
                        formatVnd(product.price),
                        style: const TextStyle(
                          color: AppColors.blue800,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (product.oldPrice case final oldPrice?) ...[
                        Text(
                          formatVnd(oldPrice),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (product.discountPercent case final discount?)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1DF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tiết kiệm $discount%',
                              style: const TextStyle(
                                color: Color(0xFFD26F13),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.blue600,
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cam kết tươi ngon',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Hoàn tiền nếu sản phẩm không đạt chất lượng',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số lượng',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Còn ${product.stock} sản phẩm',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _QuantityStepper(
                        value: _quantity,
                        onChanged: (value) => setState(() => _quantity = value),
                      ),
                    ],
                  ),
                  const Divider(height: 26),
                  const Text(
                    'Thông tin sản phẩm',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? '',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.65,
                    ),
                  ),
                  const SectionHeading(
                    title: 'Có thể bạn cũng thích',
                    action: 'Xem tất cả',
                  ),
                  SizedBox(
                    height: 255,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.store.products.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = widget.store.products[index];
                        return SizedBox(
                          width: 150,
                          child: ProductCard(
                            product: item,
                            store: widget.store,
                            onTap: () => widget.onOpenProduct(item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              IconButton.filledTonal(
                key: _buyNowKey,
                tooltip: 'Mua ngay',
                onPressed: () =>
                    _addToCart(sourceKey: _buyNowKey, checkout: true),
                icon: const Icon(Icons.flash_on_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: _addToCartKey,
                  onPressed: () => _addToCart(sourceKey: _addToCartKey),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Thêm vào giỏ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// thêm số lượng đã chọn vào giỏ và phát hiệu ứng phản hồi cho người dùng.
  Future<void> _addToCart({
    required GlobalKey sourceKey,
    bool checkout = false,
  }) async {
    widget.store.addToCart(widget.product, quantity: _quantity);
    if (mounted) setState(() {});
    final sourceContext = sourceKey.currentContext;
    final targetContext = _cartTargetKey.currentContext;
    final overlay = Overlay.maybeOf(context);
    final overlayRenderObject = overlay?.context.findRenderObject();
    final sourceRenderObject = sourceContext?.findRenderObject();
    final targetRenderObject = targetContext?.findRenderObject();

    if (overlay != null &&
        overlayRenderObject is RenderBox &&
        sourceRenderObject is RenderBox &&
        targetRenderObject is RenderBox) {
      final overlayBox = overlayRenderObject;
      final start = overlayBox.globalToLocal(
        sourceRenderObject.localToGlobal(
          sourceRenderObject.size.center(Offset.zero),
        ),
      );
      final end = overlayBox.globalToLocal(
        targetRenderObject.localToGlobal(
          targetRenderObject.size.center(Offset.zero),
        ),
      );
      _flyingProduct?.remove();
      _flyController
        ..stop()
        ..reset();
      _flyingProduct = OverlayEntry(
        builder: (context) => AnimatedBuilder(
          animation: _flyController,
          builder: (context, child) {
            final progress = Curves.easeInOutCubic.transform(
              _flyController.value,
            );
            final position =
                Offset.lerp(start, end, progress)! -
                Offset(0, 75 * math.sin(math.pi * progress));
            return Stack(
              children: [
                Positioned(
                  left: position.dx - 23,
                  top: position.dy - 23,
                  width: 46,
                  height: 46,
                  child: Opacity(
                    opacity: 1 - (progress * 0.22),
                    child: Material(
                      key: const ValueKey('flying-product-image'),
                      elevation: 8,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: ProductImage(
                        imageUrl: widget.product.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
      overlay.insert(_flyingProduct!);
      await _flyController.forward();
      _flyingProduct?.remove();
      _flyingProduct = null;
    }

    if (!mounted) return;
    if (checkout) {
      widget.onCheckout();
      return;
    }
    showSmartMartNotice(
      context,
      message: 'Đã thêm ${widget.product.name} vào giỏ hàng',
      icon: Icons.shopping_bag_outlined,
    );
  }

  /// mở bảng chia sẻ thông tin sản phẩm.
  void _showShareSheet(BuildContext context, Product product) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            key: const ValueKey('product-share-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chia sẻ sản phẩm',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${product.name} · ${formatVnd(product.price)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: '${product.name} - ${formatVnd(product.price)}',
                      ),
                    );
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    showSmartMartNotice(
                      context,
                      message: 'Đã sao chép thông tin sản phẩm',
                      icon: Icons.content_copy_rounded,
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Sao chép thông tin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  /// dựng bộ điều khiển tăng giảm số lượng sản phẩm.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(value > 1 ? value - 1 : 1),
            icon: const Icon(Icons.remove, size: 16),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }
}
