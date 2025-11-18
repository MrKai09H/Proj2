import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';

/// Settings Screen - Assigned to: Hoàng Chí Bằng
/// Task 1.6: Trang Cài đặt
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          // User profile section
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              final bool hasValidName =
                  user?.name != null && user!.name.isNotEmpty;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    hasValidName ? user.name![0].toUpperCase() : 'U',
                  ),
                ),
                title: Text(user?.name ?? 'User'),
                subtitle: Text(user?.email ?? ''),
              );
            },
          ),
          const Divider(),

          // --- ĐÃ XÓA MỤC THÔNG BÁO ---

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Ngôn ngữ'),
            subtitle: const Text('Tiếng Việt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to language settings
            },
          ),

          // Theme
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Giao diện'),
            subtitle: const Text('Sáng / Tối / Tự động'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to theme settings
            },
          ),

          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Về ứng dụng'),
            subtitle: const Text('Phiên bản 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Plant Care App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Nhóm 6',
                children: [
                  const SizedBox(height: 16),
                  const Text('Ứng dụng quản lý chăm sóc cây cảnh'),
                ],
              );
            },
          ),

          // Help
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Trợ giúp'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthProvider>().signOut();
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      },
                      child: const Text('Đăng xuất',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}