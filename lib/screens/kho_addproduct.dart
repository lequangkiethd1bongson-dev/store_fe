import 'dart:math';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/staff_controller.dart';
import '../theme/app_theme.dart';

/// Giao diện dành riêng cho Nhân viên Quản lý Kho thêm sản phẩm mới vào hệ thống.
class KhoAddProductScreen extends StatefulWidget {
  const KhoAddProductScreen({
    this.controller,
    this.onProductAdded,
    super.key,
  });

  final StaffController? controller;
  final ValueChanged<Product>? onProductAdded;

  @override
  State<KhoAddProductScreen> createState() => _KhoAddProductScreenState();
}

class _KhoAddProductScreenState extends State<KhoAddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _brandController = TextEditingController();
  final _packageSizeController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _importPriceController = TextEditingController();
  final _initialQuantityController = TextEditingController(text: '50');
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Rau củ quả';
  String _selectedShelf = 'A1';
  bool _isSubmitting = false;

  static const _categories = [
    'Rau củ quả',
    'Sữa & chế phẩm',
    'Nước giải khát',
    'Thịt tươi sống',
    'Gia vị & Đồ khô',
    'Thực phẩm đông lạnh',
    'Hàng tiêu dùng',
  ];

  static const _shelves = ['A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];

  // Image presets for quick selection
  static const _presetImages = [
    {'name': 'Rau củ tươi', 'url': 'assets/images/bannerThit.png'},
    {'name': 'Gia vị thực phẩm', 'url': 'assets/images/banner_giavi.png'},
    {'name': 'Logo siêu thị', 'url': 'assets/images/logosieuthi.png'},
  ];

  @override
  void initState() {
    super.initState();
    _generateRandomBarcode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _packageSizeController.dispose();
    _sellingPriceController.dispose();
    _importPriceController.dispose();
    _initialQuantityController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _generateRandomBarcode() {
    final random = Random();
    final code = '8938${100000000 + random.nextInt(899999999)}';
    setState(() {
      _barcodeController.text = code;
    });
  }

  Future<void> _submitForm() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await Future<void>.delayed(const Duration(milliseconds: 350));

    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();
    final brand = _brandController.text.trim();
    final packageSize = _packageSizeController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim().isEmpty
        ? 'assets/images/logosieuthi.png'
        : _imageUrlController.text.trim();

    final sellingPrice = int.tryParse(_sellingPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final importPrice = int.tryParse(_importPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final initialQuantity = int.tryParse(_initialQuantityController.text.trim()) ?? 50;

    final productId = 'prod_${DateTime.now().millisecondsSinceEpoch}';

    final newProduct = Product(
      id: productId,
      name: name,
      price: sellingPrice,
      importPrice: importPrice,
      oldPrice: sellingPrice > 0 ? (sellingPrice * 1.15).round() : null,
      rating: 5.0,
      category: _selectedCategory,
      imageUrl: imageUrl,
      barcode: barcode,
      brand: brand.isEmpty ? 'SSM4 Supermarket' : brand,
      packageSize: packageSize.isEmpty ? 'Gói / Hộp' : packageSize,
      description: description.isEmpty ? 'Sản phẩm mới nhập kho siêu thị SSM4.' : description,
      stock: initialQuantity,
    );

    final controller = widget.controller;
    if (controller != null) {
      controller.addProduct(newProduct);
      controller.receiveStock(newProduct, initialQuantity);
    }

    if (widget.onProductAdded != null) {
      widget.onProductAdded!(newProduct);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã nhập kho sản phẩm mới: "$name" ($initialQuantity sản phẩm)',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pop(newProduct);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thêm sản phẩm mới'),
            Text(
              'Giao diện Nhân viên Quản lý Kho',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Banner Kho
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue900, AppColors.blue700],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 26),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phiếu Tiếp Nhận Hàng Mới',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Nhập đầy đủ thông tin để lưu sản phẩm vào kho dự trữ',
                            style: TextStyle(color: Color(0xFFDCEBFA), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // KHỐI 1: THÔNG TIN SẢN PHẨM
              _SectionCard(
                title: '1. Thông tin cơ bản sản phẩm',
                icon: Icons.inventory_2_outlined,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm (*)',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      hintText: 'VD: Sữa tươi Vinamilk 100% 1L',
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Mã vạch / Barcode (*)',
                            prefixIcon: Icon(Icons.qr_code_2_rounded),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Vui lòng nhập mã vạch' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Tạo mã ngẫu nhiên',
                        onPressed: _generateRandomBarcode,
                        icon: const Icon(Icons.autorenew_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục / Nhóm hàng (*)',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: 'Thương hiệu',
                            prefixIcon: Icon(Icons.verified_outlined),
                            hintText: 'VD: Vinamilk',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _packageSizeController,
                          decoration: const InputDecoration(
                            labelText: 'Quy cách đóng gói',
                            prefixIcon: Icon(Icons.straighten_rounded),
                            hintText: 'VD: Hộp 1 Lít',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // KHỐI 2: GIÁ & TỒN KHO
              _SectionCard(
                title: '2. Giá cả & Tồn kho ban đầu',
                icon: Icons.payments_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá bán lẻ (VNĐ) (*)',
                            prefixIcon: Icon(Icons.sell_outlined),
                            hintText: 'VD: 36000',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Vui lòng nhập giá bán';
                            if (int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) == null) {
                              return 'Nhập số hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _importPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá nhập kho (VNĐ)',
                            prefixIcon: Icon(Icons.request_quote_outlined),
                            hintText: 'VD: 28000',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _initialQuantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số lượng nhập ban đầu (*)',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                          validator: (val) {
                            final num = int.tryParse(val ?? '');
                            if (num == null || num <= 0) return 'Số lượng > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedShelf,
                          decoration: const InputDecoration(
                            labelText: 'Kệ dự kiến',
                            prefixIcon: Icon(Icons.shelves),
                          ),
                          items: _shelves
                              .map((sh) => DropdownMenuItem(value: sh, child: Text('Kệ $sh')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedShelf = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // KHỐI 3: HÌNH ẢNH & MÔ TẢ
              _SectionCard(
                title: '3. Hình ảnh & Mô tả',
                icon: Icons.image_outlined,
                children: [
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Đường dẫn hình ảnh (URL / Asset)',
                      prefixIcon: Icon(Icons.link_rounded),
                      hintText: 'assets/images/logosieuthi.png',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hoặc chọn ảnh mẫu có sẵn:',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _presetImages
                        .map(
                          (preset) => ActionChip(
                            avatar: const Icon(Icons.image_search_rounded, size: 16),
                            label: Text(preset['name']!),
                            onPressed: () {
                              setState(() {
                                _imageUrlController.text = preset['url']!;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả chi tiết sản phẩm',
                      prefixIcon: Icon(Icons.notes_rounded),
                      hintText: 'Nhập xuất xứ, hạn sử dụng, hướng dẫn bảo quản...',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // NÚT XÁC NHẬN NỘP BẢN NHẬP KHO
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'ĐANG LƯU SẢN PHẨM...' : 'XÁC NHẬN THÊM VÀO KHO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.blue700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}
