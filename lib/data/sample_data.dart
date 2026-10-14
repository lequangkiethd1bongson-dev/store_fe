import '../models/store_models.dart';

/// dữ liệu sản phẩm tĩnh dùng để xem thử giao diện khi chưa nối backend.
const sampleProducts = <Product>[
  Product(
    id: 'milk',
    name: 'Sữa tươi Vinamilk 1L',
    price: 36500,
    barcode: '8938501001001',
    oldPrice: 42000,
    rating: 4.9,
    category: 'Sữa & trứng',
    brand: 'VINAMILK',
    packageSize: '1 lít',
    stock: 48,
    imageUrl: 'https://images.unsplash.com/photo-1596633605700-1efc9b49e277?auto=format&fit=crop&w=700&q=85',
    description: 'Sữa tươi 100% từ trang trại đạt chuẩn quốc tế, giàu canxi và vitamin. Vị thơm ngon tự nhiên, phù hợp cho cả gia đình.',
  ),
  Product(
    id: 'apple',
    name: 'Táo Envy Mỹ 1kg',
    price: 89000,
    barcode: '8938501001002',
    oldPrice: 119000,
    rating: 4.8,
    category: 'Rau củ quả',
    brand: 'ENVY',
    packageSize: '1 kg',
    stock: 32,
    imageUrl: 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&w=700&q=85',
    description: 'Táo Envy nhập khẩu từ Mỹ, vị ngọt giòn, thích hợp dùng trực tiếp hoặc chế biến món ăn.',
  ),
  Product(
    id: 'eggs',
    name: 'Trứng gà tươi 10 quả',
    price: 32000,
    barcode: '8938501001003',
    oldPrice: 38000,
    rating: 4.9,
    category: 'Sữa & trứng',
    brand: 'FARM FRESH',
    packageSize: '10 quả',
    stock: 56,
    imageUrl: 'https://images.unsplash.com/photo-1621791430759-7025439b42e3?auto=format&fit=crop&w=700&q=85',
    description: 'Trứng gà tươi được đóng gói cẩn thận, giàu protein và phù hợp cho bữa ăn hằng ngày.',
  ),
  Product(
    id: 'rice',
    name: 'Gạo thơm ST25 5kg',
    price: 185000,
    barcode: '8938501001004',
    oldPrice: 210000,
    rating: 4.7,
    category: 'Thực phẩm khô',
    brand: 'ST25',
    packageSize: '5 kg',
    stock: 18,
    imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=700&q=85',
    description:
        'Gạo thơm dẻo, hạt dài, được đóng túi 5kg tiện lợi cho gia đình.',
  ),
  Product(
    id: 'water',
    name: 'Nước suối Aquafina 500ml',
    price: 6000,
    barcode: '8938501001005',
    rating: 4.8,
    category: 'Đồ uống',
    brand: 'AQUAFINA',
    packageSize: '500 ml',
    stock: 120,
    imageUrl: 'https://images.unsplash.com/photo-1560023907-5f339617ea30?auto=format&fit=crop&w=700&q=85',
    description: 'Nước uống tinh khiết đóng chai nhỏ gọn, tiện mang theo khi đi học hoặc đi làm.',
  ),
  Product(
    id: 'beef',
    name: 'Thịt bò Úc 500g',
    price: 145000,
    barcode: '8938501001006',
    oldPrice: 169000,
    rating: 4.9,
    category: 'Thịt cá',
    brand: 'AUS BEEF',
    packageSize: '500 g',
    stock: 14,
    imageUrl: 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=700&q=85',
    description: 'Thịt bò nhập khẩu được bảo quản lạnh, phù hợp cho món nướng, áp chảo và lẩu.',
  ),
];

/// lưu tên, biểu tượng và số lượng hiển thị của một nhóm sản phẩm.
class ProductCategory {
  const ProductCategory({
    required this.emoji,
    required this.name,
    required this.count,
  });

  final String emoji;
  final String name;
  final String count;
}

/// danh sách nhóm hàng mẫu để dựng giao diện danh mục.
const sampleCategories = <ProductCategory>[
  ProductCategory(emoji: '🥬', name: 'Rau củ quả', count: '120+ sản phẩm'),
  ProductCategory(emoji: '🥩', name: 'Thịt cá', count: '86 sản phẩm'),
  ProductCategory(emoji: '🥛', name: 'Sữa & trứng', count: '64 sản phẩm'),
  ProductCategory(emoji: '🧃', name: 'Đồ uống', count: '98 sản phẩm'),
  ProductCategory(emoji: '🍪', name: 'Bánh kẹo', count: '112 sản phẩm'),
  ProductCategory(emoji: '🧂', name: 'Gia vị', count: '75 sản phẩm'),
  ProductCategory(emoji: '🧹', name: 'Đồ gia dụng', count: '54 sản phẩm'),
  ProductCategory(emoji: '🧴', name: 'Hóa mỹ phẩm', count: '68 sản phẩm'),
];
