import 'package:flutter/material.dart';

import '../../models/resource_request.dart';
import '../../services/request_store.dart';
import '../../theme/app_theme.dart';

class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Incoming Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: RequestStore.instance,
        builder: (context, child) {
          final requests = RequestStore.instance.requests;

          if (requests.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _RequestCard(
                request: requests[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.primary,
            ),
            SizedBox(height: 16),
            Text(
              'No incoming requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'New resource requests from other '
              'departments will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ResourceRequest request;

  const _RequestCard({
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final isPending =
        request.status == RequestStatus.pending;

    final statusColor = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resource
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F1ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.resource.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.resource.department,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                text: _statusText(request.status),
                color: statusColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Requester
          _InfoLine(
            icon: Icons.person_outline,
            label: 'Requested by',
            value: request.requester,
          ),

          const SizedBox(height: 8),

          _InfoLine(
            icon: Icons.school_outlined,
            label: 'Department',
            value: request.requesterDepartment,
          ),

          const SizedBox(height: 8),

          _InfoLine(
            icon: Icons.location_on_outlined,
            label: 'Resource location',
            value: request.resource.location,
          ),

          const SizedBox(height: 8),

          _InfoLine(
            icon: Icons.access_time_outlined,
            label: 'Requested',
            value: _formatDate(request.requestedAt),
          ),

          if (isPending) ...[
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        context,
                        request,
                        RequestStatus.rejected,
                      );
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                      minimumSize:
                          const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _confirmAction(
                        context,
                        request,
                        RequestStatus.approved,
                      );
                    },
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 18,
                    ),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size(double.infinity, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    ResourceRequest request,
    RequestStatus status,
  ) {
    final isApproval = status == RequestStatus.approved;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isApproval
                ? 'Approve Request?'
                : 'Reject Request?',
          ),
          content: Text(
            isApproval
                ? 'Approve ${request.requester}\'s request '
                    'for ${request.resource.name}?'
                : 'Reject ${request.requester}\'s request '
                    'for ${request.resource.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                RequestStore.instance.updateStatus(
                  request.id,
                  status,
                );

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isApproval
                          ? 'Request approved successfully.'
                          : 'Request rejected.',
                    ),
                    backgroundColor:
                        isApproval ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isApproval ? AppTheme.primary : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                isApproval ? 'Approve' : 'Reject',
              ),
            ),
          ],
        );
      },
    );
  }

  String _statusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.completed:
        return 'Completed';
    }
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.approved:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: AppTheme.secondary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.mutedText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}