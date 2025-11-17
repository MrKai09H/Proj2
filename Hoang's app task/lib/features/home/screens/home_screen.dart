import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/plant_provider.dart';
import '../../../core/routes/app_routes.dart';

/// Home Screen - Assigned to: Hoàng Chí Bằng
/// Task 1.2: Trang chủ (Dashboard & Danh sách cây)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  void _loadPlants() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<PlantProvider>().loadPlants(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌱 Plant Care'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.statistics);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadPlants(),
        child: Consumer<PlantProvider>(
          builder: (context, plantProvider, _) {
            if (plantProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (plantProvider.plants.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco, size: 100, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có cây nào',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.addPlant);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm cây mới'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plantProvider.plants.length,
              itemBuilder: (context, index) {
                final plant = plantProvider.plants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: const Icon(Icons.eco, color: Colors.green),
                    ),
                    title: Text(plant.name),
                    subtitle: Text('${plant.species} • ${plant.ageInDays} ngày'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to plant detail with IoT
                      Navigator.pushNamed(
                        context,
                        AppRoutes.plantDetailIot,
                        arguments: plant.id,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addPlant);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

