import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/plant_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/plant_list_item.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/empty_state_widget.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlants();
    });
  }

  Future<void> _loadPlants() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      await context.read<PlantProvider>().loadPlants(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌱 Plant Care',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (authProvider.currentUser != null)
              Text(
                'Xin chào, ${authProvider.currentUser!.name}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thông báo đang phát triển')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlants,
        child: Consumer<PlantProvider>(
          builder: (context, plantProvider, _) {
            if (plantProvider.isLoading && plantProvider.plants.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (plantProvider.plants.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.eco,
                title: 'Chưa có cây nào',
                message: 'Hãy thêm cây đầu tiên của bạn\nvào vườn nhỏ xinh này nhé!',
                buttonText: 'Thêm cây mới',
                onButtonPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addPlant);
                },
              );
            }

            return CustomScrollView(
              slivers: [
                // Dashboard Section
                SliverToBoxAdapter(
                  child: _buildDashboardSection(plantProvider),
                ),

                // Quick Actions Section
                SliverToBoxAdapter(
                  child: _buildQuickActionsSection(),
                ),

                // Section Header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Icon(Icons.eco, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Cây của bạn',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Plant List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final plant = plantProvider.plants[index];
                        return PlantListItem(
                          plant: plant,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.plantDetailIot,
                              arguments: plant.id,
                            );
                          },
                          onEdit: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.editPlant,
                              arguments: plant.id,
                            );
                          },
                          onDelete: () => _confirmDeletePlant(plant.id),
                        );
                      },
                      childCount: plantProvider.plants.length,
                    ),
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addPlant);
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm cây'),
      ),
    );
  }

  Widget _buildDashboardSection(PlantProvider plantProvider) {
    final totalPlants = plantProvider.plants.length;
    final avgAge = plantProvider.plants.isEmpty
        ? 0
        : (plantProvider.plants.fold<int>(0, (sum, p) => sum + p.ageInDays) /
                plantProvider.plants.length)
            .round();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              DashboardCard(
                title: 'Tổng số cây',
                value: totalPlants.toString(),
                icon: Icons.eco,
                color: Colors.green,
                onTap: () {
                  // Scroll to plant list
                },
              ),
              DashboardCard(
                title: 'Tuổi trung bình',
                value: '$avgAge ngày',
                icon: Icons.calendar_today,
                color: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.statistics);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thao tác nhanh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  label: 'Nhật ký',
                  icon: Icons.book,
                  color: Colors.orange,
                  onTap: () {
                    if (context.read<PlantProvider>().plants.isNotEmpty) {
                      final firstPlant = context.read<PlantProvider>().plants.first;
                      Navigator.pushNamed(
                        context,
                        AppRoutes.diaryList,
                        arguments: firstPlant.id,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hãy thêm cây trước!')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  label: 'Thư viện',
                  icon: Icons.photo_library,
                  color: Colors.purple,
                  onTap: () {
                    if (context.read<PlantProvider>().plants.isNotEmpty) {
                      final firstPlant = context.read<PlantProvider>().plants.first;
                      Navigator.pushNamed(
                        context,
                        AppRoutes.gallery,
                        arguments: firstPlant.id,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hãy thêm cây trước!')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  label: 'Thống kê',
                  icon: Icons.bar_chart,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.statistics);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  label: 'IoT',
                  icon: Icons.sensors,
                  color: Colors.green,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.iotHome);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePlant(String plantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa cây này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id ?? '';
      final success = await context.read<PlantProvider>().deletePlant(plantId);      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã xóa cây' : 'Lỗi khi xóa cây'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
