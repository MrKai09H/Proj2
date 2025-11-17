class PlantModel {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? description;
  final DateTime plantedDate;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.description,
    required this.plantedDate,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'species': species,
      'description': description,
      'plantedDate': plantedDate.toIso8601String(),
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      description: map['description'],
      plantedDate: DateTime.parse(map['plantedDate']),
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // CopyWith method
  PlantModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? description,
    DateTime? plantedDate,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      description: description ?? this.description,
      plantedDate: plantedDate ?? this.plantedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate plant age in days
  int get ageInDays {
    return DateTime.now().difference(plantedDate).inDays;
  }
}

