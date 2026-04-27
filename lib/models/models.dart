/// RescueNet — Data Models

class Disaster {
  final String id;
  final String userId;
  final String title;
  final String type; // earthquake, flood, fire, storm, landslide, other
  final String severity; // low, medium, high, critical
  final String description;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final String status; // reported, responding, resolved
  final String? photoUrl;
  final int affectedCount;
  final String? createdAt;

  Disaster({
    required this.id, required this.userId, required this.title,
    required this.type, required this.severity, required this.description,
    required this.locationName, this.latitude, this.longitude,
    this.status = 'reported', this.photoUrl, this.affectedCount = 0, this.createdAt,
  });

  factory Disaster.fromMap(Map<String, dynamic> m) => Disaster(
    id: m['\$id'] ?? m['id'] ?? '',
    userId: m['userId'] ?? '',
    title: m['title'] ?? '',
    type: m['type'] ?? 'other',
    severity: m['severity'] ?? 'medium',
    description: m['description'] ?? '',
    locationName: m['locationName'] ?? '',
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    status: m['status'] ?? 'reported',
    photoUrl: m['photoUrl'],
    affectedCount: m['affectedCount'] ?? 0,
    createdAt: m['\$createdAt'] ?? m['createdAt'],
  );

  Map<String, dynamic> toMap() => {
    'userId': userId, 'title': title, 'type': type, 'severity': severity,
    'description': description, 'locationName': locationName,
    'latitude': latitude, 'longitude': longitude, 'status': status,
    'photoUrl': photoUrl, 'affectedCount': affectedCount,
  };
}

class ResourceRequest {
  final String id;
  final String disasterId;
  final String userId;
  final String type; // food, water, medical, shelter, clothing, rescue
  final int quantity;
  final String status; // requested, approved, delivered
  final String? notes;
  final String? createdAt;

  ResourceRequest({
    required this.id, required this.disasterId, required this.userId,
    required this.type, this.quantity = 1, this.status = 'requested',
    this.notes, this.createdAt,
  });

  factory ResourceRequest.fromMap(Map<String, dynamic> m) => ResourceRequest(
    id: m['\$id'] ?? m['id'] ?? '',
    disasterId: m['disasterId'] ?? '',
    userId: m['userId'] ?? '',
    type: m['type'] ?? 'other',
    quantity: m['quantity'] ?? 1,
    status: m['status'] ?? 'requested',
    notes: m['notes'],
    createdAt: m['\$createdAt'] ?? m['createdAt'],
  );

  Map<String, dynamic> toMap() => {
    'disasterId': disasterId, 'userId': userId, 'type': type,
    'quantity': quantity, 'status': status, 'notes': notes,
  };
}

class Volunteer {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String skills;
  final bool isAvailable;
  final String? assignedDisasterId;
  final String? createdAt;

  Volunteer({
    required this.id, required this.userId, required this.fullName,
    required this.phone, required this.skills,
    this.isAvailable = true, this.assignedDisasterId, this.createdAt,
  });

  factory Volunteer.fromMap(Map<String, dynamic> m) => Volunteer(
    id: m['\$id'] ?? m['id'] ?? '',
    userId: m['userId'] ?? '',
    fullName: m['fullName'] ?? '',
    phone: m['phone'] ?? '',
    skills: m['skills'] ?? '',
    isAvailable: m['isAvailable'] ?? true,
    assignedDisasterId: m['assignedDisasterId'],
    createdAt: m['\$createdAt'] ?? m['createdAt'],
  );

  Map<String, dynamic> toMap() => {
    'userId': userId, 'fullName': fullName, 'phone': phone,
    'skills': skills, 'isAvailable': isAvailable,
    'assignedDisasterId': assignedDisasterId,
  };
}
