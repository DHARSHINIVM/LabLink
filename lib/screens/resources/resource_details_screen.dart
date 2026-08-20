import 'package:flutter/material.dart';

import '../../models/resource.dart';
import '../../models/resource_request.dart';
import '../../services/api_service.dart';
import '../../services/request_store.dart';
import '../../theme/app_theme.dart';

class ResourceDetailsScreen extends StatefulWidget {
  final Resource resource;

  const ResourceDetailsScreen({
    super.key,
    required this.resource,
  });

  @override
  State<ResourceDetailsScreen> createState() =>
      _ResourceDetailsScreenState();
}

class _ResourceDetailsScreenState
    extends State<ResourceDetailsScreen> {
  final RequestStore _requestStore =
      RequestStore.instance;

  Resource get resource => widget.resource;

  bool _isSubmitting = false;

  // Temporary authenticated user.
  // We will replace this with the real logged-in user ID
  // when authentication is connected to the backend.
  static const int _currentUserId = 1;

  static const String _currentUserName =
      'Test Student';

  static const String _currentUserDepartment =
      'CSE';

  bool get _hasPendingRequest {
    return _requestStore.hasPendingRequest(
      resource.id.toString(),
    );
  }

  bool get _available {
    return resource.availableQuantity > 0 &&
        resource.status != 'Unavailable';
  }

  // --------------------------------------------------------------------------
  // CREATE REQUEST
  // --------------------------------------------------------------------------

  Future<void> _requestResource() async {
    if (!_available || _isSubmitting) {
      return;
    }

    if (_hasPendingRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A request for this resource is already pending.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response =
          await ApiService.createRequest(
        resourceId: resource.id,
        requesterId: _currentUserId,
        purpose:
            'Resource request for ${resource.name}',
      );

      if (!mounted) {
        return;
      }

      final request =
          ResourceRequest.fromJson(
        json: response,
        resource: resource,
        requester: _currentUserName,
        requesterDepartment:
            _currentUserDepartment,
      );

      _requestStore.addRequest(request);

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${resource.name} request submitted successfully.',
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      String message = error
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilization =
        resource.utilization.round();

    final hasPending = _hasPendingRequest;

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'Resource Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ----------------------------------------------------------------
            // RESOURCE ICON
            // ----------------------------------------------------------------

            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE2F1ED),
                  borderRadius:
                      BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 55,
                  color: AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------------------
            // RESOURCE NAME
            // ----------------------------------------------------------------

            Text(
              resource.name,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              resource.category,
              style: const TextStyle(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // AVAILABILITY
            // ----------------------------------------------------------------

            _AvailabilityBadge(
              available: _available,
              availableQuantity:
                  resource.availableQuantity,
              totalQuantity:
                  resource.quantity,
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // RESOURCE INFORMATION
            // ----------------------------------------------------------------

            Container(
              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Column(
                children: [
                  _InfoRow(
                    icon:
                        Icons.business_outlined,
                    title: 'Department',
                    value:
                        resource.department,
                  ),

                  _InfoRow(
                    icon:
                        Icons.location_on_outlined,
                    title: 'Location',
                    value:
                        resource.location,
                  ),

                  _InfoRow(
                    icon: Icons
                        .account_balance_outlined,
                    title: 'Managed By',
                    value:
                        resource.department,
                  ),

                  _InfoRow(
                    icon:
                        Icons.inventory_outlined,
                    title: 'Quantity',
                    value:
                        '${resource.quantity}',
                  ),

                  _InfoRow(
                    icon:
                        Icons.check_circle_outline,
                    title: 'Available',
                    value:
                        '${resource.availableQuantity}',
                  ),

                  _InfoRow(
                    icon:
                        Icons.analytics_outlined,
                    title: 'Utilization',
                    value:
                        '$utilization%',
                    last: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------------------

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              resource.description,
              style: const TextStyle(
                height: 1.5,
                color: AppTheme.mutedText,
              ),
            ),

            const SizedBox(height: 28),

            // ----------------------------------------------------------------
            // REQUEST BUTTON
            // ----------------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton.icon(
                onPressed:
                    _available &&
                            !hasPending &&
                            !_isSubmitting
                        ? _requestResource
                        : null,

                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        hasPending
                            ? Icons
                                .check_circle_outline
                            : Icons
                                .send_outlined,
                      ),

                label: Text(
                  _isSubmitting
                      ? 'Sending Request...'
                      : hasPending
                          ? 'Request Pending'
                          : _available
                              ? 'Request Resource'
                              : 'Resource Unavailable',

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppTheme.primary,

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      hasPending
                          ? const Color(
                              0xFFDCEEE9,
                            )
                          : Colors
                              .grey
                              .shade300,

                  disabledForegroundColor:
                      hasPending
                          ? AppTheme.primary
                          : Colors
                              .grey
                              .shade600,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // REQUEST STATUS
            // ----------------------------------------------------------------

            if (hasPending)
              const Center(
                child: Text(
                  'Your request has been added to My Requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AVAILABILITY BADGE
// ============================================================================

class _AvailabilityBadge
    extends StatelessWidget {
  final bool available;
  final int availableQuantity;
  final int totalQuantity;

  const _AvailabilityBadge({
    required this.available,
    required this.availableQuantity,
    required this.totalQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        available
            ? Colors.green
            : Colors.red;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              color.withValues(alpha: 0.20),
        ),
      ),

      child: Row(
        children: [
          Icon(
            available
                ? Icons
                    .check_circle_outline
                : Icons.cancel_outlined,
            color: color,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              available
                  ? 'Available • '
                      '$availableQuantity of '
                      '$totalQuantity available'
                  : 'Currently unavailable',
              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INFORMATION ROW
// ============================================================================

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool last;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),

      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(
                  color:
                      Color(0xFFE8EEEC),
                ),
              ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: AppTheme.secondary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color:
                    AppTheme.mutedText,
              ),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}