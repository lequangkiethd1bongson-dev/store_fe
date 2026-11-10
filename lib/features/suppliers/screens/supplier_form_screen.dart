import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/supplier.dart';
import '../state/supplier_controller.dart';
import '../widgets/supplier_form_fields.dart';

class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({
    required this.controller,
    this.supplier,
    super.key,
  });

  final SupplierController controller;
  final Supplier? supplier;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _faxController;

  late bool _isActive;

  bool get _isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final supp = widget.supplier;
    _nameController = TextEditingController(text: supp?.name ?? '');
    _phoneController = TextEditingController(text: supp?.phone ?? '');
    _addressController = TextEditingController(text: supp?.address ?? '');
    _emailController = TextEditingController(text: supp?.email ?? '');
    _faxController = TextEditingController(text: supp?.fax ?? '');
    _isActive = supp?.isActive ?? true;
  }

  @override
  void didUpdateWidget(SupplierFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.supplier != oldWidget.supplier && widget.supplier != null) {
      final supp = widget.supplier!;
      _nameController.text = supp.name;
      _phoneController.text = supp.phone ?? '';
      _addressController.text = supp.address ?? '';
      _emailController.text = supp.email ?? '';
      _faxController.text = supp.fax ?? '';
      _isActive = supp.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _faxController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.controller.isSaving) return;

    Supplier? result;
    if (_isEdit) {
      result = await widget.controller.updateSupplier(
        id: widget.supplier!.id,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        email: _emailController.text,
        fax: _faxController.text,
        isActive: _isActive,
      );
    } else {
      result = await widget.controller.createSupplier(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        email: _emailController.text,
        fax: _faxController.text,
        isActive: _isActive,
      );
    }

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Đã cập nhật nhà cung cấp "${result.name}" thành công!'
                : 'Đã thêm nhà cung cấp "${result.name}" thành công!',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.pop(context, result);
    } else {
      final errorMsg = widget.controller.error ?? 'Thao tác không thành công.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red[700]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa nhà cung cấp' : 'Thêm nhà cung cấp mới'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final isSaving = widget.controller.isSaving;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SupplierFormFields(
                        nameController: _nameController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        emailController: _emailController,
                        faxController: _faxController,
                        isActive: _isActive,
                        onActiveChanged: (val) =>
                            setState(() => _isActive = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: isSaving ? null : _submitForm,
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEdit ? 'LƯU CẬP NHẬT' : 'LƯU NHÀ CUNG CẤP MỚI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
