import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/category_repository.dart';
import 'package:easthardware_pms/data/repository/invoice_repository.dart';
import 'package:easthardware_pms/data/repository/order_repository.dart';
import 'package:easthardware_pms/data/repository/product_repository.dart';
import 'package:easthardware_pms/data/repository/security_question_repository.dart';
import 'package:easthardware_pms/data/repository/user_log_repository.dart';
import 'package:easthardware_pms/data/repository/user_repository.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_repository.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';
import 'package:easthardware_pms/domain/repository/unit_repository.dart';
import 'package:easthardware_pms/domain/repository/user_log_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/'
    'authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/new_password_form/new_password_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/reset_form/reset_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/security_questions/security_question_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/bottom_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class DependencyInjector {
  DependencyInjector()
      : bottomText = ValueNotifier(""),
        serverBloc = ServerBloc()..add(const ServerInit());

  final ValueNotifier<String> bottomText;
  final ServerBloc serverBloc;

  late AuthenticationRepository _authenticationRepository;
  late ProductRepository _productRepository;
  late InvoiceRepository _invoiceRepository;
  late OrderRepository _orderRepository;
  late CategoryRepository _categoryRepository;
  late UnitRepository _unitRepository;
  late UserLogRepository _userLogRepository;
  late UserRepository _userRepository;
  late SecurityQuestionRepository _securityQuestionRepository;

  late DatabaseHelper? _databaseHelper;

  UserListBloc? _userListBloc;
  ProductListBloc? _productListBloc;
  CategoryListBloc? _categoryListBloc;
  UnitListBloc? _unitListBloc;
  UserLogListBloc? _userLogListBloc;
  SecurityQuestionListBloc? _securityQuestionListBloc;
  InvoiceListBloc? _invoiceListBloc;
  OrderListBloc? _orderListBloc;
  ResetFormBloc? _resetFormBloc;
  NewPasswordFormBloc? _newPasswordFormBloc;

  Future<void> initialize({
    DatabaseHelper? databaseHelper,
  }) async {
    _databaseHelper = databaseHelper;
    _authenticationRepository = AuthenticationRepository(databaseHelper);

    _productRepository = ProductRepositoryImpl(databaseHelper);
    _invoiceRepository = InvoiceRepositoryImpl(databaseHelper);
    _orderRepository = OrderRepositoryImpl(databaseHelper);
    _categoryRepository = CategoryRepositoryImpl(databaseHelper);
    _unitRepository = UnitRepository(databaseHelper);
    _userLogRepository = UserLogRepositoryImpl(databaseHelper);
    _userRepository = UserRepositoryImpl(databaseHelper);
    _securityQuestionRepository =
        SecurityQuestionRepositoryImpl(databaseHelper);
  }

  List<SingleChildWidget> inject() {
    if (kDebugMode) {
      print("Dependency Injector: Injecting dependencies");
    }

    ValueKey key() => ValueKey(_databaseHelper);

    return [
      Provider.value(value: BottomTextNotifier(bottomText)),
      BlocProvider.value(value: serverBloc),
      RepositoryProvider.value(value: _categoryRepository),
      RepositoryProvider.value(value: _productRepository),
      RepositoryProvider.value(value: _unitRepository),
      BlocProvider(
        create: (context) => AuthenticationBloc(_authenticationRepository),
        key: key(),
      ),
      BlocProvider(
        create: (context) => NavigationCubit(),
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _userListBloc?.close();

          return _userListBloc = UserListBloc(_userRepository)
            ..add(LoadAllUsersEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _productListBloc?.close();

          return _productListBloc = ProductListBloc(_productRepository)
            ..add(LoadAllProductsEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _categoryListBloc?.close();

          return _categoryListBloc = CategoryListBloc(_categoryRepository)
            ..add(LoadCategoriesEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _unitListBloc?.close();

          return _unitListBloc = UnitListBloc(_unitRepository) //
            ..add(LoadUnitsEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _userLogListBloc?.close();

          return _userLogListBloc = UserLogListBloc(_userLogRepository)
            ..add(const LoadUserLogsEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _securityQuestionListBloc?.close();

          return _securityQuestionListBloc =
              SecurityQuestionListBloc(_securityQuestionRepository)
                ..add(const FetchSecurityQuestionsEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _resetFormBloc?.close();
          return _resetFormBloc = ResetFormBloc(
              userRepository: _userRepository,
              securityQuestionRepository: _securityQuestionRepository);
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _newPasswordFormBloc?.close();
          return _newPasswordFormBloc = NewPasswordFormBloc(
            userRepository: _userRepository,
          );
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _invoiceListBloc?.close();

          return _invoiceListBloc = InvoiceListBloc(_invoiceRepository)
            ..add(const FetchAllInvoicesEvent());
        },
        key: ValueKey(_databaseHelper),
      ),
      BlocProvider(
        create: (context) {
          _orderListBloc?.close();

          return _orderListBloc = OrderListBloc(_orderRepository)
            ..add(FetchAllOrdersEvent());
        },
        key: key(),
      ),
    ];
  }

  /// Tells the loaded blocs to refresh their data.
  ///   TODO: Investigate if there is a way to delay updates to only UI required blocs.
  void markNeedsRefresh() {
    if (kDebugMode) {
      print("Dependency Injector: Marking needs refresh");
      print([
        _userListBloc,
        _productListBloc,
        _invoiceListBloc,
        _categoryListBloc,
        _unitListBloc,
        _userLogListBloc,
        _securityQuestionListBloc,
      ]);
    }

    _userListBloc?.add(LoadAllUsersEvent());
    _productListBloc?.add(LoadAllProductsEvent());
    _invoiceListBloc?.add(const FetchAllInvoicesEvent());
    _categoryListBloc?.add(LoadCategoriesEvent());
    _unitListBloc?.add(LoadUnitsEvent());
    _userLogListBloc?.add(const LoadUserLogsEvent());
    _securityQuestionListBloc?.add(const FetchSecurityQuestionsEvent());
  }
}
