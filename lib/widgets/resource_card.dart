import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../theme/app_theme.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool available = resource.status == 'Available';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2EF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primary,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${resource.department} • ${resource.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? const Color(0xFFE5F4ED)
                              : const Color(0xFFFFE9E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          resource.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: available
                                ? const Color(0xFF237A58)
                                : const Color(0xFFB84A4A),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        '${resource.quantity} available',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9BA7A4),
            ),
          ],
        ),
      ),
    );
  }
}