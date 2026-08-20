import 'package:flutter/foundation.dart';

import '../models/resource_request.dart';


class RequestStore extends ChangeNotifier {
  // ==========================================================================
  // SINGLETON
  // ==========================================================================

  RequestStore._();

  static final RequestStore instance =
      RequestStore._();


  // ==========================================================================
  // INTERNAL REQUEST LIST
  // ==========================================================================

  final List<ResourceRequest> _requests = [];


  // ==========================================================================
  // PUBLIC REQUEST LIST
  // ==========================================================================

  List<ResourceRequest> get requests =>
      List.unmodifiable(_requests);


  // ==========================================================================
  // ADD REQUEST
  // ==========================================================================

  void addRequest(
    ResourceRequest request,
  ) {
    _requests.add(request);

    notifyListeners();
  }


  // ==========================================================================
  // REPLACE REQUESTS
  // ==========================================================================
  // Backend is the source of truth.
  // This replaces the locally cached list with fresh API data.
  // ==========================================================================

  void replaceRequests(
    List<ResourceRequest> requests,
  ) {
    _requests
      ..clear()
      ..addAll(requests);

    notifyListeners();
  }


  // ==========================================================================
  // UPDATE REQUEST STATUS
  // ==========================================================================

  void updateStatus(
    String requestId,
    RequestStatus status,
  ) {
    final index =
        _requests.indexWhere(
      (request) =>
          request.id == requestId,
    );

    if (index != -1) {
      _requests[index].status =
          status;

      notifyListeners();
    }
  }


  // ==========================================================================
  // CHECK PENDING REQUEST
  // ==========================================================================

  bool hasPendingRequest(
    String resourceId,
  ) {
    return _requests.any(
      (request) =>
          request.resource.id.toString()
              == resourceId &&
          request.status ==
              RequestStatus.pending,
    );
  }


  // ==========================================================================
  // PENDING COUNT
  // ==========================================================================

  int get pendingCount {
    return _requests
        .where(
          (request) =>
              request.status ==
              RequestStatus.pending,
        )
        .length;
  }


  // ==========================================================================
  // APPROVED COUNT
  // ==========================================================================

  int get approvedCount {
    return _requests
        .where(
          (request) =>
              request.status ==
              RequestStatus.approved,
        )
        .length;
  }


  // ==========================================================================
  // REJECTED COUNT
  // ==========================================================================

  int get rejectedCount {
    return _requests
        .where(
          (request) =>
              request.status ==
              RequestStatus.rejected,
        )
        .length;
  }


  // ==========================================================================
  // COMPLETED COUNT
  // ==========================================================================

  int get completedCount {
    return _requests
        .where(
          (request) =>
              request.status ==
              RequestStatus.completed,
        )
        .length;
  }


  // ==========================================================================
  // TOTAL COUNT
  // ==========================================================================

  int get totalCount {
    return _requests.length;
  }


  // ==========================================================================
  // CLEAR
  // ==========================================================================

  void clear() {
    _requests.clear();

    notifyListeners();
  }
}