import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/staff_controller.dart';
import '../theme/app_theme.dart';

/// Giao diện dành riêng cho Nhân viên Quản lý Kho chỉnh sửa hoặc xóa sản phẩm.
class KhoEditProductScreen extends StatefulWidget {
  const KhoEditProductScreen({
    required this.product,
    this.controller,
    this.onProductUpdated,
    this.onProductDeleted,
    super.key,
  });

  final Product product;
  final StaffController? controller;
  final ValueChanged<Product>? onProductUpdated;
  final ValueChanged<String>? onProductDeleted;

  @override
  State<KhoEditProductScreen> createState() => _KhoEditProductScreenState();
}

class _KhoEditProductScreenState extends State<KhoEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _brandController;
  late final TextEditingController _packageSizeController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _importPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  late String _selectedCategory;
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

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _barcodeController = TextEditingController(text: p.barcode ?? '');
    _brandController = TextEditingController(text: p.brand ?? '');
    _packageSizeController = TextEditingController(text: p.packageSize ?? '');
    _sellingPriceController = TextEditingController(text: p.price.toString());
    _importPriceController = TextEditingController(text: (p.importPrice ?? '').toString());
    _stockController = TextEditingController(text: p.stock.toString());
    _descriptionController = TextEditingController(text: p.description ?? '');
    _imageUrlController = TextEditingController(text: p.imageUrl);
    _selectedCategory = _categories.contains(p.category) ? p.category : _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _packageSizeController.dispose();
    _sellingPriceController.dispose();
    _importPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();
    final brand = _brandController.text.trim();
    final packageSize = _packageSizeController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim().isEmpty
        ? widget.product.imageUrl
        : _imageUrlController.text.trim();

    final sellingPrice = int.tryParse(_sellingPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? widget.product.price;
    final importPrice = int.tryParse(_importPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final stock = int.tryParse(_stockController.text.trim()) ?? widget.product.stock;

    final updatedProduct = Product(
      id: widget.product.id,
      name: name,
      price: sellingPrice,
      importPrice: importPrice,
      oldPrice: widget.product.oldPrice,
      rating: widget.product.rating,
      category: _selectedCategory,
      imageUrl: imageUrl,
      barcode: barcode.isEmpty ? null : barcode,
      brand: brand.isEmpty ? null : brand,
      packageSize: packageSize.isEmpty ? null : packageSize,
      description: description.isEmpty ? null : description,
      stock: stock,
    );

    final controller = widget.controller;
    if (controller != null) {
      final index = controller.products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        controller.products[index] = updatedProduct;
        controller.notifyListeners();
      }
    }

    if (widget.onProductUpdated != null) {
      widget.onProductUpdated!(updatedProduct);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật thành công sản phẩm: "$name"'),
        backgroundColor: Colors.green[700],
      ),
    );

    Navigator.of(context).pop(updatedProduct);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa sản phẩm'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${widget.product.name}" khỏi kho không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = widget.controller;
    if (controller != null) {
      controller.products.removeWhere((p) => p.id == widget.product.id);
      controller.notifyListeners();
    }

    if (widget.onProductDeleted != null) {
      widget.onProductDeleted!(widget.product.id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa sản phẩm "${widget.product.name}" khỏi hệ thống.'),
        backgroundColor: Colors.orange[800],
      ),
    );

    Navigator.of(context).pop('DELETED');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sửa thông tin sản phẩm'),
            Text(
              'Giao diện Nhân viên Quản lý Kho',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa sản phẩm',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue900, AppColors.blue700],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: ClipOval(
                        child: Image.network(
                          widget.product.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.inventory_2_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mã ID: ${widget.product.id} • SKU',
                            style: const TextStyle(color: Color(0xFFDCEBFA), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // KHỐI 1: THÔNG TIN CƠ BẢN
              _SectionCard(
                title: '1. Chỉnh sửa thông tin cơ bản',
                icon: Icons.edit_note_rounded,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm (*)',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mã vạch / Barcode',
                      prefixIcon: Icon(Icons.qr_code_2_rounded),
                    ),
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
                title: '2. Giá cả & Tồn kho',
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
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Nhập giá bán' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _importPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá nhập (VNĐ)',
                            prefixIcon: Icon(Icons.request_quote_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng tồn kho',
                      prefixIcon: Icon(Icons.inventory_rounded),
                    ),
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      if (n == null || n < 0) return 'Số lượng không hợp lệ';
                      return null;
                    },
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả chi tiết sản phẩm',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // NÚT CẬP NHẬT
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _updateProduct,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'ĐANG CẬP NHẬT...' : 'CẬP NHẬT THÔNG TIN SẢN PHẨM',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // NÚT XÓA SẢN PHẨM
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Xóa sản phẩm khỏi kho', style: TextStyle(fontWeight: FontWeight.bold)),
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
