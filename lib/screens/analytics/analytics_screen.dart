import 'package:flutter/material.dart';

import '../../models/resource.dart';
import '../../services/api_service.dart';
import '../../services/request_store.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final RequestStore requestStore = RequestStore.instance;

  List<Resource> resources = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getResources();

      if (!mounted) return;

      setState(() {
        resources = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load analytics data.';
      });
    }
  }

  int get totalResources => resources.length;

  int get availableResources {
    return resources
        .where((resource) => resource.availableQuantity > 0)
        .length;
  }

  int get unavailableResources {
    return totalResources - availableResources;
  }

  int get underutilizedResources {
    return resources
        .where((resource) => resource.utilization < 50)
        .length;
  }

  double get averageUtilization {
    if (resources.isEmpty) return 0;

    final total = resources.fold<double>(
      0,
      (sum, resource) => sum + resource.utilization,
    );

    return total / resources.length;
  }

  int get totalUnits {
    return resources.fold<int>(
      0,
      (sum, resource) => sum + resource.quantity,
    );
  }

  int get availableUnits {
    return resources.fold<int>(
      0,
      (sum, resource) => sum + resource.availableQuantity,
    );
  }

  int get sharedUnits {
    return totalUnits - availableUnits;
  }

  Map<String, int> get departmentCounts {
    final counts = <String, int>{};

    for (final resource in resources) {
      counts[resource.department] =
          (counts[resource.department] ?? 0) + 1;
    }

    return counts;
  }

  List<MapEntry<String, int>> get sortedDepartments {
    final entries = departmentCounts.entries.toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    return entries;
  }

  List<Resource> get topUtilizedResources {
    final list = [...resources];

    list.sort(
      (a, b) => b.utilization.compareTo(a.utilization),
    );

    return list;
  }

  List<Resource> get underutilizedList {
    final list = resources
        .where((resource) => resource.utilization < 50)
        .toList();

    list.sort(
      (a, b) => a.utilization.compareTo(b.utilization),
    );

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadAnalytics,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primary,
                ),
                SizedBox(height: 14),
                Text(
                  'Loading analytics...',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.cloud_off_rounded,
            size: 50,
            color: Colors.orange,
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (resources.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(
            child: Text(
              'No resource data available.',
              style: TextStyle(
                color: AppTheme.mutedText,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        32,
      ),
      children: [
        const Text(
          'Resource Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.text,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Monitor institutional resource utilization '
          'and sharing activity.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.mutedText,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 22),

        // ----------------------------------------------------------
        // PRIMARY KPIs
        // ----------------------------------------------------------

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Resources',
                value: '$totalResources',
                subtitle: 'Registered',
                icon: Icons.inventory_2_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Available',
                value: '$availableResources',
                subtitle: 'Requestable',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Utilization',
                value: '${averageUtilization.round()}%',
                subtitle: 'Average',
                icon: Icons.analytics_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Underused',
                value: '$underutilizedResources',
                subtitle: 'Resources',
                icon: Icons.trending_down_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        const _SectionHeader(
          title: 'Overall Utilization',
          subtitle: 'How effectively resources are being used',
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${averageUtilization.round()}%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 7),
                    child: Text(
                      'average utilization',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (averageUtilization / 100)
                      .clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor:
                      const Color(0xFFE8EEEC),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    AppTheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _LegendItem(
                    color: Colors.green,
                    label: 'Healthy',
                  ),
                  _LegendItem(
                    color: Colors.orange,
                    label: 'Moderate',
                  ),
                  _LegendItem(
                    color: Colors.red,
                    label: 'High demand',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        const _SectionHeader(
          title: 'Resource Status',
          subtitle: 'Current availability across the inventory',
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _StatusRow(
                icon: Icons.check_circle_outline,
                title: 'Available',
                value: '$availableResources',
                color: Colors.green,
                total: totalResources,
              ),
              const SizedBox(height: 16),
              _StatusRow(
                icon: Icons.cancel_outlined,
                title: 'Unavailable',
                value: '$unavailableResources',
                color: Colors.red,
                total: totalResources,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        const _SectionHeader(
          title: 'Department Distribution',
          subtitle: 'Resources registered by department',
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: sortedDepartments
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 14,
                    ),
                    child: _DepartmentBar(
                      department: entry.key,
                      count: entry.value,
                      total: totalResources,
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 28),

        const _SectionHeader(
          title: 'Sharing Activity',
          subtitle: 'Institution-wide resource movement',
        ),

        const SizedBox(height: 12),

        AnimatedBuilder(
          animation: requestStore,
          builder: (context, child) {
            return Row(
              children: [
                Expanded(
                  child: _SmallMetricCard(
                    icon: Icons.inventory_outlined,
                    title: 'Total Units',
                    value: '$totalUnits',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallMetricCard(
                    icon: Icons.sync_alt_rounded,
                    title: 'In Use',
                    value: '$sharedUnits',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallMetricCard(
                    icon: Icons.pending_actions_outlined,
                    title: 'Requests',
                    value: '${requestStore.requests.length}',
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        const _SectionHeader(
          title: 'High-Demand Resources',
          subtitle: 'Resources with the highest utilization',
        ),

        const SizedBox(height: 12),

        ...topUtilizedResources.take(3).map(
              (resource) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: _ResourceUtilizationCard(
                  name: resource.name,
                  department: resource.department,
                  utilization: resource.utilization,
                ),
              ),
            ),

        const SizedBox(height: 18),

        const _SectionHeader(
          title: 'Underutilized Resources',
          subtitle:
              'Potential resources for cross-department sharing',
        ),

        const SizedBox(height: 12),

        if (underutilizedList.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No significantly underutilized '
                    'resources detected.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.text,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...underutilizedList.take(3).map(
                (resource) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: _UnderutilizedCard(
                    name: resource.name,
                    department: resource.department,
                    utilization: resource.utilization,
                  ),
                ),
              ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD7EAE4),
            ),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Procurement Insight',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Review underutilized resources before '
                      'purchasing new equipment. LabLink can '
                      'help departments share existing assets.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Center(
          child: Text(
            'Live analytics • PostgreSQL',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// METRIC CARD
// ===========================================================================

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SECTION HEADER
// ===========================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
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

// ===========================================================================
// LEGEND
// ===========================================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// STATUS ROW
// ===========================================================================

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final int total;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(value) ?? 0;

    final percentage = total == 0
        ? 0.0
        : current / total;

    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 21,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE8EEEC),
            valueColor:
                AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// DEPARTMENT BAR
// ===========================================================================

class _DepartmentBar extends StatelessWidget {
  final String department;
  final int count;
  final int total;

  const _DepartmentBar({
    required this.department,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        total == 0 ? 0.0 : count / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                department,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text,
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: const Color(0xFFE8EEEC),
            valueColor:
                const AlwaysStoppedAnimation<Color>(
              AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SMALL METRIC
// ===========================================================================

class _SmallMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SmallMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// RESOURCE UTILIZATION
// ===========================================================================

class _ResourceUtilizationCard extends StatelessWidget {
  final String name;
  final String department;
  final double utilization;

  const _ResourceUtilizationCard({
    required this.name,
    required this.department,
    required this.utilization,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = utilization.round();

    final color = percentage >= 80
        ? Colors.red
        : percentage >= 60
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  department,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// UNDERUTILIZED RESOURCE
// ===========================================================================

class _UnderutilizedCard extends StatelessWidget {
  final String name;
  final String department;
  final double utilization;

  const _UnderutilizedCard({
    required this.name,
    required this.department,
    required this.utilization,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = utilization.round();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFF3E4C2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$department • $percentage% utilized',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}