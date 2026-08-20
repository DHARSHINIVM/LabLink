import 'package:flutter/material.dart';

import '../../models/resource.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'resource_details_screen.dart';

class ResourceSearchScreen extends StatefulWidget {
  const ResourceSearchScreen({super.key});

  @override
  State<ResourceSearchScreen> createState() =>
      _ResourceSearchScreenState();
}

class _ResourceSearchScreenState
    extends State<ResourceSearchScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  List<Resource> _resources = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedCategory = 'All';
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOAD RESOURCES FROM BACKEND
  // --------------------------------------------------------------------------

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getResources();

      if (!mounted) return;

      setState(() {
        _resources = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load resources from the server.';
      });
    }
  }

  // --------------------------------------------------------------------------
  // FILTERED RESOURCES
  // --------------------------------------------------------------------------

  List<Resource> get _filteredResources {
    final query = _searchQuery.trim().toLowerCase();

    return _resources.where((resource) {
      final matchesSearch =
          query.isEmpty ||
          resource.name.toLowerCase().contains(query) ||
          resource.category.toLowerCase().contains(query) ||
          resource.department.toLowerCase().contains(query) ||
          resource.location.toLowerCase().contains(query) ||
          resource.description.toLowerCase().contains(query);

      final matchesDepartment =
          _selectedDepartment == 'All' ||
          resource.department == _selectedDepartment;

      final matchesCategory =
          _selectedCategory == 'All' ||
          resource.category == _selectedCategory;

      final matchesAvailability =
          !_availableOnly ||
          resource.availableQuantity > 0;

      return matchesSearch &&
          matchesDepartment &&
          matchesCategory &&
          matchesAvailability;
    }).toList();
  }

  // --------------------------------------------------------------------------
  // DEPARTMENTS
  // --------------------------------------------------------------------------

  List<String> get _departments {
    final departments = _resources
        .map((resource) => resource.department)
        .where((department) => department.isNotEmpty)
        .toSet()
        .toList();

    departments.sort();

    return ['All', ...departments];
  }

  // --------------------------------------------------------------------------
  // CATEGORIES
  // --------------------------------------------------------------------------

  List<String> get _categories {
    final categories = _resources
        .map((resource) => resource.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort();

    return ['All', ...categories];
  }

  bool get _hasActiveFilters {
    return _selectedDepartment != 'All' ||
        _selectedCategory != 'All' ||
        _availableOnly;
  }

  // --------------------------------------------------------------------------
  // CLEAR FILTERS
  // --------------------------------------------------------------------------

  void _clearFilters() {
    setState(() {
      _selectedDepartment = 'All';
      _selectedCategory = 'All';
      _availableOnly = false;
    });
  }

  void _clearAll() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedDepartment = 'All';
      _selectedCategory = 'All';
      _availableOnly = false;
    });
  }

  // --------------------------------------------------------------------------
  // FILTER BOTTOM SHEET
  // --------------------------------------------------------------------------

  void _showFilters() {
    String department = _selectedDepartment;
    String category = _selectedCategory;
    bool availableOnly = _availableOnly;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                28,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              department = 'All';
                              category = 'All';
                              availableOnly = false;
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Department',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _departments.map((item) {
                        final selected =
                            department == item;

                        return ChoiceChip(
                          label: Text(item),
                          selected: selected,
                          onSelected: (_) {
                            setSheetState(() {
                              department = item;
                            });
                          },
                          selectedColor:
                              const Color(0xFFE2F1ED),
                          labelStyle: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.text,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppTheme.primary
                                : const Color(
                                    0xFFE1E7E5,
                                  ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                      ),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _categories.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          category = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Available resources only',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Hide resources that cannot be requested',
                      ),
                      value: availableOnly,
                      activeThumbColor:
                          AppTheme.primary,
                      onChanged: (value) {
                        setSheetState(() {
                          availableOnly = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDepartment =
                                department;
                            _selectedCategory = category;
                            _availableOnly =
                                availableOnly;
                          });

                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final resources = _filteredResources;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Find Resources',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadResources,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    textInputAction:
                        TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search resources...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController
                                        .clear();

                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                  ),
                                )
                              : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                        borderSide:
                            const BorderSide(
                          color: AppTheme.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? AppTheme.primary
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        onPressed: _showFilters,
                        icon: Icon(
                          Icons.tune_rounded,
                          color: _hasActiveFilters
                              ? Colors.white
                              : AppTheme.text,
                        ),
                      ),
                    ),

                    if (_hasActiveFilters)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration:
                              const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ACTIVE FILTERS
          if (_hasActiveFilters)
            SizedBox(
              height: 42,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedDepartment != 'All')
                    _FilterChip(
                      label: _selectedDepartment,
                      onRemove: () {
                        setState(() {
                          _selectedDepartment =
                              'All';
                        });
                      },
                    ),

                  if (_selectedCategory != 'All')
                    _FilterChip(
                      label: _selectedCategory,
                      onRemove: () {
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                    ),

                  if (_availableOnly)
                    _FilterChip(
                      label: 'Available only',
                      onRemove: () {
                        setState(() {
                          _availableOnly = false;
                        });
                      },
                    ),
                ],
              ),
            ),

          // RESULT COUNT
          Padding(
            padding:
                const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Row(
              children: [
                Text(
                  '${resources.length} resource'
                  '${resources.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: _buildContent(resources),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Resource> resources) {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primary,
                ),
                SizedBox(height: 14),
                Text(
                  'Loading resources...',
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

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 100),

          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: Colors.orange,
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Make sure the LabLink backend is running.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.mutedText,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: ElevatedButton.icon(
              onPressed: _loadResources,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (resources.isEmpty) {
      return _EmptySearchState(
        query: _searchQuery,
        onClear: _clearAll,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadResources,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          28,
        ),
        itemCount: resources.length,
        separatorBuilder: (_, index) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final resource = resources[index];

          return _ResourceCard(
            resource: resource,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ResourceDetailsScreen(
                    resource: resource,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// RESOURCE CARD
// ============================================================================

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.resource,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = resource.availableQuantity > 0;

    final utilizationPercent =
        resource.utilization.round().clamp(0, 100);

    final utilizationColor =
        utilizationPercent >= 80
            ? Colors.red
            : utilizationPercent >= 60
                ? Colors.orange
                : Colors.green;

    final availabilityText = available
        ? '${resource.availableQuantity} available'
        : 'Currently unavailable';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7ECEA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor:
              AppTheme.primary.withValues(alpha: 0.08),
          highlightColor:
              AppTheme.primary.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ============================================================
                // TOP SECTION
                // ============================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // RESOURCE ICON
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE8F6F1),
                            Color(0xFFD8EEE7),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // NAME + DETAILS
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  resource.name,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: AppTheme.text,
                                    height: 1.2,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              const Icon(
                                Icons
                                    .arrow_outward_rounded,
                                size: 17,
                                color:
                                    AppTheme.mutedText,
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(
                                0xFFF0F5F3,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                7,
                              ),
                            ),
                            child: Text(
                              resource.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // ============================================================
                // LOCATION
                // ============================================================

                Row(
                  children: [
                    const Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        resource.department,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        resource.location,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color:
                              AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ============================================================
                // AVAILABILITY + UTILIZATION
                // ============================================================

                Row(
                  children: [
                    // AVAILABILITY
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: available
                            ? const Color(
                                0xFFEAF7F0,
                              )
                            : const Color(
                                0xFFFFEEEE,
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
                            width: 7,
                            height: 7,
                            decoration:
                                BoxDecoration(
                              color: available
                                  ? Colors.green
                                  : Colors.red,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            availabilityText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.bold,
                              color: available
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // UTILIZATION
                    Text(
                      'Utilization ',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    Text(
                      '$utilizationPercent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            utilizationColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ============================================================
                // UTILIZATION BAR
                // ============================================================

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child:
                      LinearProgressIndicator(
                    value:
                        utilizationPercent / 100,
                    minHeight: 6,
                    backgroundColor:
                        const Color(0xFFE9EEEC),
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      utilizationColor,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ============================================================
                // BOTTOM ACTION
                // ============================================================

                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: available
                        ? const Color(
                            0xFFEAF6F2,
                          )
                        : const Color(
                            0xFFF2F3F3,
                          ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        available
                            ? Icons
                                .send_outlined
                            : Icons
                                .block_outlined,
                        size: 16,
                        color: available
                            ? AppTheme.primary
                            : AppTheme.mutedText,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        available
                            ? 'View & Request'
                            : 'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                          color: available
                              ? AppTheme.primary
                              : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FILTER CHIP
// ============================================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F1ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),

          IconButton(
            visualDensity:
                VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 15,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptySearchState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _EmptySearchState({
    required this.query,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),

        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE2F1ED),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 38,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'No resources found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  query.isEmpty
                      ? 'Try changing your filters.'
                      : 'No resources match "$query".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                OutlinedButton(
                  onPressed: onClear,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        AppTheme.primary,
                    side: const BorderSide(
                      color: AppTheme.primary,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      const Text('Clear Search'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}