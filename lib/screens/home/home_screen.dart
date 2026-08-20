import 'package:flutter/material.dart';

import '../../models/resource.dart';
import '../../services/api_service.dart';
import '../../services/request_store.dart';
import '../../theme/app_theme.dart';
import '../resources/resource_details_screen.dart';
import '../resources/resource_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final RequestStore requestStore = RequestStore.instance;

  List<Resource> resources = [];
  bool isLoading = true;
  String? errorMessage;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loadResources();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOAD RESOURCES
  // --------------------------------------------------------------------------

  Future<void> _loadResources() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getResources();

      if (!mounted) return;

      setState(() {
        resources = result;
        isLoading = false;
      });

      // Start dashboard animations AFTER data has loaded.
      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load resources';
      });
    }
  }

  // --------------------------------------------------------------------------
  // KPI DATA
  // --------------------------------------------------------------------------

  int get totalResources => resources.length;

  int get availableResources {
    return resources
        .where(
          (resource) =>
              resource.availableQuantity > 0,
        )
        .length;
  }

  int get underutilizedResources {
    return resources
        .where(
          (resource) =>
              resource.utilization < 50,
        )
        .length;
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _loadResources,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              30,
            ),
            children: [
              // ==============================================================
              // HEADER
              // ==============================================================

              _AnimatedSection(
                animation: _animationController,
                start: 0.00,
                end: 0.25,
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good evening, Student',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'LabLink',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight:
                                  FontWeight.bold,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFE2F1ED,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: const Text(
                              'CSE Department',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notification button
                    Container(
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger
                              .of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No new notifications.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons
                              .notifications_none_rounded,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==============================================================
              // LOADING / ERROR / CONTENT
              // ==============================================================

              if (isLoading)
                const _LoadingDashboard()
              else if (errorMessage != null)
                _ErrorCard(
                  message: errorMessage!,
                  onRetry: _loadResources,
                )
              else ...[
                // ============================================================
                // KPI ROW 1
                // ============================================================

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.18,
                  end: 0.40,
                  child: Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Resources',
                          value:
                              '$totalResources',
                          icon: Icons
                              .inventory_2_outlined,
                          color:
                              AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'Available',
                          value:
                              '$availableResources',
                          icon: Icons
                              .check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ============================================================
                // KPI ROW 2
                // ============================================================

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.25,
                  end: 0.47,
                  child: Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Pending',
                          value:
                              '${requestStore.pendingCount}',
                          icon: Icons
                              .pending_actions_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'Underutilized',
                          value:
                              '$underutilizedResources',
                          icon: Icons
                              .trending_down_rounded,
                          color:
                              Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ============================================================
                // QUICK ACTIONS
                // ============================================================

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.32,
                  end: 0.52,
                  child: const _SectionTitle(
                    title: 'Quick Actions',
                    subtitle:
                        'Find and share institutional resources',
                  ),
                ),

                const SizedBox(height: 12),

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.38,
                  end: 0.58,
                  child: _ActionCard(
                    icon: Icons.search_rounded,
                    title: 'Find a Resource',
                    subtitle:
                        'Search resources across departments',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ResourceSearchScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.43,
                  end: 0.63,
                  child: _ActionCard(
                    icon: Icons.auto_awesome_rounded,
                    title:
                        'Smart Recommendations',
                    subtitle:
                        'Find the best resource for your requirement',
                    color:
                        const Color(0xFF6C63FF),
                    onTap: () {
                      _showSmartRecommendationDialog(
                        context,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.48,
                  end: 0.68,
                  child: _ActionCard(
                    icon: Icons
                        .account_balance_wallet_outlined,
                    title:
                        'Procurement Check',
                    subtitle:
                        'Check before purchasing new equipment',
                    color:
                        const Color(0xFF00897B),
                    onTap: () {
                      _showProcurementDialog(
                        context,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // ============================================================
                // MY REQUESTS
                // ============================================================

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.53,
                  end: 0.72,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const _SectionTitle(
                        title: 'My Requests',
                        subtitle:
                            'Track your resource requests',
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger
                              .of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Open the Requests tab to view all requests.',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color:
                                AppTheme.primary,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                AnimatedBuilder(
                  animation: requestStore,
                  builder:
                      (context, child) {
                    final requests =
                        requestStore.requests;

                    if (requests.isEmpty) {
                      return _AnimatedSection(
                        animation:
                            _animationController,
                        start: 0.58,
                        end: 0.77,
                        child:
                            _EmptyRequestCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ResourceSearchScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return Column(
                      children: requests
                          .take(2)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                        (entry) {
                          final index =
                              entry.key;
                          final request =
                              entry.value;

                          return _AnimatedSection(
                            animation:
                                _animationController,
                            start:
                                0.58 +
                                    (index *
                                        0.05),
                            end:
                                0.77 +
                                    (index *
                                        0.05),
                            child: Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom: 10,
                              ),
                              child:
                                  _RequestPreviewCard(
                                resourceName:
                                    request
                                        .resource
                                        .name,
                                department:
                                    request
                                        .resource
                                        .department,
                                status:
                                    _statusText(
                                  request.status,
                                ),
                                statusColor:
                                    _statusColor(
                                  request.status,
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ============================================================
                // SMART SAVINGS
                // ============================================================

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.68,
                  end: 0.86,
                  child: _SavingsCard(
                    onTap: () {
                      _showProcurementDialog(
                        context,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // ============================================================
                // RECOMMENDED RESOURCE
                // ============================================================

                _AnimatedSection(
                  animation: _animationController,
                  start: 0.75,
                  end: 0.95,
                  child: const _SectionTitle(
                    title:
                        'Recommended Resource',
                    subtitle:
                        'Popular resources available now',
                  ),
                ),

                const SizedBox(height: 12),

                if (resources.isEmpty)
                  const _NoResourcesCard()
                else
                  _AnimatedSection(
                    animation:
                        _animationController,
                    start: 0.80,
                    end: 1.00,
                    child:
                        _FeaturedResourceCard(
                      resource:
                          resources.first,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ResourceDetailsScreen(
                              resource:
                                  resources.first,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // REQUEST STATUS
  // --------------------------------------------------------------------------

  static String _statusText(
    dynamic status,
  ) {
    final value =
        status.toString().split('.').last;

    switch (value) {
      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'completed':
        return 'Completed';

      default:
        return 'Pending';
    }
  }

  static Color _statusColor(
    dynamic status,
  ) {
    final value =
        status.toString().split('.').last;

    switch (value) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'completed':
        return Colors.blue;

      default:
        return Colors.orange;
    }
  }

  // --------------------------------------------------------------------------
  // SMART RECOMMENDATION DIALOG
  // --------------------------------------------------------------------------

  static void _showSmartRecommendationDialog(
    BuildContext context,
  ) {
    final controller =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Smart Recommendation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Describe what equipment you need and LabLink '
                'will suggest matching resources.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration:
                    InputDecoration(
                  hintText:
                      'Example: device for measuring temperature',
                  filled: true,
                  fillColor:
                      AppTheme.background,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger
                    .of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Smart matching will recommend the closest '
                      'available resources.',
                    ),
                  ),
                );
              },
              child:
                  const Text('Find Resources'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // PROCUREMENT DIALOG
  // --------------------------------------------------------------------------

  static void _showProcurementDialog(
    BuildContext context,
  ) {
    final resourceController =
        TextEditingController();

    final costController =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Procurement Check',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Check whether the institution already owns '
                'a similar resource before purchasing.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller:
                    resourceController,
                decoration:
                    InputDecoration(
                  labelText: 'Resource',
                  hintText:
                      'Example: Projector',
                  filled: true,
                  fillColor:
                      AppTheme.background,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    costController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    InputDecoration(
                  labelText:
                      'Estimated cost',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor:
                      AppTheme.background,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _showDuplicateResult(
                  context,
                );
              },
              child:
                  const Text('Check'),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // DUPLICATE RESULT
  // --------------------------------------------------------------------------

  static void _showDuplicateResult(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Potential Duplicate',
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'LabLink found a similar resource already '
                'available in the institution.',
              ),
              SizedBox(height: 16),
              Text(
                'Epson Projector',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'CSE Department • 2 available',
              ),
              SizedBox(height: 12),
              Text(
                'Similarity: 96%',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Recommendation: Share the existing resource '
                'instead of purchasing another one.',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Use Existing Resource',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// ANIMATED SECTION
// ============================================================================

class _AnimatedSection
    extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double start;
  final double end;

  const _AnimatedSection({
    required this.child,
    required this.animation,
    required this.start,
    required this.end,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final curvedAnimation =
        CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    final slideAnimation =
        Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

// ============================================================================
// LOADING DASHBOARD
// ============================================================================

class _LoadingDashboard
    extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          color: AppTheme.primary,
        ),
        const SizedBox(height: 14),
        const Text(
          'Loading resources...',
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// ============================================================================
// ERROR CARD
// ============================================================================

class _ErrorCard
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.orange,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w600,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
                const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NO RESOURCES
// ============================================================================

class _NoResourcesCard
    extends StatelessWidget {
  const _NoResourcesCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Center(
        child: Text(
          'No resources available.',
          style: TextStyle(
            color: AppTheme.mutedText,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// KPI CARD
// ============================================================================

class _KpiCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ACTION CARD
// ============================================================================

class _ActionCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppTheme.text,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme
                                .mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color:
                    AppTheme.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY REQUEST CARD
// ============================================================================

class _EmptyRequestCard
    extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyRequestCard({
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: const Padding(
          padding:
              EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons
                    .assignment_outlined,
                color:
                    AppTheme.primary,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No requests yet. Find a resource to get started.',
                  style: TextStyle(
                    color:
                        AppTheme
                            .mutedText,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    AppTheme.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// REQUEST PREVIEW
// ============================================================================

class _RequestPreviewCard
    extends StatelessWidget {
  final String resourceName;
  final String department;
  final String status;
  final Color statusColor;

  const _RequestPreviewCard({
    required this.resourceName,
    required this.department,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFE2F1ED),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons
                  .inventory_2_outlined,
              color:
                  AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  resourceName,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppTheme.text,
                  ),
                ),
                const SizedBox(
                    height: 3),
                Text(
                  department,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color: AppTheme
                        .mutedText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration:
                BoxDecoration(
              color:
                  statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SAVINGS CARD
// ============================================================================

class _SavingsCard
    extends StatelessWidget {
  final VoidCallback onTap;

  const _SavingsCard({
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          const Color(0xFFEAF6F2),
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color: AppTheme
                      .primary
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(15),
                ),
                child: const Icon(
                  Icons
                      .savings_outlined,
                  color:
                      AppTheme.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Smart Savings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            AppTheme.text,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Potential cost avoided',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme
                            .mutedText,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '₹90,000',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight
                                .bold,
                        color: AppTheme
                            .primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 16,
                color:
                    AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FEATURED RESOURCE
// ============================================================================

class _FeaturedResourceCard
    extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const _FeaturedResourceCard({
    required this.resource,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE2F1ED,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  color:
                      AppTheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      resource.name,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppTheme.text,
                      ),
                    ),
                    const SizedBox(
                        height: 4),
                    Text(
                      '${resource.department} • '
                      '${resource.location}',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme
                                .mutedText,
                      ),
                    ),
                    const SizedBox(
                        height: 7),
                    Text(
                      '${resource.availableQuantity} available',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight
                                .w600,
                        color:
                            Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    AppTheme.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}