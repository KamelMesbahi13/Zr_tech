import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../services/order_service.dart';
import '../services/category_service.dart';
import '../models/order_model.dart';

class AdminStatisticsView extends StatefulWidget {
  const AdminStatisticsView({super.key});

  @override
  State<AdminStatisticsView> createState() => _AdminStatisticsViewState();
}

class _AdminStatisticsViewState extends State<AdminStatisticsView>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final CategoryService _categoryService = CategoryService();

  List<OrderModel> _allOrders = [];
  Map<String, String> _categoryNameMap = {}; // categoryId -> name
  bool _isLoading = true;

  late TabController _periodTabController;

  // 0=Today, 1=This Week, 2=This Month, 3=This Year
  int _selectedPeriod = 0;

  @override
  void initState() {
    super.initState();
    _periodTabController = TabController(length: 4, vsync: this);
    _periodTabController.addListener(() {
      if (!_periodTabController.indexIsChanging) {
        setState(() => _selectedPeriod = _periodTabController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _periodTabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders =
          await _orderService.getAllOrders().timeout(const Duration(seconds: 15));
      // Build category name map from both shopping types
      final grosCategories = await _categoryService
          .getCategories('gros')
          .timeout(const Duration(seconds: 10));
      final detailCategories = await _categoryService
          .getCategories('detail')
          .timeout(const Duration(seconds: 10));

      final catMap = <String, String>{};
      for (final c in grosCategories) {
        catMap[c.id] = c.name;
      }
      for (final c in detailCategories) {
        catMap[c.id] = c.name;
      }

      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _categoryNameMap = catMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ─── TIME FILTERING ─────────────────────────────────────────

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // Today
        return DateTime(now.year, now.month, now.day);
      case 1: // This Week (Saturday start for Arabic)
        final weekday = now.weekday; // Mon=1 .. Sun=7
        final daysSinceSat = (weekday + 1) % 7; // Sat=0
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysSinceSat));
      case 2: // This Month
        return DateTime(now.year, now.month, 1);
      case 3: // This Year
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  List<OrderModel> get _filteredOrders {
    final startMs = _periodStart.millisecondsSinceEpoch;
    return _allOrders.where((o) => o.createdAt >= startMs).toList();
  }

  // ─── KPI COMPUTATIONS ───────────────────────────────────────

  int _countByStatus(String status) =>
      _filteredOrders.where((o) => o.status == status).length;

  /// Confirmed total: counts all orders that passed through confirmation
  /// (i.e. everything except pending and cancelled).
  int get _confirmedTotal => _filteredOrders
      .where((o) => o.status != 'pending' && o.status != 'cancelled')
      .length;

  double get _totalRevenue => _filteredOrders
      .where((o) => o.status == 'delivered')
      .fold(0.0, (sum, o) => sum + o.totalPrice);

  // ─── CHART DATA HELPERS ─────────────────────────────────────

  /// Returns time buckets as (label, start, end) tuples
  List<_TimeBucket> get _timeBuckets {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // Today — single bucket
        final start = DateTime(now.year, now.month, now.day);
        return [_TimeBucket('اليوم', start, now)];
      case 1: // This week — 7 days
        final labels = ['سبت', 'أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع'];
        final weekStart = _periodStart;
        return List.generate(7, (i) {
          final dayStart = weekStart.add(Duration(days: i));
          final dayEnd = dayStart.add(const Duration(days: 1));
          return _TimeBucket(labels[i], dayStart, dayEnd);
        });
      case 2: // This month — weeks
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        final buckets = <_TimeBucket>[];
        var weekStart = monthStart;
        int weekNum = 1;
        while (weekStart.isBefore(monthEnd)) {
          final weekEnd = weekStart.add(const Duration(days: 7));
          final end = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;
          buckets.add(_TimeBucket('أ$weekNum', weekStart, end));
          weekStart = weekEnd;
          weekNum++;
        }
        return buckets;
      case 3: // This year — months
        final monthLabels = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
        ];
        return List.generate(12, (i) {
          final start = DateTime(now.year, i + 1, 1);
          final end = DateTime(now.year, i + 2, 1);
          return _TimeBucket(monthLabels[i], start, end);
        });
      default:
        return [];
    }
  }

  Map<String, List<int>> _ordersByStatusPerBucket() {
    final statuses = ['confirmed', 'delivered', 'returned', 'rejected'];
    final buckets = _timeBuckets;
    final result = <String, List<int>>{};
    for (final s in statuses) {
      result[s] = List.filled(buckets.length, 0);
    }
    for (final order in _filteredOrders) {
      final orderTime =
          DateTime.fromMillisecondsSinceEpoch(order.createdAt);
      for (int i = 0; i < buckets.length; i++) {
        if (!orderTime.isBefore(buckets[i].start) &&
            orderTime.isBefore(buckets[i].end)) {
          if (result.containsKey(order.status)) {
            result[order.status]![i]++;
          }
          break;
        }
      }
    }
    return result;
  }

  List<double> _revenuePerBucket() {
    final buckets = _timeBuckets;
    final revenues = List<double>.filled(buckets.length, 0);
    for (final order in _filteredOrders) {
      if (order.status != 'delivered') continue;
      final orderTime =
          DateTime.fromMillisecondsSinceEpoch(order.createdAt);
      for (int i = 0; i < buckets.length; i++) {
        if (!orderTime.isBefore(buckets[i].start) &&
            orderTime.isBefore(buckets[i].end)) {
          revenues[i] += order.totalPrice;
          break;
        }
      }
    }
    return revenues;
  }

  List<MapEntry<String, int>> _topProducts() {
    final map = <String, int>{};
    for (final o in _filteredOrders) {
      map[o.productName] = (map[o.productName] ?? 0) + o.quantity;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<MapEntry<String, int>> _topCategories() {
    final map = <String, int>{};
    for (final o in _filteredOrders) {
      final catName = _categoryNameMap[o.categoryId] ?? o.categoryId;
      map[catName] = (map[catName] ?? 0) + o.quantity;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  // ─── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // Period tab bar
          _buildPeriodTabBar(),
          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding,
                  vertical: Responsive.sp(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KPI Cards
                    _buildKpiCards(),
                    SizedBox(height: Responsive.sp(24)),
                    // Orders by Status chart
                    _buildChartCard(
                      title: 'الطلبات حسب الحالة',
                      icon: Icons.bar_chart,
                      child: _buildOrdersByStatusChart(),
                    ),
                    SizedBox(height: Responsive.sp(16)),
                    // Revenue over time
                    _buildChartCard(
                      title: 'الإيرادات عبر الزمن',
                      icon: Icons.trending_up,
                      child: _buildRevenueChart(),
                    ),
                    SizedBox(height: Responsive.sp(16)),
                    // Top products
                    _buildChartCard(
                      title: 'أكثر المنتجات مبيعاً',
                      icon: Icons.star,
                      child: _buildTopItemsChart(_topProducts()),
                    ),
                    SizedBox(height: Responsive.sp(16)),
                    // Top categories
                    _buildChartCard(
                      title: 'أكثر الفئات مبيعاً',
                      icon: Icons.category,
                      child: _buildTopItemsChart(_topCategories()),
                    ),
                    SizedBox(height: Responsive.sp(32)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PERIOD TAB BAR ─────────────────────────────────────────

  Widget _buildPeriodTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding,
        vertical: Responsive.sp(8),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: TabBar(
        controller: _periodTabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSlate400,
        labelStyle: TextStyle(
          fontSize: Responsive.fp(13),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: Responsive.fp(13),
          fontWeight: FontWeight.w500,
        ),
        dividerHeight: 0,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'اليوم'),
          Tab(text: 'الأسبوع'),
          Tab(text: 'الشهر'),
          Tab(text: 'السنة'),
        ],
      ),
    );
  }

  // ─── KPI CARDS ──────────────────────────────────────────────

  Widget _buildKpiCards() {
    return Wrap(
      spacing: Responsive.sp(12),
      runSpacing: Responsive.sp(12),
      children: [
        _buildKpiCard(
          icon: Icons.check_circle_outline,
          color: AppColors.primary,
          value: _confirmedTotal.toString(),
          label: 'طلبات مؤكدة',
        ),
        _buildKpiCard(
          icon: Icons.local_shipping_outlined,
          color: AppColors.success,
          value: _countByStatus('delivered').toString(),
          label: 'طلبات مسلّمة',
        ),
        _buildKpiCard(
          icon: Icons.replay_outlined,
          color: AppColors.warning,
          value: _countByStatus('returned').toString(),
          label: 'طلبات مرتجعة',
        ),
        _buildKpiCard(
          icon: Icons.payments_outlined,
          color: const Color(0xFF8B5CF6),
          value: '${_totalRevenue.toStringAsFixed(0)} د.ج',
          label: 'إجمالي الإيرادات',
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    final cardWidth = Responsive.isWide
        ? (Responsive.screenWidth - 240 - Responsive.horizontalPadding * 2 - 36) / 4
        : (Responsive.screenWidth - Responsive.horizontalPadding * 2 - 12) / 2;

    return Container(
      width: cardWidth.clamp(140.0, 320.0),
      padding: EdgeInsets.all(Responsive.sp(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: Responsive.sp(40),
            height: Responsive.sp(40),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: Responsive.sp(20)),
          ),
          SizedBox(height: Responsive.sp(12)),
          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: Responsive.fp(24),
                fontWeight: FontWeight.bold,
                fontFamily: 'Space Grotesk',
              ),
            ),
          ),
          SizedBox(height: Responsive.sp(4)),
          // Label
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: Responsive.fp(12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CHART CARD WRAPPER ─────────────────────────────────────

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.sp(20)),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: Responsive.sp(32),
                height: Responsive.sp(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: AppColors.primary, size: Responsive.sp(16)),
              ),
              SizedBox(width: Responsive.sp(10)),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.sp(20)),
          child,
        ],
      ),
    );
  }

  // ─── ORDERS BY STATUS BAR CHART ─────────────────────────────

  Widget _buildOrdersByStatusChart() {
    final buckets = _timeBuckets;
    final dataByStatus = _ordersByStatusPerBucket();

    if (buckets.isEmpty) {
      return _buildEmptyChartMessage();
    }

    final statusColors = {
      'confirmed': AppColors.primary,
      'delivered': AppColors.success,
      'returned': AppColors.warning,
      'rejected': AppColors.error,
    };

    final maxVal = dataByStatus.values
        .expand((list) => list)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('مؤكد', AppColors.primary),
            _buildLegendItem('مسلّم', AppColors.success),
            _buildLegendItem('مرتجع', AppColors.warning),
            _buildLegendItem('مرفوض', AppColors.error),
          ],
        ),
        SizedBox(height: Responsive.sp(16)),
        SizedBox(
          height: 220,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxVal + 2).toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceAlt,
                    tooltipRoundedRadius: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            buckets[idx].label,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: Responsive.fp(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxVal > 10 ? (maxVal / 5).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: Responsive.fp(10),
                            fontFamily: 'Space Grotesk',
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxVal > 10 ? (maxVal / 5).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(buckets.length, (i) {
                  final statuses = ['confirmed', 'delivered', 'returned', 'rejected'];
                  return BarChartGroupData(
                    x: i,
                    barRods: statuses.map((s) {
                      return BarChartRodData(
                        toY: (dataByStatus[s]?[i] ?? 0).toDouble(),
                        color: statusColors[s]!,
                        width: Responsive.isWide ? 8 : 5,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      );
                    }).toList(),
                    barsSpace: 2,
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── REVENUE LINE CHART ─────────────────────────────────────

  Widget _buildRevenueChart() {
    final buckets = _timeBuckets;
    final revenues = _revenuePerBucket();

    if (buckets.isEmpty) {
      return _buildEmptyChartMessage();
    }

    final maxRevenue =
        revenues.isEmpty ? 0.0 : revenues.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.surfaceAlt,
                tooltipRoundedRadius: 8,
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(0)} د.ج',
                      TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fp(12),
                        fontFamily: 'Space Grotesk',
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxRevenue > 0
                  ? (maxRevenue / 5).ceilToDouble().clamp(1, double.infinity)
                  : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.borderSubtle,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= buckets.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        buckets[idx].label,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: Responsive.fp(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: maxRevenue > 0
                      ? (maxRevenue / 5).ceilToDouble().clamp(1, double.infinity)
                      : 1,
                  getTitlesWidget: (value, meta) {
                    String text;
                    if (value >= 1000000) {
                      text = '${(value / 1000000).toStringAsFixed(1)}M';
                    } else if (value >= 1000) {
                      text = '${(value / 1000).toStringAsFixed(0)}K';
                    } else {
                      text = value.toInt().toString();
                    }
                    return Text(
                      text,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: Responsive.fp(10),
                        fontFamily: 'Space Grotesk',
                      ),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: maxRevenue > 0 ? maxRevenue * 1.15 : 10,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  buckets.length,
                  (i) => FlSpot(i.toDouble(), revenues[i]),
                ),
                isCurved: true,
                color: AppColors.success,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppColors.success,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withValues(alpha: 0.25),
                      AppColors.success.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TOP ITEMS HORIZONTAL BAR CHART ─────────────────────────

  Widget _buildTopItemsChart(List<MapEntry<String, int>> items) {
    if (items.isEmpty) {
      return _buildEmptyChartMessage();
    }

    final maxVal = items.first.value;

    return Column(
      children: items.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final fraction = maxVal > 0 ? item.value / maxVal : 0.0;

        // Gradient colors for ranking
        final colors = [
          AppColors.primary,
          const Color(0xFF8B5CF6),
          AppColors.success,
          AppColors.warning,
          const Color(0xFFEC4899),
        ];
        final color = colors[idx % colors.length];

        return Padding(
          padding: EdgeInsets.only(bottom: Responsive.sp(10)),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: Responsive.sp(28),
                height: Responsive.sp(28),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: Responsive.fp(12),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.sp(10)),
              // Name + bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.key,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: Responsive.fp(13),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.sp(4)),
                    // Bar
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 8,
                              width: constraints.maxWidth,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              height: 8,
                              width: constraints.maxWidth * fraction,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.sp(10)),
              // Value
              Text(
                item.value.toString(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.fp(13),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Space Grotesk',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── HELPER WIDGETS ─────────────────────────────────────────

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: Responsive.fp(11),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChartMessage() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined,
              color: AppColors.textHint, size: Responsive.sp(32)),
          SizedBox(height: Responsive.sp(8)),
          Text(
            'لا توجد بيانات في هذه الفترة',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: Responsive.fp(13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TIME BUCKET MODEL ──────────────────────────────────────

class _TimeBucket {
  final String label;
  final DateTime start;
  final DateTime end;
  const _TimeBucket(this.label, this.start, this.end);
}
