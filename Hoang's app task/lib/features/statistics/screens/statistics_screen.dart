// File: mobile_app/lib/features/statistics/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import '../services/statistics_service.dart';
import '../widgets/statistics_card.dart';
import '../widgets/care_history_chart.dart';
import '../widgets/activity_breakdown_chart.dart'; // Giả sử bạn có widget này

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  String _selectedPeriod = 'week';

  late Future<Map<String, int>> _summaryDataFuture;
  late Future<Map<String, double>> _activityBreakdownFuture;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  void _fetchStatistics() {
    setState(() {
      _summaryDataFuture = _statisticsService.getSummaryData(period: _selectedPeriod);
      _activityBreakdownFuture = _statisticsService.getActivityBreakdown(period: _selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thong ke (Tat ca cay)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 24),
            const Text(
              'Lich su cham soc (Tat ca cay)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CareHistoryChart(period: _selectedPeriod),
            const SizedBox(height: 24),
            const Text(
              'Phan loai hoat dong (Tat ca cay)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildActivityBreakdownSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Tuan'),
          selected: _selectedPeriod == 'week',
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPeriod = 'week');
              _fetchStatistics();
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Thang'),
          selected: _selectedPeriod == 'month',
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPeriod = 'month');
              _fetchStatistics();
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Nam'),
          selected: _selectedPeriod == 'year',
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPeriod = 'year');
              _fetchStatistics();
            }
          },
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<Map<String, int>>(
      future: _summaryDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Loi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Row(children: const [
            StatisticsCard(title: 'Lan tuoi nuoc', value: "0", icon: Icons.water_drop_outlined, color: Colors.blue),
            SizedBox(width: 12),
            StatisticsCard(title: 'Nhat ky', value: "0", icon: Icons.book_outlined, color: Colors.green),
          ]);
        }

        final summaryData = snapshot.data!;
        final wateringCount = summaryData['wateringCount'] ?? 0;
        final diaryCount = summaryData['diaryCount'] ?? 0;

        return Row(children: [
          StatisticsCard(title: 'Lan tuoi nuoc', value: wateringCount.toString(), icon: Icons.water_drop_outlined, color: Colors.blue),
          const SizedBox(width: 12),
          StatisticsCard(title: 'Nhat ky', value: diaryCount.toString(), icon: Icons.book_outlined, color: Colors.green),
        ]);
      },
    );
  }

  Widget _buildActivityBreakdownSection() {
    return FutureBuilder<Map<String, double>>(
        future: _activityBreakdownFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Card(
                child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
          }
          if (snapshot.hasError) {
            return Card(child: Center(child: Text('Loi: ${snapshot.error}')));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Card(child: SizedBox(height: 200, child: Center(child: Text('Khong co du lieu.'))));
          }

          // Giả sử bạn có widget ActivityBreakdownChart để vẽ biểu đồ tròn
          return ActivityBreakdownChart(data: snapshot.data!);
        });
  }
}