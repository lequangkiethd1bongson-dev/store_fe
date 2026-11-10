import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/supplier.dart';
import 'supplier_status_badge.dart';

class SupplierCard extends StatelessWidget {
  const SupplierCard({
    required this.supplier,
    required this.onTap,
    this.onEdit,
    this.onToggleStatus,
    this.showActions = false,
    super.key,
  });

  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      supplier.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SupplierStatusBadge(isActive: supplier.isActive),
                ],
              ),
              const SizedBox(height: 8),
              if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      supplier.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        supplier.address!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (supplier.email != null && supplier.email!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 15,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        supplier.email!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (showActions &&
                  (onEdit != null || onToggleStatus != null)) ...[
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'Sửa',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    if (onToggleStatus != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: supplier.isActive
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                        onPressed: onToggleStatus,
                        icon: Icon(
                          supplier.isActive
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          supplier.isActive ? 'Ngừng HĐ' : 'Kích hoạt lại',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
