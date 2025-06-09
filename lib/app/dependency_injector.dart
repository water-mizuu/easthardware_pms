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

class DependencyInjector extends ChangeNotifier {
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
  late DateTime? _lastUpdated;

  void initialize({DatabaseHelper? databaseHelper}) {
    _databaseHelper = databaseHelper;
    _lastUpdated = DateTime.now();

    _authenticationRepository = AuthenticationRepository(databaseHelper);
    _productRepository = ProductRepository(databaseHelper);
    _invoiceRepository = InvoiceRepository(databaseHelper);
    _orderRepository = OrderRepository(databaseHelper);
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
      Provider.value(value: BottomTextNotifier(bottomText)),
      BlocProvider.value(value: serverBloc),
      RepositoryProvider.value(value: _categoryRepository),
      RepositoryProvider.value(value: _productRepository),
      RepositoryProvider.value(value: _unitRepository),
      RepositoryProvider.value(value: _userRepository),
      BlocProvider(
        key: key(),
        create: (_) => AuthenticationBloc(_authenticationRepository),
      ),
      BlocProvider(create: (context) => NavigationCubit()),
      BlocProvider(
        lazy: false,
        key: key(),
        create: (context) {
          final bloc = UserListBloc(_userRepository);
          if (_databaseHelper != null) {
            bloc.add(const LoadAllUsersEvent());
          }

          return bloc;
        },
      ),
      BlocProvider(
        key: key(),
        create: (context) => ProductListBloc(_productRepository) //
          ..add(const LoadAllProductsEvent()),
      ),
      BlocProvider(
        key: key(),
        create: (context) => CategoryListBloc(_categoryRepository) //
          ..add(const LoadCategoriesEvent()),
      ),
      BlocProvider(
        key: key(),
        create: (context) => UnitListBloc(_unitRepository) //
          ..add(const LoadUnitsEvent()),
      ),
      BlocProvider(
        key: key(),
        create: (context) => UserLogListBloc(_userLogRepository) //
          ..add(const LoadUserLogsEvent()),
      ),
      BlocProvider(
        key: key(),
        create: (context) => SecurityQuestionListBloc(_securityQuestionRepository)
          ..add(const FetchSecurityQuestionsEvent()),
      ),
      BlocProvider(
        key: key(),
        create: (context) => ResetFormBloc(
          userRepository: _userRepository,
          securityQuestionRepository: _securityQuestionRepository,
        ),
      ),
      BlocProvider(
        key: key(),
        create: (context) => NewPasswordFormBloc(userRepository: _userRepository),
      ),
      BlocProvider(
        key: key(),
        create: (context) => InvoiceListBloc(_invoiceRepository) //
          ..add(const FetchAllInvoicesEvent()),
      ),
      BlocProvider(
        key: key(),
        create: (context) => OrderListBloc(_orderRepository) //
          ..add(const FetchAllOrdersEvent()),
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
