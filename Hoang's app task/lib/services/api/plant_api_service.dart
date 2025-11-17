import '../../models/plant_model.dart';
import '../firebase/firestore_service.dart';
import '../../core/constants/app_constants.dart';

class PlantApiService {
  final FirestoreService _firestoreService = FirestoreService();

  // Add new plant
  Future<String?> addPlant(PlantModel plant) async {
    try {
      return await _firestoreService.addDocument(
        AppConstants.plantsCollection,
        plant.toMap(),
      );
    } catch (e) {
      print('Error adding plant: $e');
      return null;
    }
  }

  // Update plant
  Future<bool> updatePlant(String plantId, PlantModel plant) async {
    try {
      return await _firestoreService.updateDocument(
        AppConstants.plantsCollection,
        plantId,
        plant.toMap(),
      );
    } catch (e) {
      print('Error updating plant: $e');
      return false;
    }
  }

  // Delete plant
  Future<bool> deletePlant(String plantId) async {
    try {
      return await _firestoreService.deleteDocument(
        AppConstants.plantsCollection,
        plantId,
      );
    } catch (e) {
      print('Error deleting plant: $e');
      return false;
    }
  }

  // Get plant by ID
  Future<PlantModel?> getPlant(String plantId) async {
    try {
      var data = await _firestoreService.getDocument(
        AppConstants.plantsCollection,
        plantId,
      );
      if (data != null) {
        return PlantModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting plant: $e');
      return null;
    }
  }

  // Get all plants for a user
  Future<List<PlantModel>> getPlantsByUserId(String userId) async {
    try {
      var data = await _firestoreService.queryCollection(
        AppConstants.plantsCollection,
        'userId',
        userId,
      );
      return data.map((item) => PlantModel.fromMap(item)).toList();
    } catch (e) {
      print('Error getting plants: $e');
      return [];
    }
  }

  // Search plants by name
  Future<List<PlantModel>> searchPlants(String userId, String query) async {
    try {
      var plants = await getPlantsByUserId(userId);
      return plants
          .where((plant) =>
              plant.name.toLowerCase().contains(query.toLowerCase()) ||
              plant.species.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching plants: $e');
      return [];
    }
  }
}

