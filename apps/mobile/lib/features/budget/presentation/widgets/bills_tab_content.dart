import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/finance_providers.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Content view for the Bills tab adhering to the Neo-Brutalist design system.
class BillsTabContent extends ConsumerWidget {
  const BillsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);

    double totalBillsAmount = 0;
    double paidAmount = 0;
    for (var b in bills) {
      totalBillsAmount += b.amount;
      if (b.isPaid) paidAmount += b.amount;
    }

    final remaining = totalBillsAmount - paidAmount;
    final progress = totalBillsAmount > 0
        ? (paidAmount / totalBillsAmount).clamp(0.0, 1.0)
        : 0.0;

    final upcomingBills = bills.where((b) => !b.isPaid).toList();
    final paidBills = bills.where((b) => b.isPaid).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Total Bills Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FDF5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL BILLS FOR JAN',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${totalBillsAmount.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: NeoBrutalism.lime,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid: Rp ${paidAmount.toInt()}',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Remaining: Rp ${remaining.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Upcoming Payments Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Payments',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/bill/add'),
                  child: Row(
                    children: const [
                      Icon(Icons.add, color: Colors.black, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Add new bills',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Upcoming Bills List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: upcomingBills.map((bill) {
                final daysLeft = bill.dueDate != null
                    ? bill.dueDate!.difference(DateTime.now()).inDays
                    : 0;
                final dateTag = bill.dueDate != null
                    ? (daysLeft >= 0
                        ? 'Due in $daysLeft days'
                        : 'Overdue by ${daysLeft.abs()} days')
                    : 'No due date';
                final dateTagColor = daysLeft <= 2
                    ? const Color(0xFFFFDAD6)
                    : const Color(0xFFFFF2D6);
                final dateTagTextColor = daysLeft <= 2
                    ? const Color(0xFFBA1A1A)
                    : const Color(0xFFB56500);

                return Dismissible(
                  key: Key(bill.id),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      context.push('/bill/edit/${bill.id}');
                      return false;
                    } else if (direction == DismissDirection.startToEnd) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.black, width: 2.0),
                          ),
                          title: const Text(
                            'Hapus Bill',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          content: Text(
                            'Apakah kamu yakin akan menghapus "${bill.name}"?',
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Hapus',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: Colors.red,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      return confirm == true;
                    }
                    return false;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.startToEnd) {
                      ref.read(billsProvider.notifier).removeBill(bill.id);
                    }
                  },
                  child: GestureDetector(
                    onTap: () => context.push('/bill/edit/${bill.id}'),
                    child: _buildPaymentCard(
                      title: bill.name,
                      dateTag: dateTag,
                      dateTagColor: dateTagColor,
                      dateTagTextColor: dateTagTextColor,
                      dateStr: bill.dueDate != null
                          ? '${bill.dueDate!.day}/${bill.dueDate!.month}'
                          : null,
                      amount: 'Rp ${bill.amount.toInt()}',
                      actionLabel: bill.isAutoPay ? 'Auto-pay on' : 'Pay Now',
                      actionColor: bill.isAutoPay
                          ? Colors.grey.shade600
                          : const Color(0xFF0F758A),
                      icon: bill.icon,
                      iconBgColor: bill.iconBgColor,
                      iconColor: bill.iconColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Paid This Month Section
          if (paidBills.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Paid this month',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Opacity(
                opacity: 0.75,
                child: Column(
                  children: paidBills.map((bill) {
                    return Dismissible(
                      key: Key(bill.id),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        alignment: Alignment.centerLeft,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          context.push('/bill/edit/${bill.id}');
                          return false;
                        } else if (direction == DismissDirection.startToEnd) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(
                                    color: Colors.black, width: 2.0),
                              ),
                              title: const Text(
                                'Hapus Bill',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              content: Text(
                                'Apakah kamu yakin akan menghapus "${bill.name}"?',
                                style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(
                                    'Batal',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.red,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          return confirm == true;
                        }
                        return false;
                      },
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          ref.read(billsProvider.notifier).removeBill(bill.id);
                        }
                      },
                      child: _buildPaidCard(
                        title: bill.name,
                        dateStr: bill.dueDate != null
                            ? 'Paid on ${bill.dueDate!.day}/${bill.dueDate!.month}'
                            : 'Paid',
                        amount: 'Rp ${bill.amount.toInt()}',
                        icon: bill.icon,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required String title,
    required String dateTag,
    required Color dateTagColor,
    required Color dateTagTextColor,
    String? dateStr,
    required String amount,
    required String actionLabel,
    required Color actionColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: dateTagColor,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: Colors.black, width: 1.2),
                      ),
                      child: Text(
                        dateTag,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: dateTagTextColor,
                        ),
                      ),
                    ),
                    if (dateStr != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                actionLabel,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: actionColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaidCard({
    required String title,
    required String dateStr,
    required String amount,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
