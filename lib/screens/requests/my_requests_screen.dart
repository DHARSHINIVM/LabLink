import 'package:flutter/material.dart';

import '../../models/resource.dart';
import '../../models/resource_request.dart';
import '../../services/api_service.dart';
import '../../services/request_store.dart';
import '../../theme/app_theme.dart';


class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({
    super.key,
  });


  @override
  State<MyRequestsScreen> createState() =>
      _MyRequestsScreenState();
}


class _MyRequestsScreenState
    extends State<MyRequestsScreen> {

  final RequestStore _requestStore =
      RequestStore.instance;


  bool _isLoading = true;

  String? _errorMessage;


  // ==========================================================================
  // CURRENT USER
  // ==========================================================================
  // We are still using the temporary authenticated user ID.
  // Later we will connect this directly to the logged-in User object.

  static const int _currentUserId = 1;

  static const String _currentUserName =
      'Test Student';

  static const String _currentUserDepartment =
      'CSE';


  @override
  void initState() {
    super.initState();

    _loadRequests();
  }


  // ==========================================================================
  // LOAD REQUESTS
  // ==========================================================================

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }


    try {
      // ----------------------------------------------------------------------
      // GET ONLY THIS USER'S REQUESTS
      // ----------------------------------------------------------------------

      final requestData =
          await ApiService.getUserRequests(
        _currentUserId,
      );


      final List<ResourceRequest>
          loadedRequests = [];


      // ----------------------------------------------------------------------
      // CONVERT API REQUESTS
      // ----------------------------------------------------------------------

      for (final json in requestData) {

        final resourceId =
            int.tryParse(
          json['resource_id']
                  ?.toString() ??
              '',
        );


        if (resourceId == null) {
          continue;
        }


        // --------------------------------------------------------------------
        // GET RESOURCE DETAILS
        // --------------------------------------------------------------------

        final resourceJson =
            await ApiService
                .getResourceById(
          resourceId,
        );


        final resource =
            Resource.fromJson(
          Map<String, dynamic>.from(
            resourceJson,
          ),
        );


        // --------------------------------------------------------------------
        // CREATE REQUEST MODEL
        // --------------------------------------------------------------------

        loadedRequests.add(
          ResourceRequest.fromJson(
            json: json,
            resource: resource,
            requester:
                _currentUserName,
            requesterDepartment:
                _currentUserDepartment,
          ),
        );
      }


      // ----------------------------------------------------------------------
      // UPDATE STORE
      // ----------------------------------------------------------------------

      if (!mounted) return;


      _requestStore.replaceRequests(
        loadedRequests,
      );


      setState(() {
        _isLoading = false;
      });

    } catch (error) {

      debugPrint(
        'MY REQUESTS LOAD ERROR: $error',
      );


      if (!mounted) return;


      setState(() {
        _isLoading = false;

        _errorMessage =
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }


  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,


      // ======================================================================
      // APP BAR
      // ======================================================================

      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
                _isLoading
                    ? null
                    : _loadRequests,

            icon: const Icon(
              Icons.refresh_rounded,
            ),

            tooltip:
                'Refresh',
          ),
        ],
      ),


      // ======================================================================
      // BODY
      // ======================================================================

      body: RefreshIndicator(
        color:
            AppTheme.primary,

        onRefresh:
            _loadRequests,

        child: AnimatedBuilder(
          animation:
              _requestStore,

          builder:
              (
            context,
            child,
          ) {

            // =================================================================
            // LOADING
            // =================================================================

            if (_isLoading) {
              return const _LoadingState();
            }


            // =================================================================
            // ERROR
            // =================================================================

            if (_errorMessage != null) {
              return _ErrorState(
                message:
                    _errorMessage!,

                onRetry:
                    _loadRequests,
              );
            }


            // =================================================================
            // REQUESTS
            // =================================================================

            final requests =
                _requestStore.requests;


            // =================================================================
            // EMPTY
            // =================================================================

            if (requests.isEmpty) {
              return const _EmptyState();
            }


            // =================================================================
            // LIST
            // =================================================================

            return ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),

              itemCount:
                  requests.length,

              itemBuilder:
                  (
                context,
                index,
              ) {
                return _buildRequestCard(
                  requests[index],
                );
              },
            );
          },
        ),
      ),
    );
  }


  // ==========================================================================
  // REQUEST CARD
  // ==========================================================================

  Widget _buildRequestCard(
    ResourceRequest request,
  ) {
    final statusColor =
        _statusColor(
      request.status,
    );


    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      elevation: 0,

      color:
          Colors.white,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),

        side:
            const BorderSide(
          color:
              Color(0xFFE7ECEA),
        ),
      ),


      child: Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // =================================================================
            // HEADER
            // =================================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Container(
                  width: 48,
                  height: 48,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE2F1ED,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),

                  child:
                      const Icon(
                    Icons.inventory_2_outlined,

                    color:
                        AppTheme.primary,
                  ),
                ),


                const SizedBox(
                  width: 12,
                ),


                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        request.resource.name,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 16,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              AppTheme.text,
                        ),
                      ),


                      const SizedBox(
                        height: 4,
                      ),


                      Text(
                        request.resource.category,

                        style:
                            const TextStyle(
                          fontSize: 12,

                          color:
                              AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(
                  width: 8,
                ),


                _statusChip(
                  request.status,
                  statusColor,
                ),
              ],
            ),


            const SizedBox(
              height: 15,
            ),


            // =================================================================
            // DEPARTMENT
            // =================================================================

            Row(
              children: [

                const Icon(
                  Icons.business_outlined,

                  size: 16,

                  color:
                      AppTheme.secondary,
                ),


                const SizedBox(
                  width: 7,
                ),


                Expanded(
                  child: Text(
                    request
                        .resource
                        .department,

                    style:
                        const TextStyle(
                      fontSize: 12,

                      fontWeight:
                          FontWeight.w600,

                      color:
                          AppTheme.text,
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(
              height: 7,
            ),


            // =================================================================
            // LOCATION
            // =================================================================

            Row(
              children: [

                const Icon(
                  Icons.location_on_outlined,

                  size: 16,

                  color:
                      AppTheme.mutedText,
                ),


                const SizedBox(
                  width: 7,
                ),


                Expanded(
                  child: Text(
                    request
                        .resource
                        .location,

                    style:
                        const TextStyle(
                      fontSize: 12,

                      color:
                          AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(
              height: 14,
            ),


            // =================================================================
            // PURPOSE
            // =================================================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                12,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF7F9F8,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'Purpose',

                    style:
                        TextStyle(
                      fontSize: 11,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          AppTheme.mutedText,
                    ),
                  ),


                  const SizedBox(
                    height: 4,
                  ),


                  Text(
                    request.purpose,

                    style:
                        const TextStyle(
                      fontSize: 12,

                      color:
                          AppTheme.text,
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(
              height: 13,
            ),


            // =================================================================
            // DATE + ID
            // =================================================================

            Row(
              children: [

                const Icon(
                  Icons.calendar_today_outlined,

                  size: 14,

                  color:
                      AppTheme.mutedText,
                ),


                const SizedBox(
                  width: 6,
                ),


                Text(
                  _formatDate(
                    request.requestedAt,
                  ),

                  style:
                      const TextStyle(
                    fontSize: 11,

                    color:
                        AppTheme.mutedText,
                  ),
                ),


                const Spacer(),


                Text(
                  'Request #${request.id}',

                  style:
                      const TextStyle(
                    fontSize: 11,

                    color:
                        AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================================
  // STATUS CHIP
  // ==========================================================================

  Widget _statusChip(
    RequestStatus status,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.12,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [

          Container(
            width: 6,
            height: 6,

            decoration:
                BoxDecoration(
              color:
                  color,

              shape:
                  BoxShape.circle,
            ),
          ),


          const SizedBox(
            width: 6,
          ),


          Text(
            _statusText(
              status,
            ),

            style:
                TextStyle(
              color:
                  color,

              fontSize: 11,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================================
  // STATUS TEXT
  // ==========================================================================

  String _statusText(
    RequestStatus status,
  ) {
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


  // ==========================================================================
  // STATUS COLOR
  // ==========================================================================

  Color _statusColor(
    RequestStatus status,
  ) {
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


  // ==========================================================================
  // DATE FORMAT
  // ==========================================================================

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}


// ============================================================================
// LOADING STATE
// ============================================================================

class _LoadingState
    extends StatelessWidget {

  const _LoadingState();


  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          CircularProgressIndicator(
            color:
                AppTheme.primary,
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'Loading your requests...',

            style:
                TextStyle(
              color:
                  AppTheme.mutedText,

              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// ERROR STATE
// ============================================================================

class _ErrorState
    extends StatelessWidget {

  final String message;

  final VoidCallback onRetry;


  const _ErrorState({
    required this.message,
    required this.onRetry,
  });


  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      children: [

        SizedBox(
          height:
              MediaQuery.of(context)
                  .size
                  .height *
              0.65,

          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                30,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Icon(
                    Icons.cloud_off_rounded,

                    size: 54,

                    color:
                        Colors.orange,
                  ),


                  const SizedBox(
                    height: 16,
                  ),


                  const Text(
                    'Unable to load requests',

                    style:
                        TextStyle(
                      fontSize: 19,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          AppTheme.text,
                    ),
                  ),


                  const SizedBox(
                    height: 8,
                  ),


                  Text(
                    message,

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      fontSize: 12,

                      color:
                          AppTheme.mutedText,
                    ),
                  ),


                  const SizedBox(
                    height: 18,
                  ),


                  ElevatedButton.icon(
                    onPressed:
                        onRetry,

                    icon:
                        const Icon(
                      Icons.refresh_rounded,
                    ),

                    label:
                        const Text(
                      'Retry',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState
    extends StatelessWidget {

  const _EmptyState();


  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      children: [

        SizedBox(
          height:
              MediaQuery.of(context)
                  .size
                  .height *
              0.65,

          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                32,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  Container(
                    width: 86,
                    height: 86,

                    decoration:
                        const BoxDecoration(
                      color:
                          Color(
                        0xFFE2F1ED,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        const Icon(
                      Icons
                          .assignment_outlined,

                      size: 42,

                      color:
                          AppTheme.primary,
                    ),
                  ),


                  const SizedBox(
                    height: 18,
                  ),


                  const Text(
                    'No requests yet',

                    style:
                        TextStyle(
                      fontSize: 20,

                      fontWeight:
                          FontWeight.bold,

                      color:
                          AppTheme.text,
                    ),
                  ),


                  const SizedBox(
                    height: 8,
                  ),


                  const Text(
                    'Search for a resource and '
                    'request it from another department.',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      color:
                          AppTheme.mutedText,

                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}