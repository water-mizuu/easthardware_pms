import 'package:easthardware_pms/data/database/database_helper.dart';
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

  void initialize({DatabaseHelper? databaseHelper}) {
    _databaseHelper = databaseHelper;
    _authenticationRepository = AuthenticationRepository(databaseHelper);

    _productRepository = ProductRepository(databaseHelper);
    _invoiceRepository = InvoiceRepository(databaseHelper);
    _orderRepository = OrderRepository(databaseHelper);
    _categoryRepository = CategoryRepository(databaseHelper);
    _unitRepository = UnitRepository(databaseHelper);
    _userLogRepository = UserLogRepository(databaseHelper);
    _userRepository = UserRepository(databaseHelper);
    _securityQuestionRepository = SecurityQuestionRepository(databaseHelper);
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
        lazy: false,
        create: (context) {
          _userListBloc?.close();
          _userListBloc = UserListBloc(_userRepository);
          if (_databaseHelper != null) {
            _userListBloc!.add(const LoadAllUsersEvent());
          }

          return _userListBloc!;
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _productListBloc?.close();

          return _productListBloc = ProductListBloc(_productRepository)
            ..add(const LoadAllProductsEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _categoryListBloc?.close();

          return _categoryListBloc = CategoryListBloc(_categoryRepository)
            ..add(const LoadCategoriesEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _unitListBloc?.close();

          return _unitListBloc = UnitListBloc(_unitRepository) //
            ..add(const LoadUnitsEvent());
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

          return _securityQuestionListBloc = SecurityQuestionListBloc(_securityQuestionRepository)
            ..add(const FetchSecurityQuestionsEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _resetFormBloc?.close();
          return _resetFormBloc = ResetFormBloc(
            userRepository: _userRepository,
            securityQuestionRepository: _securityQuestionRepository,
          );
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _newPasswordFormBloc?.close();
          return _newPasswordFormBloc = NewPasswordFormBloc(userRepository: _userRepository);
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _invoiceListBloc?.close();

          return _invoiceListBloc = InvoiceListBloc(_invoiceRepository)
            ..add(const FetchAllInvoicesEvent());
        },
        key: key(),
      ),
      BlocProvider(
        create: (context) {
          _orderListBloc?.close();

          return _orderListBloc = OrderListBloc(_orderRepository) //
            ..add(const FetchAllOrdersEvent());
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
    }

    _userListBloc?.add(const LoadAllUsersEvent());
    _productListBloc?.add(const LoadAllProductsEvent());
    _invoiceListBloc?.add(const FetchAllInvoicesEvent());
    _categoryListBloc?.add(const LoadCategoriesEvent());
    _unitListBloc?.add(const LoadUnitsEvent());
    _userLogListBloc?.add(const LoadUserLogsEvent());
    _securityQuestionListBloc?.add(const FetchSecurityQuestionsEvent());
  }
}
