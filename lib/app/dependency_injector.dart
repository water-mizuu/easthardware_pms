import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/category_repository.dart';
import 'package:easthardware_pms/data/repository/product_repository.dart';
import 'package:easthardware_pms/data/repository/security_question_repository.dart';
import 'package:easthardware_pms/data/repository/unit_repository.dart';
import 'package:easthardware_pms/data/repository/user_log_repository.dart';
import 'package:easthardware_pms/data/repository/user_repository.dart';
import 'package:easthardware_pms/domain/repository/authentication_repository.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';
import 'package:easthardware_pms/domain/repository/unit_repository.dart';
import 'package:easthardware_pms/domain/repository/user_log_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/categorylist/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/productlist/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unitlist/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/securityquestions/'
    'security_question_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/userlist/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/userloglist/user_log_list_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

class DependencyInjector {
  late AuthenticationRepository _authenticationRepository;
  late ProductRepository _productRepository;
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

  Future<void> initialize([DatabaseHelper? databaseHelper]) async {
    _databaseHelper = databaseHelper;
    _authenticationRepository = AuthenticationRepository(databaseHelper);
    _productRepository = ProductRepositoryImpl(databaseHelper);
    _categoryRepository = CategoryRepositoryImpl(databaseHelper);
    _unitRepository = UnitRepositoryImpl(databaseHelper);
    _userLogRepository = UserLogRepositoryImpl(databaseHelper);
    _userRepository = UserRepositoryImpl(databaseHelper);
    _securityQuestionRepository = SecurityQuestionRepositoryImpl(databaseHelper);
  }

  List<SingleChildWidget> inject() {
    if (kDebugMode) {
      print("Dependency Injector: Injecting dependencies");
    }

    return [
      RepositoryProvider.value(value: _categoryRepository),
      RepositoryProvider.value(value: _productRepository),
      RepositoryProvider.value(value: _unitRepository),
      BlocProvider(
        create: (context) => AuthenticationBloc(_authenticationRepository),
        key: ValueKey(_databaseHelper),
      ),
      BlocProvider(create: (context) => NavigationBloc(), key: ValueKey(_databaseHelper)),
      BlocProvider(
        create: (context) {
          _userListBloc?.close();

          return _userListBloc = UserListBloc(_userRepository)..add(LoadAllUsersEvent());
        },
        key: ValueKey(_databaseHelper),
      ),
      BlocProvider(
        create: (context) {
          _productListBloc?.close();

          return _productListBloc = ProductListBloc(_productRepository)
            ..add(LoadAllProductsEvent());
        },
        key: ValueKey(_databaseHelper),
      ),
      BlocProvider(
        create: (context) {
          _categoryListBloc?.close();

          return _categoryListBloc = CategoryListBloc(_categoryRepository)
            ..add(LoadCategoriesEvent());
        },
        key: ValueKey(_databaseHelper),
      ),
      BlocProvider(
        create: (context) {
          _unitListBloc?.close();

          return _unitListBloc = UnitListBloc(_unitRepository)..add(LoadUnitsEvent());
        },
        key: ValueKey(_databaseHelper),
      ),
      BlocProvider(
        create: (context) {
          _userLogListBloc?.close();

          return _userLogListBloc = UserLogListBloc(_userLogRepository)..add(LoadUserLogsEvent());
        },
        key: ValueKey(_databaseHelper),
      ),
      BlocProvider(
        create: (context) {
          _securityQuestionListBloc?.close();

          return _securityQuestionListBloc = SecurityQuestionListBloc(_securityQuestionRepository)
            ..add(const FetchSecurityQuestionsEvent());
        },
        key: ValueKey(_databaseHelper),
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
        _categoryListBloc,
        _unitListBloc,
        _userLogListBloc,
        _securityQuestionListBloc
      ]);
    }

    _userListBloc?.add(LoadAllUsersEvent());
    _productListBloc?.add(LoadAllProductsEvent());
    _categoryListBloc?.add(LoadCategoriesEvent());
    _unitListBloc?.add(LoadUnitsEvent());
    _userLogListBloc?.add(LoadUserLogsEvent());
    _securityQuestionListBloc?.add(const FetchSecurityQuestionsEvent());
  }
}
