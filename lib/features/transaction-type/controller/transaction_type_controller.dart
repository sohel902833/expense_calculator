import 'package:expense_calculator/features/transaction-type/repository/transaction_type_data_source.dart';
import 'package:expense_calculator/features/transaction-type/repository/transaction_type_repository.dart';
import 'package:expense_calculator/models/transaction_type_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// final transactionTypeControllerProvider = Provider((ref) {
//   final transactionTypeRepository = ref.watch(
//     transactionTypeRepositoryProvider,
//   );
//   return TransactionTypeController(
//     transactionTypeRepository: transactionTypeRepository,
//     ref: ref,
//   );
// });

final transactionTypeControllerProvider =
    StateNotifierProvider<
      TransactionTypeController,
      List<TransactionTypeModel>
    >((ref) {
      final repository = ref.watch(transactionTypeRepositoryProvider);
      return TransactionTypeController(
        transactionTypeRepository: repository,
        ref: ref,
      );
    });

final transactionTypesStreamProvider =
    StreamProvider<List<TransactionTypeModel>>((ref) {
      final repo = ref.watch(transactionTypeRepositoryProvider);
      return repo.getTransactionTypes();
    });

class TransactionTypeController
    extends StateNotifier<List<TransactionTypeModel>> {
  final TransactionTypeDataSource transactionTypeRepository;
  final Ref ref;
  TransactionTypeController({
    required this.transactionTypeRepository,
    required this.ref,
  }) : super([]) {
    _listenTransactionTypes();
  }
  void _listenTransactionTypes() {
    transactionTypeRepository.getTransactionTypes().listen((types) {
      state = types;
    });
  }

  Future<void> addTransactionType(TransactionTypeModel type) async {
    await transactionTypeRepository.addTransactionType(type);
  }

  Future<void> updateTransactionType(TransactionTypeModel type) async {
    await transactionTypeRepository.updateTransactionType(type);
  }

  Future<void> deleteTransactionType(String id) async {
    await transactionTypeRepository.deleteTransactionType(id);
  }
}
