import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SmartInventorySyncScreen
    extends StatefulWidget {

  const SmartInventorySyncScreen({
    super.key,
  });

  @override
  State<SmartInventorySyncScreen>
      createState() =>
          _SmartInventorySyncScreenState();
}

class _SmartInventorySyncScreenState
    extends State<
        SmartInventorySyncScreen> {

  File? _selectedFile;

  Map<String, dynamic>? _result;

  final Set<int> _selectedIndexes =
      <int>{};

  bool _uploading = false;

  bool _applying = false;

  String? _error;

  // ==========================================================================
  // PICK PDF
  // ==========================================================================

 Future<void> _pickPdf() async {
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isEmpty) {
      return;
    }

    final selectedFile = files.first;

    final path = selectedFile.path;

    if (path == null || path.isEmpty) {
      _showError(
        'Unable to access the selected file.',
      );
      return;
    }

    setState(() {
      _selectedFile = File(path);
      _result = null;
      _error = null;
      _selectedIndexes.clear();
    });
  } catch (error) {
    _showError(
      error.toString(),
    );
  }
}
  // ==========================================================================
  // ANALYZE PDF
  // ==========================================================================

  Future<void> _analyzePdf() async {

    if (_selectedFile == null) {

      _showError(
        'Please select an inventory PDF first.',
      );

      return;
    }

    setState(() {

      _uploading = true;

      _error = null;

      _result = null;

      _selectedIndexes.clear();
    });

    try {

      final result =
          await ApiService
              .reconcileInventoryPdf(
        _selectedFile!,
      );

      if (!mounted) return;

      final items =
          _itemsFromResult(
        result,
      );

      setState(() {

        _result = result;

        _uploading = false;

        // Select NEW and UPDATE items by default.
        for (
          int i = 0;
          i < items.length;
          i++
        ) {

          final action =
              items[i]['action']
                  ?.toString()
                  .toUpperCase();

          if (action == 'NEW' ||
              action == 'UPDATE') {

            _selectedIndexes.add(i);
          }
        }
      });

    } catch (error) {

      if (!mounted) return;

      setState(() {

        _uploading = false;

        _error = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ==========================================================================
  // ITEMS
  // ==========================================================================

  List<Map<String, dynamic>>
      _itemsFromResult(
    Map<String, dynamic> result,
  ) {

    final raw =
        result['items'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  // ==========================================================================
  // APPLY SELECTED
  // ==========================================================================

  Future<void>
      _applySelectedChanges() async {

    if (_result == null) {
      return;
    }

    final items =
        _itemsFromResult(
      _result!,
    );

    final selected =
        _selectedIndexes
            .where(
              (index) =>
                  index >= 0 &&
                  index < items.length,
            )
            .map(
              (index) =>
                  _toApplyPayload(
                items[index],
              ),
            )
            .toList();

    if (selected.isEmpty) {

      _showError(
        'Select at least one change to apply.',
      );

      return;
    }

    final confirmed =
        await _showApplyConfirmation(
      selected.length,
    );

    if (confirmed != true) {
      return;
    }

    setState(() {

      _applying = true;

      _error = null;
    });

    try {

      final response =
          await ApiService
              .applyInventoryChanges(
        selected,
      );

      if (!mounted) return;

      setState(() {

        _applying = false;
      });

      await _showSuccessDialog(
        response,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );

    } catch (error) {

      if (!mounted) return;

      setState(() {

        _applying = false;

        _error = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ==========================================================================
  // CONVERT RECONCILIATION ITEM TO APPLY PAYLOAD
  // ==========================================================================

  Map<String, dynamic>
      _toApplyPayload(
    Map<String, dynamic> item,
  ) {

    final action =
        item['action']
            ?.toString()
            .toUpperCase();

    return {
      'action':
          action,

      'existing_id':
          item['existing_id'],

      'name':
          item['name'],

      'category':
          item['category'],

      'quantity':
          item['quantity'],

      'location':
          item['location'],

      'department':
          item['department'],

      'description':
          item['description'],
    };
  }

  // ==========================================================================
  // CONFIRM
  // ==========================================================================

  Future<bool?>
      _showApplyConfirmation(
    int count,
  ) {

    return showDialog<bool>(
      context: context,
      builder: (context) {

        return AlertDialog(

          title:
              const Text(
            'Apply inventory changes?',
          ),

          content:
              Text(
            'You are about to apply '
            '$count approved change(s) '
            'to the LabLink inventory.',
          ),

          actions: [

            TextButton(
              onPressed:
                  () =>
                      Navigator.pop(
                    context,
                    false,
                  ),

              child:
                  const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed:
                  () =>
                      Navigator.pop(
                    context,
                    true,
                  ),

              child:
                  const Text(
                'Apply',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // EDIT ITEM
  // ==========================================================================

  Future<void> _editItem(
    int index,
  ) async {

    if (_result == null) {
      return;
    }

    final items =
        _itemsFromResult(
      _result!,
    );

    if (index < 0 ||
        index >= items.length) {
      return;
    }

    final item =
        Map<String, dynamic>.from(
      items[index],
    );

    final nameController =
        TextEditingController(
      text:
          item['name']
              ?.toString() ??
              '',
    );

    final categoryController =
        TextEditingController(
      text:
          item['category']
              ?.toString() ??
              '',
    );

    final quantityController =
        TextEditingController(
      text:
          item['quantity']
              ?.toString() ??
              '',
    );

    final locationController =
        TextEditingController(
      text:
          item['location']
              ?.toString() ??
              '',
    );

    final departmentController =
        TextEditingController(
      text:
          item['department']
              ?.toString() ??
              '',
    );

    final descriptionController =
        TextEditingController(
      text:
          item['description']
              ?.toString() ??
              '',
    );

    final formKey =
        GlobalKey<FormState>();

    final saved =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {

        return AlertDialog(

          title:
              const Text(
            'Edit Resource',
          ),

          content:
              SizedBox(
            width:
                500,

            child:
                SingleChildScrollView(
              child:
                  Form(
                key: formKey,

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    TextFormField(
                      controller:
                          nameController,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Name',
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
                    ),

                    TextFormField(
                      controller:
                          quantityController,

                      keyboardType:
                          TextInputType.number,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Quantity',
                      ),

                      validator:
                          (value) {

                        final quantity =
                            int.tryParse(
                          value ?? '',
                        );

                        if (quantity == null ||
                            quantity < 1) {

                          return
                              'Enter a valid quantity';
                        }

                        return null;
                      },
                    ),

                    TextFormField(
                      controller:
                          locationController,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Location',
                      ),
                    ),

                    TextFormField(
                      controller:
                          departmentController,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Department',
                      ),
                    ),

                    TextFormField(
                      controller:
                          descriptionController,

                      maxLines:
                          3,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Description',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          actions: [

            TextButton(
              onPressed:
                  () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),

              child:
                  const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed:
                  () {

                if (!formKey
                    .currentState!
                    .validate()) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    if (saved != true) {

      nameController.dispose();
      categoryController.dispose();
      quantityController.dispose();
      locationController.dispose();
      departmentController.dispose();
      descriptionController.dispose();

      return;
    }

    final updated =
        Map<String, dynamic>.from(
      item,
    );

    updated['name'] =
        nameController.text.trim();

    updated['category'] =
        categoryController.text.trim();

    updated['quantity'] =
        int.parse(
      quantityController.text,
    );

    updated['location'] =
        locationController.text.trim();

    updated['department'] =
        departmentController.text.trim();

    updated['description'] =
        descriptionController.text.trim();

    items[index] =
        updated;

    final newResult =
        Map<String, dynamic>.from(
      _result!,
    );

    newResult['items'] =
        items;

    setState(() {

      _result =
          newResult;

      _selectedIndexes.add(
        index,
      );
    });

    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    locationController.dispose();
    departmentController.dispose();
    descriptionController.dispose();
  }

  // ==========================================================================
  // SUCCESS
  // ==========================================================================

  Future<void> _showSuccessDialog(
    Map<String, dynamic> response,
  ) {

    final count =
        response['applied_count']
            ?.toString() ??
            '0';

    return showDialog<void>(
      context: context,
      builder: (context) {

        return AlertDialog(

          icon:
              const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 52,
          ),

          title:
              const Text(
            'Inventory Updated',
          ),

          content:
              Text(
            '$count inventory change(s) '
            'were successfully applied.',
            textAlign:
                TextAlign.center,
          ),

          actions: [

            ElevatedButton(
              onPressed:
                  () =>
                      Navigator.pop(
                    context,
                  ),

              child:
                  const Text(
                'Done',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // ERROR
  // ==========================================================================

  void _showError(
    String message,
  ) {

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message.replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      ),
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

      appBar:
          AppBar(

        title:
            const Text(
          'Smart Inventory Sync',
        ),

        backgroundColor:
            AppTheme.background,

        elevation:
            0,
      ),

      body:
          _buildBody(),
    );
  }

  // ==========================================================================
  // BODY
  // ==========================================================================

  Widget _buildBody() {

    return RefreshIndicator(

      onRefresh:
          () async {

        if (_selectedFile != null) {
          await _analyzePdf();
        }
      },

      child:
          ListView(

        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          18,
        ),

        children: [

          _buildHeader(),

          const SizedBox(
            height: 18,
          ),

          _buildUploadCard(),

          if (_uploading) ...[

            const SizedBox(
              height: 24,
            ),

            const Center(
              child:
                  CircularProgressIndicator(),
            ),

            const SizedBox(
              height: 10,
            ),

            const Center(
              child:
                  Text(
                'Analyzing inventory PDF...',
              ),
            ),
          ],

          if (_error != null) ...[

            const SizedBox(
              height: 18,
            ),

            _buildErrorCard(),
          ],

          if (_result != null) ...[

            const SizedBox(
              height: 24,
            ),

            _buildSummary(),

            const SizedBox(
              height: 20,
            ),

            _buildReviewHeader(),

            const SizedBox(
              height: 12,
            ),

            ..._buildReviewItems(),

            const SizedBox(
              height: 20,
            ),

            _buildApplyButton(),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader() {

    return Container(

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(

        color:
            AppTheme.primary,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Row(
        children: [

          Container(

            width:
                52,

            height:
                52,

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
              Icons.auto_awesome,
              color:
                  Colors.white,
              size:
                  29,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'Smart Inventory Sync',

                  style:
                      TextStyle(
                    color:
                        Colors.white,

                    fontSize:
                        19,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Upload an inventory PDF and review detected changes before updating LabLink.',

                  style:
                      TextStyle(
                    color:
                        Colors.white70,

                    fontSize:
                        12,

                    height:
                        1.4,
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
  // UPLOAD CARD
  // ==========================================================================

  Widget _buildUploadCard() {

    return Container(

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE4EAE7,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'Inventory Document',

            style:
                TextStyle(
              fontSize:
                  16,

              fontWeight:
                  FontWeight.bold,

              color:
                  AppTheme.text,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Supported format: PDF',

            style:
                TextStyle(
              fontSize:
                  12,

              color:
                  AppTheme.mutedText,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Container(

            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              14,
            ),

            decoration:
                BoxDecoration(

              color:
                  AppTheme.background,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child:
                Row(
              children: [

                const Icon(
                  Icons.picture_as_pdf_outlined,

                  color:
                      Colors.red,

                  size:
                      28,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Text(
                    _selectedFile
                            ?.path
                            .split(
                              Platform.pathSeparator,
                            )
                            .last ??
                        'No PDF selected',

                    maxLines:
                        2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize:
                          13,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [

              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _uploading
                          ? null
                          : _pickPdf,

                  icon:
                      const Icon(
                    Icons.upload_file,
                  ),

                  label:
                      const Text(
                    'Choose PDF',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _uploading ||
                              _selectedFile ==
                                  null
                          ? null
                          : _analyzePdf,

                  icon:
                      const Icon(
                    Icons.auto_awesome,
                  ),

                  label:
                      const Text(
                    'Analyze',
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SUMMARY
  // ==========================================================================

  Widget _buildSummary() {

    final total =
        _result?['total_extracted']
                ?.toString() ??
            '0';

    final newCount =
        _result?['new_resources']
                ?.toString() ??
            '0';

    final updated =
        _result?['updated_resources']
                ?.toString() ??
            '0';

    final unchanged =
        _result?['unchanged_resources']
                ?.toString() ??
            '0';

    return Column(
      children: [

        Row(
          children: [

            Expanded(
              child:
                  _summaryCard(
                'Detected',
                total,
                Icons.inventory_2_outlined,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
                  _summaryCard(
                'New',
                newCount,
                Icons.add_circle_outline,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        Row(
          children: [

            Expanded(
              child:
                  _summaryCard(
                'Updates',
                updated,
                Icons.sync_alt,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
                  _summaryCard(
                'Unchanged',
                unchanged,
                Icons.check_circle_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {

    return Container(

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          Column(
        children: [

          Icon(
            icon,

            color:
                AppTheme.primary,

            size:
                24,
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            value,

            style:
                const TextStyle(
              fontSize:
                  22,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Text(
            title,

            style:
                const TextStyle(
              fontSize:
                  11,

              color:
                  AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // REVIEW HEADER
  // ==========================================================================

  Widget _buildReviewHeader() {

    final items =
        _itemsFromResult(
      _result!,
    );

    return Row(
      children: [

        const Expanded(
          child:
              Text(
            'Review Changes',

            style:
                TextStyle(
              fontSize:
                  20,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        TextButton(
          onPressed:
              () {

            setState(() {

              if (_selectedIndexes.length ==
                  items.length) {

                _selectedIndexes.clear();

              } else {

                _selectedIndexes
                  ..clear()
                  ..addAll(
                    List.generate(
                      items.length,
                      (index) => index,
                    ),
                  );
              }
            });
          },

          child:
              Text(
            _selectedIndexes.length ==
                    items.length
                ? 'Clear all'
                : 'Select all',
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // REVIEW ITEMS
  // ==========================================================================

  List<Widget> _buildReviewItems() {

    final items =
        _itemsFromResult(
      _result!,
    );

    return List.generate(
      items.length,
      (index) =>
          _buildReviewCard(
        index,
        items[index],
      ),
    );
  }

  Widget _buildReviewCard(
    int index,
    Map<String, dynamic> item,
  ) {

    final action =
        item['action']
            ?.toString()
            .toUpperCase() ??
            '';

    final selected =
        _selectedIndexes.contains(
      index,
    );

    Color actionColor;

    if (action == 'NEW') {
      actionColor =
          Colors.blue;
    } else if (action == 'UPDATE') {
      actionColor =
          Colors.orange;
    } else {
      actionColor =
          Colors.green;
    }

    final changes =
        item['changes'];

    return Container(

      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          17,
        ),

        border:
            Border.all(
          color:
              selected
                  ? AppTheme.primary
                  : const Color(
                      0xFFE4EAE7,
                    ),
        ),
      ),

      child:
          Column(
        children: [

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Checkbox(
                value:
                    selected,

                onChanged:
                    action ==
                            'UNCHANGED'
                        ? null
                        : (value) {

                            setState(() {

                              if (value ==
                                  true) {

                                _selectedIndexes
                                    .add(
                                  index,
                                );

                              } else {

                                _selectedIndexes
                                    .remove(
                                  index,
                                );
                              }
                            });
                          },
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      item['name']
                              ?.toString() ??
                          'Unknown resource',

                      style:
                          const TextStyle(
                        fontSize:
                            15,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            actionColor
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
                        action,

                        style:
                            TextStyle(
                          color:
                              actionColor,

                          fontSize:
                              10,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip:
                    'Edit',

                onPressed:
                    action ==
                            'UNCHANGED'
                        ? null
                        : () =>
                            _editItem(
                          index,
                        ),

                icon:
                    const Icon(
                  Icons.edit_outlined,
                  size: 19,
                ),
              ),
            ],
          ),

          const Divider(),

          _detailRow(
            'Category',
            item['category'],
          ),

          _detailRow(
            'Quantity',
            item['quantity'],
          ),

          _detailRow(
            'Location',
            item['location'],
          ),

          _detailRow(
            'Department',
            item['department'],
          ),

          if (action == 'UPDATE')
            _buildChanges(
              changes,
            ),

          if (action == 'UPDATE')
            _detailRow(
              'Currently in use',
              item['current_in_use'],
            ),

          if (action == 'UPDATE')
            _detailRow(
              'Proposed available',
              item[
                  'proposed_available_quantity'],
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DETAIL ROW
  // ==========================================================================

  Widget _detailRow(
    String label,
    dynamic value,
  ) {

    if (value == null ||
        value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          SizedBox(
            width:
                125,

            child:
                Text(
              label,

              style:
                  const TextStyle(
                fontSize:
                    11,

                color:
                    AppTheme.mutedText,
              ),
            ),
          ),

          Expanded(
            child:
                Text(
              value.toString(),

              style:
                  const TextStyle(
                fontSize:
                    12,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CHANGES
  // ==========================================================================

  Widget _buildChanges(
    dynamic changes,
  ) {

    if (changes is! Map ||
        changes.isEmpty) {

      return const SizedBox.shrink();
    }

    return Container(

      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        top: 10,
        bottom: 6,
      ),

      padding:
          const EdgeInsets.all(
        11,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.orange
                .withValues(
          alpha: 0.07,
        ),

        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'Detected changes',

            style:
                TextStyle(
              fontSize:
                  11,

              fontWeight:
                  FontWeight.bold,

              color:
                  Colors.orange,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          ...changes.entries.map(
            (entry) {

              final value =
                  entry.value;

              if (value is! Map) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding:
                    const EdgeInsets
                        .only(
                  bottom: 4,
                ),

                child:
                    Text(
                  '${entry.key}: '
                  '${value['old']} → '
                  '${value['new']}',

                  style:
                      const TextStyle(
                    fontSize:
                        11,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // APPLY BUTTON
  // ==========================================================================

  Widget _buildApplyButton() {

    final count =
        _selectedIndexes.length;

    return SizedBox(

      width:
          double.infinity,

      child:
          ElevatedButton.icon(

        onPressed:
            _applying ||
                    count == 0
                ? null
                : _applySelectedChanges,

        icon:
            _applying
                ? const SizedBox(
                    width:
                        18,
                    height:
                        18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2,
                      color:
                          Colors.white,
                    ),
                  )
                : const Icon(
                    Icons
                        .published_with_changes,
                  ),

        label:
            Text(
          _applying
              ? 'Applying...'
              : 'Apply $count Selected Changes',
        ),

        style:
            ElevatedButton.styleFrom(

          backgroundColor:
              AppTheme.primary,

          foregroundColor:
              Colors.white,

          padding:
              const EdgeInsets
                  .symmetric(
            vertical:
                15,
          ),

          elevation:
              0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // ERROR CARD
  // ==========================================================================

  Widget _buildErrorCard() {

    return Container(

      padding:
          const EdgeInsets.all(
        15,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.red
                .withValues(
          alpha: 0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Icon(
            Icons.error_outline,
            color:
                Colors.red,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
                Text(
              _error!,
              style:
                  const TextStyle(
                color:
                    Colors.red,
                fontSize:
                    12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}