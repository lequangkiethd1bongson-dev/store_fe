import 'package:flutter/material.dart';

class SupplierFormFields extends StatelessWidget {
  const SupplierFormFields({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.emailController,
    required this.faxController,
    required this.isActive,
    required this.onActiveChanged,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController emailController;
  final TextEditingController faxController;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên nhà cung cấp (*)',
            prefixIcon: Icon(Icons.business_rounded),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Vui lòng nhập tên nhà cung cấp';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại (11 chữ số) (*)',
            hintText: 'VD: 09123456789',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
          validator: (val) {
            final clean = val?.trim() ?? '';
            if (clean.isEmpty) {
              return 'Vui lòng nhập số điện thoại nhà cung cấp';
            }
            final phoneRegex = RegExp(r'^\d{11}$');
            if (!phoneRegex.hasMatch(clean)) {
              return 'Số điện thoại phải bao gồm đúng 11 chữ số.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ nhà cung cấp (*)',
            prefixIcon: Icon(Icons.location_on_rounded),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Vui lòng nhập địa chỉ nhà cung cấp';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (tùy chọn)',
            prefixIcon: Icon(Icons.email_rounded),
          ),
          validator: (val) {
            final clean = val?.trim() ?? '';
            if (clean.isNotEmpty) {
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(clean)) {
                return 'Địa chỉ email không hợp lệ';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: faxController,
          decoration: const InputDecoration(
            labelText: 'Fax (tùy chọn)',
            prefixIcon: Icon(Icons.fax_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Trạng thái hoạt động',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          subtitle: Text(
            isActive
                ? 'Nhà cung cấp đang hoạt động và có thể chọn khi lập phiếu nhập'
                : 'Tạm ngưng (không xuất hiện khi lập phiếu nhập hàng mới)',
            style: const TextStyle(fontSize: 10),
          ),
          value: isActive,
          onChanged: onActiveChanged,
        ),
      ],
    );
  }
}
