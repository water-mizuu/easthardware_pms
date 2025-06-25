import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/cubit/billing/payment_method_display/payment_method_display_enum.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'payment_method_display_state.dart';

class PaymentMethodDisplayCubit extends Cubit<PaymentMethodDisplayState> {
  PaymentMethodDisplayCubit() : super(PaymentMethodDisplayState.empty());

  void updateItems(List<PaymentMethod> paymentMethods) {
    emit(state.copyWith(allPaymentMethods: paymentMethods));
    _processQuery();
  }

  void updateSearch(String searchQuery) {
    emit(state.copyWith(searchQuery: searchQuery));
    _processQuery();
  }

  void updateSort(PaymentMethodDisplaySortBy sortBy) {
    // Check if we're selecting the same sort type that's already active
    if (state.sortBy == sortBy) {
      // Toggle the sort direction if the same sort type is selected again
      final newSortAscending = !state.sortAscending;
      emit(state.copyWith(sortAscending: newSortAscending));

      // Determine the appropriate sort type based on the field and direction
      final newSortBy = _getSortTypeBasedOnDirection(sortBy, newSortAscending);
      emit(state.copyWith(sortBy: newSortBy));
    } else {
      // Default to ascending order for new sort type
      emit(state.copyWith(
        sortBy: sortBy,
        sortAscending: true,
      ));
    }

    _processQuery();
  }

  // Helper method to get the correct sort type based on direction
  PaymentMethodDisplaySortBy _getSortTypeBasedOnDirection(
    PaymentMethodDisplaySortBy currentSort,
    bool ascending,
  ) {
    switch (currentSort) {
      case PaymentMethodDisplaySortBy.nameAscending:
      case PaymentMethodDisplaySortBy.nameDescending:
        return ascending
            ? PaymentMethodDisplaySortBy.nameDescending
            : PaymentMethodDisplaySortBy.nameAscending;
    }
  }

  Future<void> _processQuery() async {
    emit(state.copyWith(filteredPaymentMethods: null));

    var result = state.allPaymentMethods;
    if (result == null || result.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredPaymentMethods: null,
      ));
      return;
    }

    result = await Levenshtein.rankItems<PaymentMethod>(
      result,
      state.searchQuery,
      (paymentMethod) => {
        paymentMethod.name,
      },
      state.sortBy.comparePaymentMethods,
    );

    emit(state.copyWith(filteredPaymentMethods: result));
  }
}
