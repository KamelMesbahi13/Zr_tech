import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/responsive_wrapper.dart';
import '../services/ledger_service.dart';
import '../models/ledger_transaction_model.dart';
import '../models/order_model.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ═══════════════════════════════════════════════════════════════════
//  ORDER-SPECIFIC LEDGER DIALOG
// ═══════════════════════════════════════════════════════════════════

class OrderLedgerDialog extends StatefulWidget {
  final String userId;
  final OrderModel order;
  final LedgerService ledgerService;

  const OrderLedgerDialog({
    super.key,
    required this.userId,
    required this.order,
    required this.ledgerService,
  });

  @override
  State<OrderLedgerDialog> createState() => _OrderLedgerDialogState();
}

class _OrderLedgerDialogState extends State<OrderLedgerDialog> {
  List<LedgerTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txs = await widget.ledgerService.getOrderTransactions(widget.userId, widget.order.orderId);
      if (!mounted) return;
      setState(() {
        _transactions = txs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // The order total is the credit (purchase)
  double get _totalCredit => widget.order.totalPrice;

  // Total payments for this order
  double get _totalDebit => _transactions
      .where((t) => t.type == 'debit')
      .fold(0.0, (sum, t) => sum + t.amount);

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
                _buildDialogHeader(),
                _buildBalanceSummary(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _buildCombinedList(),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════

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
                widget.order.customerFullName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.fp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.order.productName,
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
                widget.order.customerFullName.isNotEmpty
                    ? widget.order.customerFullName[0].toUpperCase()
                    : '?',
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

  // ═══════════════════════════════════════════════════════════════
  //  BALANCE SUMMARY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBalanceSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            label: 'المبلغ المتبقي',
            value: _balance.abs().toStringAsFixed(2),
            color: _balance > 0 ? AppColors.error : AppColors.success,
            icon: Icons.warning_amber_rounded,
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildSummaryItem(
            label: 'إجمالي المدفوع',
            value: _totalDebit.toStringAsFixed(2),
            color: AppColors.success,
            icon: Icons.payments,
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildSummaryItem(
            label: 'إجمالي الطلب',
            value: _totalCredit.toStringAsFixed(2),
            color: AppColors.primary,
            icon: Icons.shopping_cart,
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
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: Responsive.fp(18),
              fontWeight: FontWeight.bold,
              fontFamily: 'Space Grotesk',
            ),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSlate400,
                    fontSize: Responsive.fp(10),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  COMBINED LIST (order card + payment transactions)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCombinedList() {
    // Calculate running balances
    final sortedAsc = List<LedgerTransaction>.from(_transactions)
      ..sort((a, b) => a.date.compareTo(b.date));
    final Map<String, double> runningBalances = {};
    double running = _totalCredit;
    for (final tx in sortedAsc) {
      if (tx.type == 'debit') {
        running -= tx.amount;
      } else {
        running += tx.amount;
      }
      runningBalances[tx.id] = running;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // ── ORDER SECTION ──
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'طلبات من الموقع (1)',
                      style: TextStyle(
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
        _buildOrderCard(),

        if (_transactions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.border),
          ),
          // ── PAYMENTS SECTION ──
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

  Widget _buildOrderCard() {
    final order = widget.order;
    final dateStr = order.createdAt > 0
        ? () {
            final d = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
            return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
          }()
        : '-';

    final statusLabels = {
      'pending': 'قيد الانتظار',
      'waiting': 'في الانتظار',
      'preparing': 'قيد التحضير',
      'ready': 'جاهز',
      'on_the_way': 'في الطريق',
      'delivered': 'تم التوصيل',
      'received': 'تم الاستلام',
      'cancelled': 'ملغى',
      'rejected': 'مرفوض',
    };
    final statusText = statusLabels[order.normalizedStatus] ?? order.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            Positioned(
              top: 0, bottom: 0, right: 0, width: 4,
              child: Container(color: AppColors.primary),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
              child: Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart, color: AppColors.primary, size: 12),
                        const SizedBox(width: 4),
                        Text('شراء', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(statusText, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ),
                  const Spacer(),
                  // Amount
                  Text(
                    '${order.totalPrice.toStringAsFixed(2)} د.ج',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: Responsive.fp(15),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Space Grotesk',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date + product
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
                        const SizedBox(height: 4),
                        Text(
                          '${order.productName} x${order.quantity}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: Responsive.fp(12),
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  // ═══════════════════════════════════════════════════════════════
  //  TRANSACTION ITEM
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTransactionItem(LedgerTransaction tx, double runningBalance) {
    final isCredit = tx.type == 'credit';
    final typeColor = isCredit ? AppColors.primary : AppColors.success;
    final typeLabel = isCredit ? 'شراء' : 'دفع';
    final typeIcon = isCredit ? Icons.shopping_cart : Icons.payments;
    final dateStr = '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}:${tx.date.second.toString().padLeft(2, '0')} ${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}';

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
            Positioned(top: 0, bottom: 0, right: 0, width: 4, child: Container(color: typeColor)),
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
                      Text('المتبقي', style: TextStyle(color: AppColors.textMuted, fontSize: Responsive.fp(10))),
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
                        style: TextStyle(color: typeColor, fontSize: Responsive.fp(15), fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
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
                            Text(typeLabel, style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600)),
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
                        Text(dateStr, style: TextStyle(color: AppColors.textSecondary, fontSize: Responsive.fp(13), fontFamily: 'Space Grotesk')),
                        if (tx.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(tx.note, style: TextStyle(color: AppColors.textMuted, fontSize: Responsive.fp(12)), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
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

  // ═══════════════════════════════════════════════════════════════
  //  BOTTOM ACTIONS (Invoice + Add Payment only)
  // ═══════════════════════════════════════════════════════════════

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
  //  ADD PAYMENT DIALOG
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
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
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Space Grotesk', fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'المبلغ (د.ج)',
                          labelStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
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
                          labelText: 'ملاحظة (اختياري)',
                          labelStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.note_outlined, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setSheetState(() => selectedDate = picked);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontFamily: 'Space Grotesk'),
                              ),
                              const Spacer(),
                              const Text('التاريخ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final amountStr = amountController.text.trim();
                                  if (amountStr.isEmpty) return;
                                  final amount = double.tryParse(amountStr);
                                  if (amount == null || amount <= 0) return;
                                  setSheetState(() => isSaving = true);
                                  try {
                                    final tx = LedgerTransaction(
                                      id: '',
                                      amount: amount,
                                      type: 'debit',
                                      note: noteController.text.trim(),
                                      orderId: widget.order.orderId,
                                      date: selectedDate,
                                    );
                                    await widget.ledgerService.addTransaction(widget.userId, tx);
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payments, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('تسجيل الدفعة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
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
  //  INVOICE / RECEIPT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showInvoiceDialog() {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final order = widget.order;
    final List<Map<String, dynamic>> entries = [];

    // Add the order as a credit entry
    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
    entries.add({
      'date': orderDate,
      'desc': '${order.quantity}× ${order.productName}',
      'credit': order.totalPrice,
      'debit': null,
    });

    // Add payments
    for (final tx in _transactions) {
      entries.add({
        'date': tx.date,
        'desc': tx.note.isEmpty ? 'دفعة' : tx.note,
        'credit': tx.type == 'credit' ? tx.amount : null,
        'debit': tx.type == 'debit' ? tx.amount : null,
      });
    }

    entries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    final List<double> runningBalances = [];
    double running = 0;
    for (final e in entries) {
      if (e['credit'] != null) running += (e['credit'] as double);
      if (e['debit'] != null) running -= (e['debit'] as double);
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
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
                          onPressed: () => _printOrderInvoiceHtml(dateStr, entries, runningBalances),
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: Text('كشف حساب الطلب', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              'تاريخ الإصدار: $dateStr',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Space Grotesk'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 16),
                          _buildInvoiceInfoRow('الزبون', order.customerFullName),
                          _buildInvoiceInfoRow('الهاتف', order.phone),
                          _buildInvoiceInfoRow('الولاية', order.wilaya),
                          _buildInvoiceInfoRow('المنتج', order.productName),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 16),

                          // Transaction table
                          Table(
                            border: TableBorder.all(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
                            columnWidths: const {
                              0: FlexColumnWidth(1.2),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(1.2),
                              4: FlexColumnWidth(1.2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                children: const [
                                  _OrderInvoiceHeaderCell('التاريخ'),
                                  _OrderInvoiceHeaderCell('الوصف'),
                                  _OrderInvoiceHeaderCell('مشتريات'),
                                  _OrderInvoiceHeaderCell('مدفوع'),
                                  _OrderInvoiceHeaderCell('الرصيد'),
                                ],
                              ),
                              for (int i = 0; i < entries.length; i++)
                                TableRow(
                                  children: [
                                    _OrderInvoiceDataCell(
                                      '${(entries[i]['date'] as DateTime).day.toString().padLeft(2, '0')}/${(entries[i]['date'] as DateTime).month.toString().padLeft(2, '0')}/${(entries[i]['date'] as DateTime).year} ${(entries[i]['date'] as DateTime).hour.toString().padLeft(2, '0')}:${(entries[i]['date'] as DateTime).minute.toString().padLeft(2, '0')}',
                                      isLTR: true,
                                    ),
                                    _OrderInvoiceDataCell(entries[i]['desc'] as String),
                                    _OrderInvoiceDataCell(
                                      entries[i]['credit'] != null ? (entries[i]['credit'] as double).toStringAsFixed(2) : '-',
                                      isLTR: true,
                                      color: AppColors.primary,
                                    ),
                                    _OrderInvoiceDataCell(
                                      entries[i]['debit'] != null ? (entries[i]['debit'] as double).toStringAsFixed(2) : '-',
                                      isLTR: true,
                                      color: AppColors.error,
                                    ),
                                    _OrderInvoiceDataCell(
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

                          // Summary boxes
                          Row(
                            children: [
                              Expanded(
                                child: _buildInvoiceSummaryBox('إجمالي الطلب', _totalCredit.toStringAsFixed(2), AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInvoiceSummaryBox('إجمالي المدفوع', _totalDebit.toStringAsFixed(2), AppColors.success),
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

  // ═══════════════════════════════════════════════════════════════
  //  PRINT INVOICE HTML
  // ═══════════════════════════════════════════════════════════════

  void _printOrderInvoiceHtml(String dateStr, List<Map<String, dynamic>> entries, List<double> runningBalances) {
    final order = widget.order;
    final rowsHtml = StringBuffer();
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final d = e['date'] as DateTime;
      final txDate = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      final desc = e['desc'] as String;
      final credit = e['credit'] != null ? (e['credit'] as double).toStringAsFixed(2) : '-';
      final debit = e['debit'] != null ? (e['debit'] as double).toStringAsFixed(2) : '-';
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
  <title>كشف حساب طلب - ${order.customerFullName}</title>
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
  <h1>كشف حساب طلب</h1>
  <div class="subtitle">تاريخ الإصدار: $dateStr</div>
  <div class="info-section">
    <div class="info-row"><span class="info-label">الزبون:</span><span>${order.customerFullName}</span></div>
    <div class="info-row"><span class="info-label">الهاتف:</span><span>${order.phone}</span></div>
    <div class="info-row"><span class="info-label">الولاية:</span><span>${order.wilaya}</span></div>
    <div class="info-row"><span class="info-label">المنتج:</span><span>${order.productName}</span></div>
  </div>
  <table>
    <thead><tr><th>التاريخ</th><th>الوصف</th><th>مشتريات</th><th>مدفوع</th><th>الرصيد</th></tr></thead>
    <tbody>$rowsHtml</tbody>
  </table>
  <div class="summary">
    <div class="summary-box" style="border-color:#1976D2"><div class="value" style="color:#1976D2">${_totalCredit.toStringAsFixed(2)}</div><div class="label">إجمالي الطلب</div></div>
    <div class="summary-box" style="border-color:#43a047"><div class="value" style="color:#43a047">${_totalDebit.toStringAsFixed(2)}</div><div class="label">إجمالي المدفوع</div></div>
    <div class="summary-box" style="border-color:${_balance > 0 ? '#e53935' : '#43a047'}"><div class="value" style="color:${_balance > 0 ? '#e53935' : '#43a047'}">${_balance.abs().toStringAsFixed(2)}</div><div class="label">المبلغ المتبقي</div></div>
  </div>
  <script>window.onload = function() { window.print(); }</script>
</body>
</html>
    ''';

    final blob = html.Blob([invoiceHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(url));
  }

  // ═══════════════════════════════════════════════════════════════
  //  INVOICE HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInvoiceInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
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
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INVOICE TABLE HELPER WIDGETS (Order-specific)
// ═══════════════════════════════════════════════════════════════════

class _OrderInvoiceHeaderCell extends StatelessWidget {
  final String text;
  const _OrderInvoiceHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _OrderInvoiceDataCell extends StatelessWidget {
  final String text;
  final bool isLTR;
  final Color? color;
  const _OrderInvoiceDataCell(this.text, {this.isLTR = false, this.color});

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

// ═══════════════════════════════════════════════════════════════════
//  PUBLIC HELPER — open the order ledger dialog from anywhere
// ═══════════════════════════════════════════════════════════════════

void openOrderLedgerDialog(
  BuildContext context, {
  required String userId,
  required OrderModel order,
  required LedgerService ledgerService,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'order-ledger',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim, anim2) {
      return OrderLedgerDialog(
        userId: userId,
        order: order,
        ledgerService: ledgerService,
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
