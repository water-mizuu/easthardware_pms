import 'dart:async';

import 'package:easthardware_pms/data/database/dao/metadata_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';
import 'package:easthardware_pms/domain/repository/expense_type_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_repository.dart';
import 'package:easthardware_pms/domain/repository/order_item_repository.dart';
import 'package:easthardware_pms/domain/repository/order_product_repository.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/domain/repository/payment_method_repository.dart';
import 'package:easthardware_pms/domain/repository/payment_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';
import 'package:easthardware_pms/domain/repository/unit_repository.dart';
import 'package:easthardware_pms/domain/repository/user_log_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/login_form/'
    'login_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/new_password_form/'
    'new_password_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/reset_form/reset_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/business_snapshot/business_snapshot_report_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/'
    'category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/'
    'expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_list/payment_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/'
    'payment_method_list/payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/security_questions/'
    'security_question_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/database_information/'
    'database_information_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/inventory/'
    'category_display/category_display_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/payment/'
    'payment_display/payment_display_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/bottom_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class DependencyInjector extends ChangeNotifier {
  DependencyInjector()
      : bottomText = ValueNotifier(""),
        serverBloc = ServerBloc()..add(const ServerInit());

  final ValueNotifier<String> bottomText;
  final ServerBloc serverBloc;

  late MetadataDao _metadataDao;

  late AuthenticationRepository _authenticationRepository;
  late ProductRepository _productRepository;
  late InvoiceRepository _invoiceRepository;
  late InvoiceProductRepository _invoiceProductRepository;
  late PaymentMethodRepository _paymentMethodRepository;
  late OrderProductRepository _orderProductRepository;
  late OrderItemRepository _orderItemRepository;
  late OrderRepository _orderRepository;
  late ExpenseTypeRepository _expenseTypeRepository;
  late CategoryRepository _categoryRepository;
  late UnitRepository _unitRepository;
  late UserLogRepository _userLogRepository;
  late UserRepository _userRepository;
  late SecurityQuestionRepository _securityQuestionRepository;
  late PaymentRepository _paymentRepository;

  // Bloc instances that will be managed by the injector
  AuthenticationBloc? _authenticationBloc;
  UserListBloc? _userListBloc;
  ProductListBloc? _productListBloc;
  CategoryListBloc? _categoryListBloc;
  UnitListBloc? _unitListBloc;
  UserLogListBloc? _userLogListBloc;
  SecurityQuestionListBloc? _securityQuestionListBloc;
  ResetFormBloc? _resetFormBloc;
  InvoiceListBloc? _invoiceListBloc;
  PaymentMethodListBloc? _paymentMethodListBloc;
  PaymentListBloc? _paymentListBloc;
  OrderListBloc? _orderListBloc;
  ExpenseTypeListBloc? _expenseTypeListBloc;

  NewPasswordFormBloc? _newPasswordFormBloc;
  LoginFormBloc? _loginFormBloc;

  DatabaseInformationCubit? _databaseInformationCubit;

  late DatabaseHelper? _databaseHelper;
  late DateTime? _lastUpdated;

  Future<void> initialize({DatabaseHelper? databaseHelper}) async {
    _databaseHelper = databaseHelper;
    _lastUpdated = DateTime.now();

    _metadataDao = MetadataDao(databaseHelper);
    _authenticationRepository = AuthenticationRepository(databaseHelper);
    _productRepository = ProductRepository(databaseHelper);
    _invoiceRepository = InvoiceRepository(databaseHelper);
    _invoiceProductRepository = InvoiceProductRepository(databaseHelper);
    _paymentMethodRepository = PaymentMethodRepository(databaseHelper);
    _paymentRepository = PaymentRepository(databaseHelper);
    _orderProductRepository = OrderProductRepository(databaseHelper);
    _orderItemRepository = OrderItemRepository(databaseHelper);
    _orderRepository = OrderRepository(databaseHelper);
    _expenseTypeRepository = ExpenseTypeRepository(databaseHelper);
    _categoryRepository = CategoryRepository(databaseHelper);
    _unitRepository = UnitRepository(databaseHelper);
    _userLogRepository = UserLogRepository(databaseHelper);
    _userRepository = UserRepository(databaseHelper);
    _securityQuestionRepository = SecurityQuestionRepository(databaseHelper);

    notifyListeners();
  }

  List<SingleChildWidget> inject() {
    if (kDebugMode) {
      print("Dependency Injector: Injecting dependencies");
    }

    ValueKey key() => ValueKey((_databaseHelper, _lastUpdated));

    return [
      BlocProvider(create: (_) => NavigationCubit()),
      Provider.value(value: BottomTextNotifier(bottomText)),
      BlocProvider.value(value: serverBloc),
      RepositoryProvider.value(value: _categoryRepository),
      RepositoryProvider.value(value: _invoiceProductRepository),
      RepositoryProvider.value(value: _invoiceRepository),
      RepositoryProvider.value(value: _paymentMethodRepository),
      RepositoryProvider.value(value: _paymentRepository),
      RepositoryProvider.value(value: _orderProductRepository),
      RepositoryProvider.value(value: _orderItemRepository),
      RepositoryProvider.value(value: _expenseTypeRepository),
      RepositoryProvider.value(value: _orderRepository),
      RepositoryProvider.value(value: _productRepository),
      RepositoryProvider.value(value: _unitRepository),
      RepositoryProvider.value(value: _userRepository),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _authenticationBloc?.state ?? const AuthenticationState();

          return _authenticationBloc = AuthenticationBloc(_authenticationRepository, state);
        },
      ),
      BlocProvider(
        lazy: false,
        key: key(),
        create: (context) {
          final state = _userListBloc?.state ?? const UserListState();

          return _userListBloc = UserListBloc(_userRepository, state)
            ..addIf(_databaseHelper != null, const LoadAllUsersEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _productListBloc?.state ?? const ProductListState.initial();

          return _productListBloc = ProductListBloc(
            _productRepository,
            _categoryRepository,
            _unitRepository,
            state,
          )..addIf(_databaseHelper != null, const LoadAllProductsEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _categoryListBloc?.state ?? CategoryListInitial();

          return _categoryListBloc = CategoryListBloc(_categoryRepository, state)
            ..addIf(_databaseHelper != null, const LoadCategoriesEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _unitListBloc?.state ?? const UnitListState.initial();

          return _unitListBloc = UnitListBloc(_unitRepository, state)
            ..addIf(_databaseHelper != null, const LoadUnitsEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _userLogListBloc?.state ?? UserLogListState();

          return _userLogListBloc = UserLogListBloc(_userRepository, _userLogRepository, state)
            ..addIf(_databaseHelper != null, const LoadUserLogsEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _securityQuestionListBloc?.state ?? const SecurityQuestionListState();

          return _securityQuestionListBloc =
              SecurityQuestionListBloc(_securityQuestionRepository, state)
                ..addIf(_databaseHelper != null, const FetchSecurityQuestionsEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _newPasswordFormBloc?.state ?? const NewPasswordFormState();

          return _newPasswordFormBloc = NewPasswordFormBloc(
            userRepository: _userRepository,
            initialState: state,
          );
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _invoiceListBloc?.state ?? const InvoiceListState();

          return _invoiceListBloc = InvoiceListBloc(
            _invoiceRepository,
            _invoiceProductRepository,
            _productRepository,
            state,
          )..addIf(_databaseHelper != null, const FetchAllInvoicesEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _paymentMethodListBloc?.state ?? const PaymentMethodListState();

          return _paymentMethodListBloc = PaymentMethodListBloc(_paymentMethodRepository, state)
            ..addIf(_databaseHelper != null, const FetchAllPaymentMethodsEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _paymentListBloc?.state ?? const PaymentListState();

          return _paymentListBloc = PaymentListBloc(_paymentRepository, state)
            ..addIf(_databaseHelper != null, const FetchAllPaymentsEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _orderListBloc?.state ?? const OrderListState();

          return _orderListBloc = OrderListBloc(
            _orderRepository,
            _orderProductRepository,
            _orderItemRepository,
            _productRepository,
            state,
          )..addIf(_databaseHelper != null, const FetchAllOrdersEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _expenseTypeListBloc?.state ?? const ExpenseTypeListState();

          return _expenseTypeListBloc = ExpenseTypeListBloc(_expenseTypeRepository, state)
            ..addIf(_databaseHelper != null, const FetchAllExpenseTypesEvent());
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _resetFormBloc?.state ?? const ResetFormState();

          return _resetFormBloc = ResetFormBloc(
            userRepository: _userRepository,
            securityQuestionRepository: _securityQuestionRepository,
            initialState: state,
          );
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _loginFormBloc?.state ?? const LoginFormState();

          return _loginFormBloc = LoginFormBloc(state);
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final state = _databaseInformationCubit?.state ?? const DatabaseInformationState();

          return _databaseInformationCubit = DatabaseInformationCubit(_metadataDao, state)
            ..mapIf(_databaseHelper != null, (c) => unawaited(c.loadMetadata()));
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) => InventoryDisplayBloc(),
      ),
      BlocProvider(
        key: key(),
        create: (context) => CategoryDisplayCubit(),
      ),
      BlocProvider(
        key: key(),
        create: (context) => PaymentDisplayCubit(),
      ),
      BlocProvider(
        key: key(),
        create: (context) {
          final productListBloc = context.read<ProductListBloc>();
          final invoiceListBloc = context.read<InvoiceListBloc>();
          final orderListBloc = context.read<OrderListBloc>();
          final expenseTypeListBloc = context.read<ExpenseTypeListBloc>();

          return BusinessSnapshotReportBloc(
            productListBloc.state.allProducts,
            invoiceListBloc.state.invoices,
            invoiceListBloc.state.invoiceProducts,
            orderListBloc.state.allOrders,
            orderListBloc.state.allOrderProducts,
            expenseTypeListBloc.state.expenseTypes,
          );
        },
      ),
    ];
  }

  /// Tells the loaded blocs to refresh their data.
  void markNeedsRefresh() {
    if (kDebugMode) {
      print("Dependency Injector: Marking needs refresh");
    }

    _lastUpdated = DateTime.now();
    notifyListeners();
  }
}

extension<E, S> on Bloc<E, S> {
  void addIf(bool condition, E event) {
    if (condition) add(event);
  }
}

extension<C extends Cubit> on C {
  void mapIf(bool condition, void Function(C) callback) {
    if (condition) callback(this);
  }
}
