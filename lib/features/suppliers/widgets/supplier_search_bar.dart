import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class SupplierSearchBar extends StatelessWidget {
  const SupplierSearchBar({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onFilterChanged,
    super.key,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, SĐT hoặc email nhà cung cấp',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              isDense: true,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('ALL', 'Tất cả'),
              const SizedBox(width: 8),
              _buildFilterChip('ACTIVE', 'Đang hoạt động'),
              const SizedBox(width: 8),
              _buildFilterChip('INACTIVE', 'Tạm ngưng'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.blue700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.ink,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(value);
        }
      },
    );
  }
}
