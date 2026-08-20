import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'smart_inventory_sync_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User admin;

  const AdminDashboardScreen({
    super.key,
    required this.admin,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  bool _loading = true;

  String? _error;

  Map<String, dynamic> _dashboard = {};

  List<Map<String, dynamic>> _requests = [];

  List<Map<String, dynamic>> _resources = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ==========================================================================
  // LOAD DASHBOARD
  // ==========================================================================

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dashboard =
          await ApiService.getAdminDashboard();

      final requests =
          await ApiService.getAdminRequests();

      final resources =
          await ApiService.getAdminResources();

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _requests = requests;
        _resources = resources;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );

        _loading = false;
      });
    }
  }

  // ==========================================================================
  // UPDATE REQUEST STATUS
  // ==========================================================================

  Future<void> _updateStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      await ApiService.updateAdminRequestStatus(
        requestId: requestId,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request ${status.toLowerCase()} successfully.',
          ),
        ),
      );

      await _loadDashboard();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // ADD / EDIT RESOURCE
  // ==========================================================================

  Future<void> _showResourceDialog({
    Map<String, dynamic>? resource,
  }) async {
    final isEditing = resource != null;

    final nameController = TextEditingController(
      text:
          resource?['name']?.toString() ?? '',
    );

    final categoryController = TextEditingController(
      text:
          resource?['category']?.toString() ?? '',
    );

    final departmentController = TextEditingController(
      text:
          resource?['department']?.toString() ?? '',
    );

    final locationController = TextEditingController(
      text:
          resource?['location']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text:
          resource?['description']?.toString() ?? '',
    );

    final quantityController = TextEditingController(
      text:
          resource?['quantity']?.toString() ?? '1',
    );

    final availableController = TextEditingController(
      text:
          resource?['available_quantity']?.toString() ?? '1',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Resource'
                    : 'Add Resource',
              ),

              content: SingleChildScrollView(
                child: Form(
                  key: formKey,

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      TextFormField(
                        controller:
                            nameController,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Resource name',
                        ),

                        validator:
                            (value) =>
                                value == null ||
                                        value
                                            .trim()
                                            .isEmpty
                                    ? 'Required'
                                    : null,
                      ),

                      TextFormField(
                        controller:
                            categoryController,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Category',
                        ),

                        validator:
                            (value) =>
                                value == null ||
                                        value
                                            .trim()
                                            .isEmpty
                                    ? 'Required'
                                    : null,
                      ),

                      TextFormField(
                        controller:
                            departmentController,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Department',
                        ),

                        validator:
                            (value) =>
                                value == null ||
                                        value
                                            .trim()
                                            .isEmpty
                                    ? 'Required'
                                    : null,
                      ),

                      TextFormField(
                        controller:
                            locationController,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Location',
                        ),

                        validator:
                            (value) =>
                                value == null ||
                                        value
                                            .trim()
                                            .isEmpty
                                    ? 'Required'
                                    : null,
                      ),

                      TextFormField(
                        controller:
                            descriptionController,

                        maxLines: 3,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Description',
                        ),
                      ),

                      TextFormField(
                        controller:
                            quantityController,

                        keyboardType:
                            TextInputType.number,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Total quantity',
                        ),

                        validator: (value) {
                          final number =
                              int.tryParse(
                            value ?? '',
                          );

                          if (number == null ||
                              number < 1) {
                            return
                                'Enter a valid quantity';
                          }

                          return null;
                        },
                      ),

                      TextFormField(
                        controller:
                            availableController,

                        keyboardType:
                            TextInputType.number,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Available quantity',
                        ),

                        validator: (value) {
                          final available =
                              int.tryParse(
                            value ?? '',
                          );

                          final total =
                              int.tryParse(
                            quantityController
                                .text,
                          );

                          if (available == null ||
                              available < 0) {
                            return
                                'Enter a valid quantity';
                          }

                          if (total != null &&
                              available > total) {
                            return
                                'Cannot exceed total quantity';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () =>
                          Navigator.pop(
                        dialogContext,
                        false,
                      ),

                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final formState = formKey.currentState;

if (formState == null) {
  return;
}

if (!formState.validate()) {
  return;
}

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final quantity =
                                int.parse(
                              quantityController
                                  .text,
                            );

                            final available =
                                int.parse(
                              availableController
                                  .text,
                            );

                         if (isEditing) {
  await ApiService.updateResource(
    resourceId: int.parse(
      resource['id'].toString(),
    ),

    name:
        nameController.text.trim(),

    category:
        categoryController.text.trim(),

    department:
        departmentController.text.trim(),

    location:
        locationController.text.trim(),

    description:
        descriptionController.text.trim(),

    quantity:
        quantity,

    availableQuantity:
        available,
  );
} else {
  await ApiService.createResource(
    name:
        nameController.text.trim(),

    category:
        categoryController.text.trim(),

    department:
        departmentController.text.trim(),

    location:
        locationController.text.trim(),

    description:
        descriptionController.text.trim(),

    quantity:
        quantity,

    availableQuantity:
        available,
  );
}

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } catch (error) {
                            setDialogState(() {
                              saving = false;
                            });

                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error
                                      .toString()
                                      .replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                ),
                              ),
                            );
                          }
                        },

                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing
                              ? 'Save'
                              : 'Add',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    categoryController.dispose();
    departmentController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    availableController.dispose();

    if (result == true) {
      await _loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Resource updated successfully.'
                : 'Resource added successfully.',
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // DELETE RESOURCE
  // ==========================================================================

  Future<void> _deleteResource(
    Map<String, dynamic> resource,
  ) async {
    final name =
        resource['name']?.toString() ??
            'this resource';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            const Text('Delete resource?'),

        content: Text(
          'Are you sure you want to delete $name?',
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),

            child:
                const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red,

              foregroundColor:
                  Colors.white,
            ),

            child:
                const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.deleteResource(
        int.parse(
          resource['id'].toString(),
        ),
      );

      await _loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Resource deleted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // OPEN SMART INVENTORY SYNC
  // ==========================================================================

  Future<void> _openSmartInventorySync() async {
    final changed =
        await Navigator.push<bool>(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const SmartInventorySyncScreen(),
      ),
    );

    if (changed == true) {
      await _loadDashboard();
    }
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  void _logout() {
    ApiService.logout();

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),

      (route) => false,
    );
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

      appBar: AppBar(
        backgroundColor:
            AppTheme.background,

        elevation: 0,

        title: const Text(
          'LabLink Admin',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,

            color:
                AppTheme.text,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',

            onPressed:
                _loading
                    ? null
                    : _loadDashboard,

            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),

          IconButton(
            tooltip: 'Logout',

            onPressed: _logout,

            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ==========================================================================
  // BODY
  // ==========================================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh:
          _loadDashboard,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(18),

        children: [
          _buildWelcome(),

          const SizedBox(
            height: 24,
          ),

          _buildStats(),

          const SizedBox(
            height: 28,
          ),

          _buildResourcesSection(),

          const SizedBox(
            height: 30,
          ),

          _buildRequestsHeader(),

          const SizedBox(
            height: 12,
          ),

          _requests.isEmpty
              ? _buildEmptyRequests()
              : Column(
                  children:
                      _requests
                          .map(
                            _buildRequestCard,
                          )
                          .toList(),
                ),
        ],
      ),
    );
  }

  // ==========================================================================
  // WELCOME
  // ==========================================================================

  Widget _buildWelcome() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        color:
            AppTheme.primary,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.15,
              ),

              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),

            child:
                const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Welcome back',

                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  widget.admin.name,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  widget.admin.department,

                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STATISTICS
  // ==========================================================================

  Widget _buildStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child:
                  _buildStatCard(
                title:
                    'Resources',

                value:
                    _dashboard[
                            'total_resources']
                        ?.toString() ??
                        _resources.length
                            .toString(),

                icon:
                    Icons.inventory_2_outlined,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
                  _buildStatCard(
                title:
                    'Available',

                value:
                    _dashboard[
                            'available_resources']
                        ?.toString() ??
                        _resources
                            .where(
                              (resource) =>
                                  (int.tryParse(
                                        resource[
                                                'available_quantity']
                                            ?.toString() ??
                                            '0',
                                      ) ??
                                      0) >
                                  0,
                            )
                            .length
                            .toString(),

                icon:
                    Icons.check_circle_outline,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Expanded(
              child:
                  _buildStatCard(
                title:
                    'Users',

                value:
                    _dashboard[
                            'total_users']
                        ?.toString() ??
                        '0',

                icon:
                    Icons.people_outline,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
                  _buildStatCard(
                title:
                    'Pending',

                value:
                    _dashboard[
                            'pending_requests']
                        ?.toString() ??
                        '0',

                icon:
                    Icons.pending_actions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha: 0.04,
            ),

            blurRadius: 10,

            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  AppTheme.primary
                      .withValues(
                alpha: 0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                Icon(
              icon,
              color:
                  AppTheme.primary,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            value,

            style:
                const TextStyle(
              fontSize: 26,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.text,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            title,

            style:
                const TextStyle(
              fontSize: 13,
              color:
                  AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // RESOURCE SECTION
  // ==========================================================================

  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Resource Management',

                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppTheme.text,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed:
                  () =>
                      _showResourceDialog(),

              icon:
                  const Icon(
                Icons.add_rounded,
                size: 18,
              ),

              label:
                  const Text(
                'Add',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.primary,

                foregroundColor:
                    Colors.white,

                elevation:
                    0,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        if (_resources.isEmpty)
          _buildEmptyResources()
        else
          Column(
            children:
                _resources
                    .map(
                      _buildResourceCard,
                    )
                    .toList(),
          ),

        // ======================================================================
        // SMART INVENTORY SYNC
        // ======================================================================

        const SizedBox(
          height: 18,
        ),

        _buildSmartInventorySyncCard(),
      ],
    );
  }

  // ==========================================================================
  // SMART INVENTORY SYNC CARD
  // ==========================================================================

  Widget _buildSmartInventorySyncCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          colors: [
            AppTheme.primary,

            AppTheme.primary
                .withValues(
              alpha: 0.82,
            ),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.15,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                    const Icon(
                  Icons.auto_awesome,
                  color:
                      Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Smart Inventory Sync',

                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Update resources from inventory PDFs with admin validation.',

                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          Container(
            padding:
                const EdgeInsets.all(11),

            decoration:
                BoxDecoration(
              color:
                  Colors.white
                      .withValues(
                alpha: 0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                const Row(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color:
                      Colors.white70,
                  size: 19,
                ),

                SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    'Upload → Analyze → Review → Approve → Apply',

                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          SizedBox(
            width:
                double.infinity,

            child:
                ElevatedButton.icon(
              onPressed:
                  _openSmartInventorySync,

              icon:
                  const Icon(
                Icons.upload_file,
              ),

              label:
                  const Text(
                'Open Inventory Sync',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white,

                foregroundColor:
                    AppTheme.primary,

                elevation:
                    0,

                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // RESOURCE CARD
  // ==========================================================================

  Widget _buildResourceCard(
    Map<String, dynamic> resource,
  ) {
    final name =
        resource['name']?.toString() ??
            'Unknown Resource';

    final category =
        resource['category']?.toString() ??
            '';

    final location =
        resource['location']?.toString() ??
            '';

    final quantity =
        int.tryParse(
              resource['quantity']
                      ?.toString() ??
                  '',
            ) ??
            0;

    final available =
        int.tryParse(
              resource[
                        'available_quantity']
                    ?.toString() ??
                  '',
            ) ??
            0;

    final status =
        resource['status']?.toString() ??
            'Available';

    final availableNow =
        available > 0 &&
        status != 'Inactive';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(17),

        border:
            Border.all(
          color:
              const Color(
            0xFFE7ECEA,
          ),
        ),
      ),

      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width: 46,
                height: 46,

                decoration:
                    BoxDecoration(
                  color:
                      AppTheme.primary
                          .withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),

                child:
                    const Icon(
                  Icons
                      .inventory_2_outlined,

                  color:
                      AppTheme.primary,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      name,

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,

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
                      height: 3,
                    ),

                    Text(
                      category,

                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            AppTheme.mutedText,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      location,

                      maxLines: 1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),

              _resourceStatusChip(
                status,
                availableNow,
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Row(
            children: [
              const Icon(
                Icons.inventory_outlined,

                size: 16,

                color:
                    AppTheme.mutedText,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                '$available / $quantity available',

                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppTheme.text,
                ),
              ),

              const Spacer(),

              IconButton(
                tooltip:
                    'Edit',

                onPressed:
                    () =>
                        _showResourceDialog(
                  resource:
                      resource,
                ),

                icon:
                    const Icon(
                  Icons.edit_outlined,
                  size: 19,
                ),
              ),

              IconButton(
                tooltip:
                    'Delete',

                onPressed:
                    () =>
                        _deleteResource(
                  resource,
                ),

                icon:
                    const Icon(
                  Icons.delete_outline,
                  size: 19,
                  color:
                      Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // RESOURCE STATUS
  // ==========================================================================

  Widget _resourceStatusChip(
    String status,
    bool available,
  ) {
    final color =
        available
            ? Colors.green
            : Colors.red;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        status,

        style:
            TextStyle(
          color:
              color,

          fontSize: 10,

          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================================================
  // EMPTY RESOURCES
  // ==========================================================================

  Widget _buildEmptyResources() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        25,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          17,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,

            size: 42,

            color:
                AppTheme.primary,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'No resources found',

            style:
                TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // REQUEST HEADER
  // ==========================================================================

  Widget _buildRequestsHeader() {
    final pending =
        _dashboard[
                'pending_requests']
            ?.toString() ??
            '0';

    return Row(
      children: [
        const Expanded(
          child:
              Text(
            'Resource Requests',

            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.text,
            ),
          ),
        ),

        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 10,
            vertical: 6,
          ),

          decoration:
              BoxDecoration(
            color:
                Colors.orange
                    .withValues(
              alpha: 0.10,
            ),

            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          child:
              Text(
            '$pending pending',

            style:
                const TextStyle(
              color:
                  Colors.orange,

              fontSize: 12,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // REQUEST CARD
  // ==========================================================================

  Widget _buildRequestCard(
    Map<String, dynamic> request,
  ) {
    final id =
        int.tryParse(
              request['id']
                      ?.toString() ??
                  '',
            ) ??
            0;

    final resourceName =
        request['resource_name']
                ?.toString() ??
            'Unknown Resource';

    final requesterName =
        request['requester_name']
                ?.toString() ??
            'Unknown User';

    final department =
        request[
                    'requester_department']
                ?.toString() ??
            '';

    final purpose =
        request['purpose']
                ?.toString() ??
            '';

    final status =
        request['status']
                ?.toString() ??
            'Pending';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
          const EdgeInsets.all(17),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(18),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(
                  resourceName,

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppTheme.text,
                  ),
                ),
              ),

              _buildStatusChip(
                status,
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              const Icon(
                Icons.person_outline,

                size: 18,

                color:
                    AppTheme.mutedText,
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child:
                    Text(
                  requesterName,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            department,

            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppTheme.mutedText,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

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
                  AppTheme.background,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                Text(
              purpose,

              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    AppTheme.mutedText,
              ),
            ),
          ),

          if (status.toLowerCase() ==
              'pending') ...[
            const SizedBox(
              height: 14,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton(
                    onPressed:
                        () =>
                            _updateStatus(
                      requestId:
                          id,

                      status:
                          'Rejected',
                    ),

                    child:
                        const Text(
                      'Reject',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      ElevatedButton(
                    onPressed:
                        () =>
                            _updateStatus(
                      requestId:
                          id,

                      status:
                          'Approved',
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          AppTheme
                              .primary,

                      foregroundColor:
                          Colors.white,

                      elevation:
                          0,
                    ),

                    child:
                        const Text(
                      'Approve',
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

  // ==========================================================================
  // REQUEST STATUS CHIP
  // ==========================================================================

  Widget _buildStatusChip(
    String status,
  ) {
    final normalized =
        status.toLowerCase();

    Color color;

    if (normalized ==
        'approved') {
      color =
          Colors.green;
    } else if (normalized ==
        'rejected') {
      color =
          Colors.red;
    } else if (normalized ==
        'completed') {
      color =
          Colors.blue;
    } else {
      color =
          Colors.orange;
    }

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
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        status,

        style:
            TextStyle(
          color:
              color,

          fontSize: 11,

          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ==========================================================================
  // EMPTY REQUESTS
  // ==========================================================================

  Widget _buildEmptyRequests() {
    return Container(
      padding:
          const EdgeInsets.all(
        30,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons
                .assignment_turned_in_outlined,

            size: 48,

            color:
                AppTheme.primary,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'No resource requests',

            style:
                TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ERROR
  // ==========================================================================

  Widget _buildError() {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),

        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,

              size: 52,

              color:
                  Colors.red,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Unable to load admin dashboard',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _error ??
                  'Unknown error',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    AppTheme.mutedText,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            ElevatedButton(
              onPressed:
                  _loadDashboard,

              child:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}