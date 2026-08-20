import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/resource.dart';
import '../models/user.dart';

class ApiService {
  // ==========================================================================
  // BASE URL
  // ==========================================================================

  static const String baseUrl =
      'http://127.0.0.1:8000';

  // ==========================================================================
  // AUTHENTICATION
  // ==========================================================================

  static String? _accessToken;

  static User? _currentUser;

  static User? get currentUser =>
      _currentUser;

  static bool get isLoggedIn =>
      _accessToken != null &&
      _accessToken!.isNotEmpty;

  static bool get isAdmin =>
      _currentUser?.isAdmin ?? false;

  // ==========================================================================
  // AUTH HEADERS
  // ==========================================================================

  static Map<String, String>
      get _authHeaders {

    if (!isLoggedIn) {
      throw Exception(
        'You are not authenticated.',
      );
    }

    return {
      'Accept':
          'application/json',

      'Authorization':
          'Bearer $_accessToken',
    };
  }

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  static Future<Map<String, dynamic>>
      login({
    required String email,
    required String password,
  }) async {

    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/auth/login',
      ),
      headers: {
        'Content-Type':
            'application/json',

        'Accept':
            'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid response from server.',
      );
    }

    if (response.statusCode != 200) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ?? 'Login failed.',
      );
    }

    if (decoded is! Map) {
      throw Exception(
        'Invalid login response.',
      );
    }

    final result =
        Map<String, dynamic>.from(
      decoded,
    );

    final token =
        result['access_token']
            ?.toString();

    if (token == null ||
        token.isEmpty) {

      throw Exception(
        'Server did not return an access token.',
      );
    }

    _accessToken = token;

    final userData =
        result['user'];

    if (userData is Map) {

      _currentUser =
          User.fromJson(
        Map<String, dynamic>.from(
          userData,
        ),
      );

    } else {

      throw Exception(
        'Server did not return user information.',
      );
    }

    return result;
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  static void logout() {
    _accessToken = null;
    _currentUser = null;
  }

  // ==========================================================================
  // PARSE USER
  // ==========================================================================

  static User parseUser(
    Map<String, dynamic>
        loginResponse,
  ) {

    final userJson =
        loginResponse['user'];

    if (userJson is! Map) {

      throw Exception(
        'Invalid user information from server.',
      );
    }

    return User.fromJson(
      Map<String, dynamic>.from(
        userJson,
      ),
    );
  }

  // ==========================================================================
  // GET ALL RESOURCES
  // ==========================================================================

  static Future<List<Resource>>
      getResources() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/api/resources',
      ),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Failed to load resources: '
        '${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! List) {

      throw Exception(
        'Invalid resource response from server.',
      );
    }

    return decoded
        .map<Resource>(
          (item) =>
              Resource.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  // ==========================================================================
  // GET RESOURCE BY ID
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      getResourceById(
    int resourceId,
  ) async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/api/resources/'
        '$resourceId',
      ),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Failed to load resource: '
        '${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {

      throw Exception(
        'Invalid resource response.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  // ==========================================================================
  // CREATE RESOURCE REQUEST
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      createRequest({
    required int resourceId,
    required int requesterId,
    required String purpose,
  }) async {

    final response =
        await http.post(
      Uri.parse(
        '$baseUrl/api/requests',
      ),
      headers: {
        'Content-Type':
            'application/json',

        'Accept':
            'application/json',
      },
      body: jsonEncode({
        'resource_id':
            resourceId,

        'requester_id':
            requesterId,

        'purpose':
            purpose,
      }),
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid response from server.',
      );
    }

    if (response.statusCode != 200 &&
        response.statusCode != 201) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to create request.',
      );
    }

    if (decoded is! Map) {

      throw Exception(
        'Invalid request response.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  // ==========================================================================
  // GET ALL STUDENT REQUESTS
  // ==========================================================================

  static Future<
          List<Map<String, dynamic>>>
      getRequests() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/api/requests',
      ),
      headers: {
        'Accept':
            'application/json',
      },
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Failed to load requests: '
        '${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! List) {

      throw Exception(
        'Invalid request response from server.',
      );
    }

    return decoded
        .map<
            Map<String, dynamic>>(
          (item) =>
              Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // ==========================================================================
  // GET REQUESTS FOR CURRENT USER
  // ==========================================================================

  static Future<
          List<Map<String, dynamic>>>
      getUserRequests(
    int userId,
  ) async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/api/requests/user/$userId',
      ),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Failed to load requests: '
        '${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! List) {

      throw Exception(
        'Invalid request response from server.',
      );
    }

    return decoded
        .map<
            Map<String, dynamic>>(
          (item) =>
              Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  // ==========================================================================
  // ADMIN DASHBOARD
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      getAdminDashboard() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/api/admin/dashboard',
      ),
      headers: _authHeaders,
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid dashboard response.',
      );
    }

    if (response.statusCode != 200) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to load admin dashboard.',
      );
    }

    if (decoded is! Map) {

      throw Exception(
        'Invalid dashboard response.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  // ==========================================================================
  // ADMIN REQUESTS
  // ==========================================================================

  static Future<
          List<Map<String, dynamic>>>
      getAdminRequests() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/api/admin/requests',
      ),
      headers: _authHeaders,
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid admin request response.',
      );
    }

    if (response.statusCode != 200) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to load admin requests.',
      );
    }

    if (decoded is! List) {

      throw Exception(
        'Invalid admin request response.',
      );
    }

    return decoded
        .map<
            Map<String, dynamic>>(
          (item) =>
              Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // ==========================================================================
  // ADMIN UPDATE REQUEST STATUS
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      updateAdminRequestStatus({
    required int requestId,
    required String status,
  }) async {

    final response =
        await http.patch(
      Uri.parse(
        '$baseUrl/api/admin/requests/'
        '$requestId/status'
        '?status=$status',
      ),
      headers: _authHeaders,
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid response from server.',
      );
    }

    if (response.statusCode != 200) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to update request status.',
      );
    }

    if (decoded is! Map) {

      throw Exception(
        'Invalid status update response.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  // ==========================================================================
  // ADMIN RESOURCES
  // ==========================================================================

  static Future<
          List<Map<String, dynamic>>>
      getAdminResources() async {

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/api/resources',
      ),
      headers: _authHeaders,
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Failed to load resources: '
        '${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! List) {

      throw Exception(
        'Invalid resource response from server.',
      );
    }

    return decoded
        .map<
            Map<String, dynamic>>(
          (item) =>
              Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // ==========================================================================
  // CREATE RESOURCE
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      createResource({
    required String name,
    required String category,
    required String department,
    required String location,
    required String description,
    required int quantity,
    required int availableQuantity,
  }) async {

    final response =
        await http.post(
      Uri.parse(
        '$baseUrl/api/resources',
      ),
      headers: {
        ..._authHeaders,

        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'name':
            name,

        'category':
            category,

        'department':
            department,

        'location':
            location,

        'description':
            description,

        'quantity':
            quantity,

        'available_quantity':
            availableQuantity,

        'utilization':
            0,

        'status':
            availableQuantity > 0
                ? 'Available'
                : 'Unavailable',
      }),
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid response from server.',
      );
    }

    if (response.statusCode != 201) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to create resource.',
      );
    }

    return Map<String, dynamic>.from(
      decoded as Map,
    );
  }

  // ==========================================================================
  // UPDATE RESOURCE
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      updateResource({
    required int resourceId,
    required String name,
    required String category,
    required String department,
    required String location,
    required String description,
    required int quantity,
    required int availableQuantity,
  }) async {

    final response =
        await http.put(
      Uri.parse(
        '$baseUrl/api/resources/$resourceId',
      ),
      headers: {
        ..._authHeaders,

        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'name':
            name,

        'category':
            category,

        'department':
            department,

        'location':
            location,

        'description':
            description,

        'quantity':
            quantity,

        'available_quantity':
            availableQuantity,
      }),
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid response from server.',
      );
    }

    if (response.statusCode != 200) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to update resource.',
      );
    }

    return Map<String, dynamic>.from(
      decoded as Map,
    );
  }

  // ==========================================================================
  // DELETE RESOURCE
  // ==========================================================================

  static Future<void>
      deleteResource(
    int resourceId,
  ) async {

    final response =
        await http.delete(
      Uri.parse(
        '$baseUrl/api/resources/$resourceId',
      ),
      headers: _authHeaders,
    );

    if (response.statusCode != 200) {

      dynamic decoded;

      try {
        decoded =
            jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to delete resource.',
      );
    }
  }

  // ==========================================================================
  // SMART INVENTORY - RECONCILE PDF
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      reconcileInventoryPdf(
    File pdfFile,
  ) async {

    if (!isLoggedIn) {
      throw Exception(
        'You are not authenticated.',
      );
    }

    final request =
        http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/api/admin/inventory/reconcile',
      ),
    );

    request.headers.addAll(
      _authHeaders,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        pdfFile.path,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid inventory response from server.',
      );
    }

    if (response.statusCode != 200) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to analyze inventory PDF.',
      );
    }

    if (decoded is! Map) {

      throw Exception(
        'Invalid inventory reconciliation response.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  // ==========================================================================
  // SMART INVENTORY - APPLY APPROVED CHANGES
  // ==========================================================================

  static Future<
          Map<String, dynamic>>
      applyInventoryChanges(
    List<Map<String, dynamic>>
        items,
  ) async {

    final response =
        await http.post(
      Uri.parse(
        '$baseUrl/api/admin/inventory/apply',
      ),
      headers: {
        ..._authHeaders,

        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'items': items,
      }),
    );

    dynamic decoded;

    try {
      decoded =
          jsonDecode(response.body);
    } catch (_) {

      throw Exception(
        'Invalid inventory apply response.',
      );
    }

    if (response.statusCode != 200) {

      final message =
          decoded is Map
              ? decoded['detail']
                  ?.toString()
              : null;

      throw Exception(
        message ??
            'Failed to apply inventory changes.',
      );
    }

    if (decoded is! Map) {

      throw Exception(
        'Invalid inventory apply response.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }
}