import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../domain/sales_summary.dart';

final salesRangeProvider = StateProvider<String>((_) => 'day'); // day, week, month

final salesSummaryProvider = FutureProvider.autoDispose<SalesSummary>((ref) async {
  final range = ref.watch(salesRangeProvider);
  final repo = ref.read(orderRepositoryProvider);
  return repo.fetchSalesSummary(range);
});
