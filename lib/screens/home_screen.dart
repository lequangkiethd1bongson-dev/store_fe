import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/store_models.dart';
import '../state/store_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// dựng trang chủ cửa hàng với tìm kiếm, banner và nhóm sản phẩm nổi bật.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.store,
    required this.onOpenProducts,
    required this.onOpenCategories,
    required this.onOpenProduct,
    required this.onOpenMenu,
    required this.onOpenCart,
    super.key,
  });

  final StoreController store;
  final ValueChanged<String> onOpenProducts;
  final VoidCallback onOpenCategories;
  final ValueChanged<Product> onOpenProduct;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenCart;

  /// tạo trạng thái quản lý nội dung và địa chỉ trên trang chủ.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _promoController = PageController();
  final _savedAddresses = <String>[
    '21 Nguyễn Huệ, Quận 1',
    'Ký túc xá, TP. Thủ Đức',
  ];
  String _selectedAddress = '21 Nguyễn Huệ, Quận 1';
  String _searchQuery = '';
  int _promoIndex = 0;
  bool _showPromo = false;

  /// khởi tạo bộ điều khiển tìm kiếm và dữ liệu giao diện của trang.
  ///
  /// BƯỚC 6 — sau khung hình đầu tiên thì gọi tải sản phẩm từ backend.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showPromo = true);
      if (!widget.store.loadedFromApi) widget.store.loadProducts();
    });
  }

  /// giải phóng bộ điều khiển tìm kiếm khi rời trang chủ.
  @override
  void dispose() {
    _searchController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  /// mở hộp thoại để chọn một địa chỉ giao hàng đã lưu.
  Future<void> _showAddressPicker() async {
    final address = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Chọn địa chỉ giao hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ..._savedAddresses.map(
                  (savedAddress) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.blue700,
                    ),
                    title: Text(savedAddress),
                    trailing: savedAddress == _selectedAddress
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.blue700,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(savedAddress),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.add_location_alt_outlined,
                    color: AppColors.blue700,
                  ),
                  title: const Text('Thêm địa chỉ mới'),
                  onTap: () async {
                    final newAddress = await _requestNewAddress();
                    if (!mounted || newAddress == null) return;
                    setState(() => _savedAddresses.add(newAddress));
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (address != null && mounted) {
      setState(() => _selectedAddress = address);
    }
  }

  /// yêu cầu nhập địa chỉ mới và trả về nội dung sau khi xác nhận.
  Future<String?> _requestNewAddress() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _AddAddressDialog(),
    );
  }

  /// dựng trang chủ, gồm đầu trang ghim khi cuộn và các khu vực sản phẩm.
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _CollapsingHomeHeader(
            selectedAddress: _selectedAddress,
            onOpenMenu: widget.onOpenMenu,
            onAddressTap: _showAddressPicker,
            onNotificationsTap: () =>
                _showHeaderMessage('Thông báo mới sẽ hiển thị tại đây.'),
            onNotesTap: () =>
                _showHeaderMessage('Ghi chú mua sắm sẽ sớm có mặt.'),
            searchController: _searchController,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            searchQuery: _searchQuery.trim(),
            topInset: topInset,
            promoController: _promoController,
            promoIndex: _promoIndex,
            onPromoChanged: (index) => setState(() => _promoIndex = index),
            onOpenProducts: widget.onOpenProducts,
            showPromo: _showPromo,
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
            decoration: const BoxDecoration(color: AppColors.canvas),
            child: Column(
              children: [
                SectionHeading(
                  title: 'Danh mục',
                  action: 'Xem thêm',
                  onAction: widget.onOpenCategories,
                ),
                _QuickCategories(
                  categories: widget.store.categories,
                  onSelect: (category) => widget.onOpenProducts(category.name),
                ),
                SectionHeading(
                  title: 'Mua lại lần trước',
                  action: 'Giỏ hàng',
                  onAction: widget.onOpenCart,
                ),
                _QuickReorder(
                  products: widget.store.cartLines
                      .map((line) => line.product)
                      .toList(),
                  store: widget.store,
                ),
                SectionHeading(
                  title: 'Ưu đãi dành cho bạn',
                  action: 'Khám phá',
                  onAction: () => widget.onOpenProducts('Rau củ quả'),
                ),
                _DealsCarousel(onOpenProducts: widget.onOpenProducts),
                SectionHeading(
                  title: 'Khuyến mãi hôm nay',
                  action: 'Xem tất cả',
                  onAction: () => widget.onOpenProducts('Rau củ quả'),
                ),
                _HorizontalProducts(
                  products: widget.store.products.take(4).toList(),
                  store: widget.store,
                  onOpenProduct: widget.onOpenProduct,
                ),
                SectionHeading(
                  title: 'Phổ biến tuần này',
                  action: 'Xem tất cả',
                  onAction: () => widget.onOpenProducts('Rau củ quả'),
                ),
                _ProductGrid(
                  products: widget.store.products.take(4).toList(),
                  store: widget.store,
                  onOpenProduct: widget.onOpenProduct,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// hiện thông báo ngắn ở đầu nội dung trang chủ.
  void _showHeaderMessage(String message) {
    showSmartMartNotice(
      context,
      message: message,
      icon: Icons.notifications_active_outlined,
    );
  }
}

class _CollapsingHomeHeader extends SliverPersistentHeaderDelegate {
  const _CollapsingHomeHeader({
    required this.selectedAddress,
    required this.onOpenMenu,
    required this.onAddressTap,
    required this.onNotificationsTap,
    required this.onNotesTap,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchQuery,
    required this.topInset,
    required this.promoController,
    required this.promoIndex,
    required this.onPromoChanged,
    required this.onOpenProducts,
    required this.showPromo,
  });

  final String selectedAddress;
  final VoidCallback onOpenMenu;
  final VoidCallback onAddressTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onNotesTap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;
  final double topInset;
  final PageController promoController;
  final int promoIndex;
  final ValueChanged<int> onPromoChanged;
  final ValueChanged<String> onOpenProducts;
  final bool showPromo;

  bool get _hasSearchResultsPanel => searchQuery.isNotEmpty;

  double get _searchExtent => _hasSearchResultsPanel ? 148 : 76;

  @override
  double get minExtent => topInset + (_hasSearchResultsPanel ? 166 : 100);

  @override
  double get maxExtent => _searchExtent + 250 + topInset;

  /// dựng phần đầu co giãn nhưng giữ thanh tìm kiếm hiển thị khi cuộn.
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bottomRadius = Radius.circular(28 - (10 * progress));
    final searchTop = topInset + 80 - 52 * progress;
    final searchQueryTop = topInset + 144 - 52 * progress;
    final informationTop = topInset + 8 - 25 * progress;

    return Material(
      elevation: overlapsContent ? 3 : 0,
      shadowColor: AppColors.blue900.withValues(alpha: 0.14),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final greenHeight = (constraints.maxHeight - 84)
                .clamp(minExtent, maxExtent)
                .toDouble();
            return Stack(
              key: const ValueKey('home-collapsing-header'),
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: greenHeight,
                  child: DecoratedBox(
                    key: const ValueKey('home-header-blue-background'),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue900, AppColors.blue700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: bottomRadius),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  height: 168,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    opacity: showPromo ? 1 - progress : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      offset: showPromo
                          ? Offset(0, progress * 0.12)
                          : const Offset(0, 0.08),
                      child: _PromoBanner(
                        controller: promoController,
                        currentIndex: promoIndex,
                        onPageChanged: onPromoChanged,
                        onOpenProducts: onOpenProducts,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: informationTop,
                  child: Opacity(
                    opacity: (1 - progress * 1.45).clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: progress > 0.82,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SmartMartLogo(
                                compact: true,
                                logoSize: 60,
                                onTap: onOpenMenu,
                                onDark: true,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'SSM4',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    InkWell(
                                      key: const ValueKey(
                                        'home-address-selector',
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: onAddressTap,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selectedAddress,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFFD6E8FF),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Color(0xFFD6E8FF),
                                            size: 17,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              _HeaderActionButton(
                                tooltip: 'Thông báo',
                                icon: Icons.notifications_none_rounded,
                                onPressed: onNotificationsTap,
                              ),
                              const SizedBox(width: 8),
                              _HeaderActionButton(
                                tooltip: 'Ghi chú',
                                icon: Icons.note_alt_outlined,
                                onPressed: onNotesTap,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: searchTop,
                  height: 56,
                  child: SearchField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                  ),
                ),
                if (_hasSearchResultsPanel)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: searchQueryTop,
                    height: 62,
                    child: _SearchEmptyState(query: searchQuery),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// yêu cầu dựng lại phần đầu khi các thông số kích thước thay đổi.
  @override
  bool shouldRebuild(_CollapsingHomeHeader oldDelegate) =>
      oldDelegate.selectedAddress != selectedAddress ||
      oldDelegate.searchQuery != searchQuery ||
      oldDelegate.searchController != searchController ||
      oldDelegate.onSearchChanged != onSearchChanged ||
      oldDelegate.onOpenMenu != onOpenMenu ||
      oldDelegate.onAddressTap != onAddressTap ||
      oldDelegate.onNotificationsTap != onNotificationsTap ||
      oldDelegate.onNotesTap != onNotesTap ||
      oldDelegate.promoController != promoController ||
      oldDelegate.promoIndex != promoIndex ||
      oldDelegate.onPromoChanged != onPromoChanged ||
      oldDelegate.onOpenProducts != onOpenProducts ||
      oldDelegate.showPromo != showPromo;
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  /// tạo nút thao tác nhỏ nằm trong phần đầu trang chủ.
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
    );
  }
}

/// nhập và xác nhận địa chỉ mới trong một hộp thoại.
class _AddAddressDialog extends StatefulWidget {
  const _AddAddressDialog();

  /// tạo trạng thái biểu mẫu nhập địa chỉ.
  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _controller = TextEditingController();

  /// giải phóng bộ điều khiển địa chỉ khi hộp thoại đóng.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// dựng biểu mẫu nhập địa chỉ và nút xác nhận.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm địa chỉ mới'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Nhập địa chỉ giao hàng'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) Navigator.of(context).pop(value);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  /// hiển thị hướng dẫn khi không tìm thấy sản phẩm phù hợp.
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-search-results'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue900.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.muted,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Chưa có sản phẩm phù hợp với “$query”',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onOpenProducts,
  });

  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onOpenProducts;

  /// dựng vùng banner quảng bá dạng vuốt ngang.
  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('home-promo-banner'),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView(
              controller: controller,
              onPageChanged: onPageChanged,
              children: [
                _PromoSlide(
                  title: 'Tươi ngon mỗi ngày',
                  subtitle: 'Giảm đến 30% rau củ',
                  category: 'Rau củ quả',
                  imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=85',
                  onOpenProducts: onOpenProducts,
                ),
                _PromoSlide(
                  title: 'Thịt cá tươi ngon',
                  subtitle: 'Chọn món ngon cho cả nhà',
                  category: 'Thịt cá',
                  assetPath: 'assets/images/bannerThit.png',
                  onOpenProducts: onOpenProducts,
                ),
                _PromoSlide(
                  title: 'Đậm đà vị bếp',
                  subtitle: 'Khám phá gia vị cho món ngon',
                  category: 'Gia vị',
                  assetPath: 'assets/images/banner_giavi.png',
                  isSpicePlaceholder: true,
                  onOpenProducts: onOpenProducts,
                ),
              ],
            ),
            Positioned(
              bottom: 9,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      key: ValueKey('promo-page-dot-$index'),
                      onTap: () => controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == currentIndex ? 14 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: index == currentIndex ? 1 : 0.6,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoSlide extends StatelessWidget {
  const _PromoSlide({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.onOpenProducts,
    this.imageUrl,
    this.assetPath,
    this.isSpicePlaceholder = false,
  });

  final String title;
  final String subtitle;
  final String category;
  final ValueChanged<String> onOpenProducts;
  final String? imageUrl;
  final String? assetPath;
  final bool isSpicePlaceholder;

  /// trình bày nội dung, hình ảnh và nút của một trang banner.
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (assetPath != null)
          Image.asset(assetPath!, fit: BoxFit.cover)
        else if (imageUrl != null)
          ProductImage(imageUrl: imageUrl!)
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8D451F),
                  Color(0xFFD99748),
                  Color(0xFF5B3021),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 20),
                child: Text('🧂 🌶️ 🫙', style: TextStyle(fontSize: 34)),
              ),
            ),
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
              stops: [0, 0.57, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 12, 12, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSpicePlaceholder ? 'GIAN HÀNG GIA VỊ' : 'ƯU ĐÃI THÀNH VIÊN',
                style: const TextStyle(
                  color: Color(0xFFD6E8FF),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              const SizedBox(height: 6),
              GlassButton(
                key: ValueKey('promo-buy-$category'),
                label: 'Mua ngay',
                icon: Icons.chevron_right,
                onPressed: () => onOpenProducts(category),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickCategories extends StatefulWidget {
  const _QuickCategories({
    required this.categories,
    required this.onSelect,
  });

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onSelect;

  /// tạo trạng thái cho danh sách danh mục cuộn ngang.
  @override
  State<_QuickCategories> createState() => _QuickCategoriesState();
}

class _QuickCategoriesState extends State<_QuickCategories> {
  int _selectedIndex = 0;

  /// dựng các nút danh mục nhanh trên trang chủ.
  @override
  Widget build(BuildContext context) {
    final categoryList = widget.categories.isNotEmpty ? widget.categories : sampleCategories;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categoryList.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categoryList[index];
          final isSelected = _selectedIndex == index;
          return Semantics(
            button: true,
            selected: isSelected,
            label: category.name,
            child: InkWell(
              key: ValueKey('home-category-${category.name}'),
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() => _selectedIndex = index);
                widget.onSelect(category);
              },
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.fromLTRB(5, 9, 5, 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.blue800, AppColors.blue600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.line,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue900.withValues(
                          alpha: isSelected ? 0.15 : 0.04,
                        ),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.08 : 1,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        child: Text(
                          category.emoji,
                          style: const TextStyle(fontSize: 31),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.ink,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickReorder extends StatelessWidget {
  const _QuickReorder({required this.products, required this.store});

  final List<Product> products;
  final StoreController store;

  /// hiển thị lối tắt mua lại các sản phẩm đã chọn.
  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.shopping_bag_outlined, color: AppColors.blue700),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sản phẩm bạn thêm vào giỏ sẽ xuất hiện ở đây.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 246,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue900.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 66,
                    height: 72,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatVnd(product.price),
                        style: const TextStyle(
                          color: AppColors.blue800,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  tooltip: 'Mua lại ${product.name}',
                  onPressed: () => store.addToCart(product),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.blue50,
                    foregroundColor: AppColors.blue700,
                    fixedSize: const Size(34, 34),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DealsCarousel extends StatelessWidget {
  const _DealsCarousel({required this.onOpenProducts});

  final ValueChanged<String> onOpenProducts;

  static const _deals = <(String, String, IconData, String, Color)>[
    (
      'Giảm đến 30%',
      'Rau củ tươi mỗi ngày',
      Icons.eco_outlined,
      'Rau củ quả',
      AppColors.blue800,
    ),
    (
      'Tươi ngon chuẩn vị',
      'Thịt cá chọn lọc',
      Icons.set_meal_outlined,
      'Thịt cá',
      AppColors.blue700,
    ),
    (
      'Đậm đà món ngon',
      'Gia vị cho cả nhà',
      Icons.soup_kitchen_outlined,
      'Gia vị',
      AppColors.blue900,
    ),
  ];

  /// dựng dải sản phẩm ưu đãi để người dùng vuốt xem.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _deals.length,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final deal = _deals[index];
          return Material(
            color: deal.$5,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('home-deal-${deal.$1}'),
              onTap: () => onOpenProducts(deal.$4),
              child: SizedBox(
                width: 226,
                child: Stack(
                  children: [
                    Positioned(
                      right: -14,
                      bottom: -25,
                      child: Icon(
                        deal.$3,
                        size: 114,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            deal.$3,
                            color: Colors.white.withValues(alpha: 0.88),
                            size: 21,
                          ),
                          const Spacer(),
                          Text(
                            deal.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            deal.$2,
                            style: const TextStyle(
                              color: Color(0xFFD6E8FF),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalProducts extends StatelessWidget {
  const _HorizontalProducts({
    required this.products,
    required this.store,
    required this.onOpenProduct,
  });

  final List<Product> products;
  final StoreController store;
  final ValueChanged<Product> onOpenProduct;

  /// hiển thị một nhóm sản phẩm theo hàng ngang.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 264,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (context, index) => SizedBox(
          width: 156,
          child: ProductCard(
            product: products[index],
            store: store,
            onTap: () => onOpenProduct(products[index]),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.store,
    required this.onOpenProduct,
  });

  final List<Product> products;
  final StoreController store;
  final ValueChanged<Product> onOpenProduct;

  /// dựng lưới sản phẩm theo số cột phù hợp với chiều rộng màn hình.
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 286,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          store: store,
          onTap: () => onOpenProduct(product),
        );
      },
    );
  }
}
