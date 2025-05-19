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
import 'package:easthardware_pms/presentation/bloc/security/securityquestions/security_question_list_bloc.dart';
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

  Future<void> init([DatabaseHelper? databaseHelper]) async {
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
      BlocProvider(create: (context) => AuthenticationBloc(_authenticationRepository)),
      BlocProvider(create: (context) => NavigationBloc()),
      BlocProvider(create: (context) => UserListBloc(_userRepository)..add(LoadAllUsersEvent())),
      BlocProvider(
          create: (context) => ProductListBloc(_productRepository)..add(LoadAllProductsEvent())),
      BlocProvider(
          create: (context) => CategoryListBloc(_categoryRepository)..add(LoadCategoriesEvent())),
      BlocProvider(create: (context) => UnitListBloc(_unitRepository)..add(LoadUnitsEvent())),
      BlocProvider(
          create: (context) => UserLogListBloc(_userLogRepository)..add(LoadUserLogsEvent())),
      BlocProvider(
          create: (context) => SecurityQuestionListBloc(_securityQuestionRepository)
            ..add(const FetchSecurityQuestionsEvent())),
    ];
  }
}
