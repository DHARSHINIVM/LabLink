import '../models/resource.dart';


// ============================================================================
// REQUEST STATUS
// ============================================================================

enum RequestStatus {
  pending,
  approved,
  rejected,
  completed,
}


// ============================================================================
// RESOURCE REQUEST
// ============================================================================

class ResourceRequest {
  final String id;

  final Resource resource;

  final String requester;

  final String requesterDepartment;

  final String purpose;

  final DateTime requestedAt;

  RequestStatus status;


  ResourceRequest({
    required this.id,
    required this.resource,
    required this.requester,
    required this.requesterDepartment,
    this.purpose = 'Resource request',
    required this.requestedAt,
    this.status = RequestStatus.pending,
  });


  // ==========================================================================
  // CREATE FROM API RESPONSE
  // ==========================================================================

  factory ResourceRequest.fromJson({
    required Map<String, dynamic> json,
    required Resource resource,
    String requester = 'Test Student',
    String requesterDepartment = 'CSE',
  }) {
    return ResourceRequest(
      id: json['id'].toString(),

      resource: resource,

      requester: requester,

      requesterDepartment:
          requesterDepartment,

      purpose:
          json['purpose']?.toString() ??
          'Resource request',

      requestedAt:
          DateTime.tryParse(
            json['requested_at']?.toString() ?? '',
          ) ??
          DateTime.now(),

      status:
          _statusFromString(
        json['status']?.toString(),
      ),
    );
  }


  // ==========================================================================
  // STATUS CONVERSION
  // ==========================================================================

  static RequestStatus _statusFromString(
    String? value,
  ) {
    switch (
      value?.trim().toLowerCase()
    ) {
      case 'approved':
        return RequestStatus.approved;

      case 'rejected':
        return RequestStatus.rejected;

      case 'completed':
        return RequestStatus.completed;

      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }
}