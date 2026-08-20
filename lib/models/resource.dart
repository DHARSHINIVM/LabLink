class Resource {
  final int id;
  final String name;
  final String category;
  final String department;
  final String location;
  final String description;
  final int quantity;
  final int availableQuantity;
  final double utilization;
  final String status;
  final DateTime? createdAt;

  const Resource({
    required this.id,
    required this.name,
    required this.category,
    required this.department,
    required this.location,
    required this.description,
    required this.quantity,
    required this.availableQuantity,
    required this.utilization,
    required this.status,
    this.createdAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      department: json['department'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      availableQuantity: json['available_quantity'] as int,
      utilization: (json['utilization'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  bool get isAvailable => availableQuantity > 0;

  bool get isLimited => status.toLowerCase() == 'limited';
}