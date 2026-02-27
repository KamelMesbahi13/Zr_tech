import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../services/auth_service.dart';
import '../services/ledger_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/ledger_transaction_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AdminLedgerView extends StatefulWidget {
  const AdminLedgerView({super.key});

  @override
  State<AdminLedgerView> createState() => _AdminLedgerViewState();
}

class _AdminLedgerViewState extends State<AdminLedgerView> {
  final LedgerService _ledgerService = LedgerService();
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Cache balances per user
  final Map<String, double> _userBalances = {};
  final Map<String, bool> _loadingBalances = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await AuthService().fetchAllUsers().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      // Filter: only approved users (gros users are those who have an account)
      final grosUsers = users.where((u) => u['status'] == 'approved').toList();
      setState(() {
        _allUsers = grosUsers;
        _isLoading = false;
      });
      // Load balances for all users
      for (final user in grosUsers) {
        _loadUserBalance(user['uid'] ?? '');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('حدث خطأ أثناء تحميل المستخدمين');
    }
  }

  Future<void> _loadUserBalance(String userId) async {
    if (userId.isEmpty) return;
    setState(() => _loadingBalances[userId] = true);
    try {
      final txs = await _ledgerService.getTransactions(userId);
      double balance = 0;
      for (final tx in txs) {
        if (tx.type == 'credit') {
          balance += tx.amount;
        } else {
          balance -= tx.amount;
        }
      }
      if (!mounted) return;
      setState(() {
        _userBalances[userId] = balance;
        _loadingBalances[userId] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingBalances[userId] = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    final q = _searchQuery.toLowerCase();
    return _allUsers.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final store = (u['storeName'] ?? '').toString().toLowerCase();
      return name.contains(q) || store.contains(q);
    }).toList();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Column(
      children: [
        // ── Search bar + refresh ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو المتجر...',
                      hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _loadUsers,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredUsers.length}',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Space Grotesk',
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── User list ──
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, color: AppColors.textMuted, size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'لا يوجد زبائن',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserLedgerCard(_filteredUsers[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  USER LEDGER CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUserLedgerCard(Map<String, dynamic> user) {
    final uid = user['uid'] ?? '';
    final name = user['name'] ?? 'بدون اسم';
    final storeName = user['storeName'] ?? '';
    final balance = _userBalances[uid];
    final isLoadingBalance = _loadingBalances[uid] ?? true;

    Color balanceColor;
    String balanceText;
    IconData balanceIcon;

    if (balance == null || isLoadingBalance) {
      balanceColor = AppColors.textMuted;
      balanceText = '...';
      balanceIcon = Icons.hourglass_empty;
    } else if (balance > 0) {
      // Positive = purchases > payments = user still owes
      balanceColor = AppColors.error;
      balanceText = '${balance.toStringAsFixed(2)} د.ج';
      balanceIcon = Icons.warning_amber_rounded;
    } else if (balance < 0) {
      // Negative = payments > purchases = overpaid
      balanceColor = AppColors.success;
      balanceText = '${balance.abs().toStringAsFixed(2)} د.ج';
      balanceIcon = Icons.check_circle;
    } else {
      balanceColor = AppColors.textMuted;
      balanceText = '0.00 د.ج';
      balanceIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openUserLedger(user),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Action button
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chevron_left, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبلغ المتبقي',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: Responsive.fp(11),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(balanceIcon, color: balanceColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          balanceText,
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: Responsive.fp(15),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // User info (right aligned for RTL)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: Responsive.fp(15),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (storeName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                storeName,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: Responsive.fp(13),
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.store, color: AppColors.textMuted, size: Responsive.sp(14)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primaryLight.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: Responsive.fp(18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  USER LEDGER DIALOG (FULL-SCREEN)
  // ═══════════════════════════════════════════════════════════════

  void _openUserLedger(Map<String, dynamic> user) {
    final uid = user['uid'] ?? '';
    final name = user['name'] ?? 'بدون اسم';
    final storeName = user['storeName'] ?? '';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ledger',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, anim2) {
        return _UserLedgerDialog(
          userId: uid,
          userName: name,
          storeName: storeName,
          user: user,
          ledgerService: _ledgerService,
          onBalanceChanged: () => _loadUserBalance(uid),
        );
      },
      transitionBuilder: (ctx, anim, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  USER LEDGER DIALOG
// ═══════════════════════════════════════════════════════════════════

class _UserLedgerDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final String storeName;
  final Map<String, dynamic> user;
  final LedgerService ledgerService;
  final VoidCallback onBalanceChanged;

  const _UserLedgerDialog({
    required this.userId,
    required this.userName,
    required this.storeName,
    required this.user,
    required this.ledgerService,
    required this.onBalanceChanged,
  });

  @override
  State<_UserLedgerDialog> createState() => _UserLedgerDialogState();
}

class _UserLedgerDialogState extends State<_UserLedgerDialog> {
  List<LedgerTransaction> _transactions = [];
  List<OrderModel> _userOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final txsFuture = widget.ledgerService.getTransactions(widget.userId);
      final ordersFuture = OrderService().getAllOrders();
      final results = await Future.wait([txsFuture, ordersFuture]).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final userPhone = (widget.user['phone'] ?? '').toString().trim();
      final allOrders = results[1] as List<OrderModel>;
      // Match orders to user by phone
      final matched = userPhone.isNotEmpty
          ? allOrders.where((o) => o.phone.trim() == userPhone && o.shoppingType == 'gros').toList()
          : <OrderModel>[];
      setState(() {
        _transactions = results[0] as List<LedgerTransaction>;
        _userOrders = matched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final txs = await widget.ledgerService.getTransactions(widget.userId);
      if (!mounted) return;
      setState(() => _transactions = txs);
    } catch (_) {}
  }

  // Totals from manual transactions
  double get _totalManualCredit => _transactions
      .where((t) => t.type == 'credit')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalDebit => _transactions
      .where((t) => t.type == 'debit')
      .fold(0.0, (sum, t) => sum + t.amount);

  // Total from auto orders
  double get _totalOrdersCredit => _userOrders
      .fold(0.0, (sum, o) => sum + o.totalPrice);

  double get _totalCredit => _totalManualCredit + _totalOrdersCredit;

  double get _balance => _totalCredit - _totalDebit;

  Future<void> _deleteTransaction(LedgerTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف المعاملة', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل أنت متأكد من حذف هذه المعاملة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await widget.ledgerService.deleteTransaction(widget.userId, tx.id);
      widget.onBalanceChanged();
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isWide = Responsive.screenWidth >= Breakpoints.tablet;
    final dialogWidth = isWide ? 700.0 : Responsive.screenWidth * 0.95;
    final dialogHeight = Responsive.screenHeight * 0.88;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── HEADER ──
                _buildDialogHeader(),

                // ── BALANCE SUMMARY ──
                _buildBalanceSummary(),

                // ── TRANSACTIONS LIST ──
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : (_transactions.isEmpty && _userOrders.isEmpty)
                          ? _buildEmptyState()
                          : _buildCombinedList(),
                ),

                // ── BOTTOM ACTIONS ──
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.userName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.storeName.isNotEmpty)
                Text(
                  widget.storeName,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: Responsive.fp(13),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primaryLight.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: Responsive.fp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              label: 'إجمالي المشتريات',
              value: _totalCredit.toStringAsFixed(2),
              color: AppColors.primary,
              icon: Icons.shopping_cart,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildSummaryItem(
              label: 'إجمالي المدفوع',
              value: _totalDebit.toStringAsFixed(2),
              color: AppColors.success,
              icon: Icons.payments,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildSummaryItem(
              label: 'المبلغ المتبقي',
              value: _balance.abs().toStringAsFixed(2),
              color: _balance > 0 ? AppColors.error : _balance < 0 ? AppColors.success : AppColors.textMuted,
              icon: _balance > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: Responsive.fp(16),
                fontWeight: FontWeight.bold,
                fontFamily: 'Space Grotesk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 56),
          const SizedBox(height: 16),
          const Text(
            'لا توجد معاملات بعد',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف أول معاملة لهذا الزبون',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedList() {
    // Calculate running balances for manual transactions
    final sortedAsc = List<LedgerTransaction>.from(_transactions)
      ..sort((a, b) => a.date.compareTo(b.date));
    final Map<String, double> runningBalances = {};
    double running = _totalOrdersCredit; // Start from orders total
    for (final tx in sortedAsc) {
      if (tx.type == 'credit') {
        running += tx.amount;
      } else {
        running -= tx.amount;
      }
      runningBalances[tx.id] = running;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // ── AUTO ORDERS SECTION ──
        if (_userOrders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'طلبات من الموقع (${_userOrders.length})',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final order in _userOrders) _buildOrderCard(order),
          if (_transactions.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.border),
            ),
        ],

        // ── MANUAL TRANSACTIONS SECTION ──
        if (_transactions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_note, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'معاملات يدوية (${_transactions.length})',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final tx in _transactions)
            _buildTransactionItem(tx, runningBalances[tx.id] ?? 0),
        ],
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateStr = order.createdAt > 0
        ? () {
            final d = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
            return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
          }()
        : '-';
    final statusLabels = {
      'pending': 'قيد الانتظار',
      'confirmed': 'مؤكد',
      'delivered': 'تم التوصيل',
      'cancelled': 'ملغى',
    };
    final statusColors = {
      'pending': Colors.orange,
      'confirmed': AppColors.primary,
      'delivered': AppColors.success,
      'cancelled': AppColors.error,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned(top: 0, bottom: 0, right: 0, width: 4, child: Container(color: AppColors.primary)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
              child: Row(
                children: [
                  // Total price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.totalPrice.toStringAsFixed(2)} د.ج',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: Responsive.fp(14),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (statusColors[order.status] ?? Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabels[order.status] ?? order.status,
                          style: TextStyle(
                            color: statusColors[order.status] ?? Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Product info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.productName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: Responsive.fp(13),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الكمية: ${order.quantity} × ${order.productPrice.toStringAsFixed(0)} د.ج  •  $dateStr',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: Responsive.fp(11),
                            fontFamily: 'Space Grotesk',
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag, color: AppColors.primary, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTransactionItem(LedgerTransaction tx, double runningBalance) {
    final isCredit = tx.type == 'credit';
    final typeColor = isCredit ? AppColors.primary : AppColors.success;
    final typeLabel = isCredit ? 'شراء' : 'دفع';
    final typeIcon = isCredit ? Icons.shopping_cart : Icons.payments;
    final dateStr = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year} ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}:${tx.date.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Colored side accent
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 4,
              child: Container(color: typeColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
              child: Row(
                children: [
                  // Delete button
                  InkWell(
                    onTap: () => _deleteTransaction(tx),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Running balance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المتبقي',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: Responsive.fp(10),
                        ),
                      ),
                      Text(
                        runningBalance.toStringAsFixed(2),
                        style: TextStyle(
                          color: runningBalance > 0 ? AppColors.error : AppColors.success,
                          fontSize: Responsive.fp(12),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Amount + type badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tx.amount.toStringAsFixed(2)} د.ج',
                        style: TextStyle(
                          color: typeColor,
                          fontSize: Responsive.fp(15),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Space Grotesk',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, color: typeColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Date + note
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.fp(13),
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                        if (tx.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            tx.note,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: Responsive.fp(12),
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Invoice button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showInvoiceDialog(),
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text('كشف حساب', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add purchase (product picker)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddPurchaseDialog(),
              icon: const Icon(Icons.shopping_cart, size: 16, color: Colors.white),
              label: const Text('إضافة شراء', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add payment
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddPaymentDialog(),
              icon: const Icon(Icons.payments, size: 16, color: Colors.white),
              label: const Text('إضافة دفع', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADD PURCHASE — PRODUCT PICKER
  // ═══════════════════════════════════════════════════════════════

  void _showAddPurchaseDialog() {
    List<CategoryModel> categories = [];
    List<ProductModel> allProducts = [];
    bool isLoading = true;
    String? selectedCategoryId;
    String productSearch = '';
    final Map<String, int> cart = {};
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Load categories + products on first build
            if (isLoading && categories.isEmpty) {
              Future.wait([
                CategoryService().getCategories('gros'),
                ProductService().getAllProducts('gros'),
              ]).then((results) {
                setSheetState(() {
                  categories = results[0] as List<CategoryModel>;
                  allProducts = results[1] as List<ProductModel>;
                  isLoading = false;
                });
              }).catchError((_) {
                setSheetState(() => isLoading = false);
              });
            }

            // Filter products by selected category + search
            final categoryProducts = selectedCategoryId != null
                ? allProducts.where((p) => p.categoryId == selectedCategoryId).toList()
                : <ProductModel>[];
            final filtered = productSearch.isEmpty
                ? categoryProducts
                : categoryProducts.where((p) => p.name.toLowerCase().contains(productSearch.toLowerCase())).toList();

            // Calculate total from cart
            double total = 0;
            cart.forEach((pid, qty) {
              final p = allProducts.where((p) => p.id == pid).firstOrNull;
              if (p != null) total += p.price * qty;
            });

            // Count items in cart for current category
            int cartCount = 0;
            cart.forEach((pid, qty) { if (qty > 0) cartCount += qty; });

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle + Title + Back button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        children: [
                          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
                          Row(
                            children: [
                              if (selectedCategoryId != null)
                                IconButton(
                                  onPressed: () => setSheetState(() { selectedCategoryId = null; productSearch = ''; }),
                                  icon: const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
                                  tooltip: 'رجوع للأقسام',
                                ),
                              Expanded(
                                child: Text(
                                  selectedCategoryId != null
                                      ? (categories.where((c) => c.id == selectedCategoryId).firstOrNull?.name ?? 'المنتجات')
                                      : 'اختر القسم',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (selectedCategoryId != null)
                                const SizedBox(width: 48), // Balance the back button
                            ],
                          ),
                          // Search (only when viewing products)
                          if (selectedCategoryId != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                              child: TextField(
                                onChanged: (v) => setSheetState(() => productSearch = v),
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'بحث عن منتج...',
                                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Content: categories or products
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : selectedCategoryId == null
                              // ── CATEGORY LIST ──
                              ? ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: categories.length,
                                  itemBuilder: (_, i) {
                                    final cat = categories[i];
                                    // Count cart items in this category
                                    int catCartCount = 0;
                                    for (final p in allProducts.where((p) => p.categoryId == cat.id)) {
                                      catCartCount += cart[p.id] ?? 0;
                                    }
                                    return InkWell(
                                      onTap: () => setSheetState(() => selectedCategoryId = cat.id),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: catCartCount > 0 ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border.withValues(alpha: 0.5)),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                                        ),
                                        child: Row(
                                          children: [
                                            // Arrow
                                            const Icon(Icons.chevron_left, color: AppColors.textMuted, size: 22),
                                            const SizedBox(width: 8),
                                            // Cart badge
                                            if (catCartCount > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$catCartCount',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                                                ),
                                              ),
                                            const Spacer(),
                                            // Category name
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                cat.name,
                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Category icon
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.category, color: AppColors.primary, size: 22),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              // ── PRODUCT LIST ──
                              : filtered.isEmpty
                                  ? const Center(child: Text('لا توجد منتجات في هذا القسم', style: TextStyle(color: AppColors.textMuted)))
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) {
                                        final p = filtered[i];
                                        final qty = cart[p.id] ?? 0;
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: qty > 0 ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: qty > 0 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _miniButton(Icons.remove, () {
                                                    if (qty > 0) {
                                                      setSheetState(() { if (qty == 1) { cart.remove(p.id); } else { cart[p.id] = qty - 1; } });
                                                    }
                                                  }, AppColors.error),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                    child: Text('$qty', style: const TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold, fontSize: 15)),
                                                  ),
                                                  _miniButton(Icons.add, () => setSheetState(() => cart[p.id] = qty + 1), AppColors.primary),
                                                ],
                                              ),
                                              const SizedBox(width: 12),
                                              if (qty > 0)
                                                Text('${(p.price * qty).toStringAsFixed(0)} د.ج', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                                              const Spacer(),
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                    Text('${p.price.toStringAsFixed(0)} د.ج', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Space Grotesk')),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                    ),

                    // Bottom: total + note + date + save
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('($cartCount منتج)  ', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                const Text('المجموع: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                Text('${total.toStringAsFixed(2)} د.ج', style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: noteController,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'ملاحظة (اختياري)', hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                                    filled: true, fillColor: AppColors.surfaceAlt,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (ctx2, child) => Theme(data: Theme.of(ctx2).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, surface: Colors.white)), child: child!),
                                  );
                                  if (picked != null) setSheetState(() => selectedDate = picked);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                  child: Row(children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text('${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, fontFamily: 'Space Grotesk', color: AppColors.textPrimary)),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (isSaving || cart.isEmpty) ? null : () async {
                                setSheetState(() => isSaving = true);
                                try {
                                  final items = <String>[];
                                  cart.forEach((pid, qty) {
                                    final p = allProducts.where((p) => p.id == pid).firstOrNull;
                                    if (p != null) items.add('${p.name} x$qty');
                                  });
                                  String note = items.join('، ');
                                  if (noteController.text.trim().isNotEmpty) note += ' | ${noteController.text.trim()}';
                                  final tx = LedgerTransaction(id: '', amount: total, type: 'credit', note: note, date: selectedDate);
                                  await widget.ledgerService.addTransaction(widget.userId, tx);
                                  widget.onBalanceChanged();
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  _loadTransactions();
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('خطأ: $e', textAlign: TextAlign.center),
                                      backgroundColor: Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                              child: isSaving
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('حفظ المشتريات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ADD PAYMENT — SIMPLE AMOUNT ENTRY
  // ═══════════════════════════════════════════════════════════════

  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
                      const Text('تسجيل دفعة', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('المبلغ الذي دفعه الزبون', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textDirection: TextDirection.ltr, textAlign: TextAlign.left,
                        style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Space Grotesk', fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'المبلغ (د.ج)', labelStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.textMuted),
                          filled: true, fillColor: AppColors.surfaceAlt,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'ملاحظة (اختياري)', labelStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.note_outlined, color: AppColors.textMuted),
                          filled: true, fillColor: AppColors.surfaceAlt,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, surface: Colors.white)), child: child!),
                          );
                          if (picked != null) setSheetState(() => selectedDate = picked);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 12),
                            Text('${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontFamily: 'Space Grotesk')),
                            const Spacer(),
                            const Text('التاريخ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            final amountStr = amountController.text.trim();
                            if (amountStr.isEmpty) return;
                            final amount = double.tryParse(amountStr);
                            if (amount == null || amount <= 0) return;
                            setSheetState(() => isSaving = true);
                            try {
                              final tx = LedgerTransaction(id: '', amount: amount, type: 'debit', note: noteController.text.trim(), date: selectedDate);
                              await widget.ledgerService.addTransaction(widget.userId, tx);
                              widget.onBalanceChanged();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _loadTransactions();
                            } catch (e) {
                              setSheetState(() => isSaving = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('خطأ: $e', textAlign: TextAlign.center),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                          child: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payments, color: Colors.white, size: 20), SizedBox(width: 8), Text('تسجيل الدفعة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ═══════════════════════════════════════════════════════════════
  //  PRINT-ONLY INVOICE (opens clean HTML in new window)
  // ═══════════════════════════════════════════════════════════════

  void _printInvoiceHtml(String dateStr, List<LedgerTransaction> sortedTxs, List<double> runningBalances) {
    // Build transaction rows HTML
    final rowsHtml = StringBuffer();
    for (int i = 0; i < sortedTxs.length; i++) {
      final tx = sortedTxs[i];
      final txDate = '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year} ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';
      final desc = tx.note.isEmpty ? '-' : tx.note;
      final credit = tx.type == 'credit' ? tx.amount.toStringAsFixed(2) : '-';
      final debit = tx.type == 'debit' ? tx.amount.toStringAsFixed(2) : '-';
      final bal = runningBalances[i].toStringAsFixed(2);
      final balColor = runningBalances[i] > 0 ? '#e53935' : '#43a047';
      rowsHtml.write('''
        <tr>
          <td style="font-family:monospace">$txDate</td>
          <td>$desc</td>
          <td style="color:#1976D2;font-weight:bold">$credit</td>
          <td style="color:#e53935;font-weight:bold">$debit</td>
          <td style="color:$balColor;font-weight:bold">$bal</td>
        </tr>
      ''');
    }

    final invoiceHtml = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <title>كشف حساب - ${widget.userName}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', Tahoma, Arial, sans-serif; padding: 40px; direction: rtl; color: #333; }
    h1 { text-align: center; font-size: 28px; margin-bottom: 4px; }
    .subtitle { text-align: center; color: #888; font-size: 13px; margin-bottom: 24px; font-family: monospace; }
    .info-section { margin-bottom: 20px; border-bottom: 1px solid #ddd; padding-bottom: 16px; }
    .info-row { display: flex; gap: 12px; margin-bottom: 6px; font-size: 14px; }
    .info-label { color: #666; font-weight: 600; min-width: 60px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 13px; }
    th { background: #f5f5f5; padding: 10px 8px; border: 1px solid #ddd; font-weight: bold; text-align: center; }
    td { padding: 8px; border: 1px solid #ddd; text-align: center; }
    .summary { display: flex; gap: 16px; justify-content: center; margin-top: 16px; }
    .summary-box { flex: 1; text-align: center; padding: 16px; border-radius: 10px; border: 1px solid #ddd; }
    .summary-box .value { font-size: 20px; font-weight: bold; font-family: monospace; }
    .summary-box .label { font-size: 12px; color: #666; margin-top: 4px; }
    @media print { body { padding: 20px; } }
  </style>
</head>
<body>
  <h1>كشف حساب</h1>
  <div class="subtitle">تاريخ الإصدار: $dateStr</div>
  <div class="info-section">
    <div class="info-row"><span class="info-label">الاسم:</span><span>${widget.userName}</span></div>
    ${widget.storeName.isNotEmpty ? '<div class="info-row"><span class="info-label">المتجر:</span><span>${widget.storeName}</span></div>' : ''}
    <div class="info-row"><span class="info-label">الهاتف:</span><span>${widget.user['phone'] ?? ''}</span></div>
    <div class="info-row"><span class="info-label">الولاية:</span><span>${widget.user['wilaya'] ?? ''}</span></div>
  </div>
  <table>
    <thead>
      <tr><th>التاريخ</th><th>الوصف</th><th>مشتريات</th><th>مدفوع</th><th>الرصيد</th></tr>
    </thead>
    <tbody>
      $rowsHtml
    </tbody>
  </table>
  <div class="summary">
    <div class="summary-box" style="border-color:#1976D2"><div class="value" style="color:#1976D2">${_totalCredit.toStringAsFixed(2)}</div><div class="label">إجمالي المشتريات</div></div>
    <div class="summary-box" style="border-color:#43a047"><div class="value" style="color:#43a047">${_totalDebit.toStringAsFixed(2)}</div><div class="label">إجمالي المدفوع</div></div>
    <div class="summary-box" style="border-color:${_balance > 0 ? '#e53935' : '#43a047'}"><div class="value" style="color:${_balance > 0 ? '#e53935' : '#43a047'}">${_balance.abs().toStringAsFixed(2)}</div><div class="label">المبلغ المتبقي</div></div>
  </div>
  <script>window.onload = function() { window.print(); }</script>
</body>
</html>
    ''';

    // Create a Blob URL and open it in a new tab for printing
    final blob = html.Blob([invoiceHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    // Revoke after a delay to allow the new tab to load
    Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(url));
  }

  // ═══════════════════════════════════════════════════════════════
  //  INVOICE / RECEIPT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showInvoiceDialog() {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // Sort transactions for invoice (oldest first)
    final sortedTxs = List<LedgerTransaction>.from(_transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Compute running balances
    final List<double> runningBalances = [];
    double running = 0;
    for (final tx in sortedTxs) {
      if (tx.type == 'credit') {
        running += tx.amount;
      } else {
        running -= tx.amount;
      }
      runningBalances.add(running);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Actions bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('إغلاق'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            _printInvoiceHtml(dateStr, sortedTxs, runningBalances);
                          },
                          icon: const Icon(Icons.print, size: 18, color: Colors.white),
                          label: const Text('طباعة', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Invoice body (scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          const Center(
                            child: Text(
                              'كشف حساب',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              'تاريخ الإصدار: $dateStr',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontFamily: 'Space Grotesk',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 16),

                          // User info
                          _buildInvoiceInfoRow('الاسم', widget.userName),
                          if (widget.storeName.isNotEmpty)
                            _buildInvoiceInfoRow('المتجر', widget.storeName),
                          _buildInvoiceInfoRow('الهاتف', widget.user['phone'] ?? ''),
                          _buildInvoiceInfoRow('الولاية', widget.user['wilaya'] ?? ''),

                          const SizedBox(height: 20),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 16),

                          // Transaction table
                          Table(
                            border: TableBorder.all(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(1.2),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(1.2),
                              4: FlexColumnWidth(1.2),
                            },
                            children: [
                              // Header row
                              TableRow(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                children: const [
                                  _InvoiceHeaderCell('التاريخ'),
                                  _InvoiceHeaderCell('الوصف'),
                                  _InvoiceHeaderCell('مشتريات'),
                                  _InvoiceHeaderCell('مدفوع'),
                                  _InvoiceHeaderCell('الرصيد'),
                                ],
                              ),
                              // Data rows
                              for (int i = 0; i < sortedTxs.length; i++)
                                TableRow(
                                  children: [
                                    _InvoiceDataCell(
                                      '${sortedTxs[i].date.day.toString().padLeft(2, '0')}/${sortedTxs[i].date.month.toString().padLeft(2, '0')}/${sortedTxs[i].date.year} ${sortedTxs[i].date.hour.toString().padLeft(2, '0')}:${sortedTxs[i].date.minute.toString().padLeft(2, '0')}',
                                      isLTR: true,
                                    ),
                                    _InvoiceDataCell(
                                      sortedTxs[i].note.isEmpty ? '-' : sortedTxs[i].note,
                                    ),
                                    _InvoiceDataCell(
                                      sortedTxs[i].type == 'credit'
                                          ? sortedTxs[i].amount.toStringAsFixed(2)
                                          : '-',
                                      isLTR: true,
                                      color: AppColors.primary,
                                    ),
                                    _InvoiceDataCell(
                                      sortedTxs[i].type == 'debit'
                                          ? sortedTxs[i].amount.toStringAsFixed(2)
                                          : '-',
                                      isLTR: true,
                                      color: AppColors.error,
                                    ),
                                    _InvoiceDataCell(
                                      runningBalances[i].toStringAsFixed(2),
                                      isLTR: true,
                                      color: runningBalances[i] > 0 ? AppColors.error : AppColors.success,
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 16),

                          // Final summary
                          Row(
                            children: [
                              Expanded(
                                child: _buildInvoiceSummaryBox(
                                  'إجمالي المشتريات',
                                  _totalCredit.toStringAsFixed(2),
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInvoiceSummaryBox(
                                  'إجمالي المدفوع',
                                  _totalDebit.toStringAsFixed(2),
                                  AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInvoiceSummaryBox(
                                  'المبلغ المتبقي',
                                  _balance.abs().toStringAsFixed(2),
                                  _balance > 0 ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSummaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Space Grotesk',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INVOICE TABLE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _InvoiceHeaderCell extends StatelessWidget {
  final String text;
  const _InvoiceHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InvoiceDataCell extends StatelessWidget {
  final String text;
  final bool isLTR;
  final Color? color;
  const _InvoiceDataCell(this.text, {this.isLTR = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 12,
          fontFamily: isLTR ? 'Space Grotesk' : null,
        ),
      ),
    );
  }
}
