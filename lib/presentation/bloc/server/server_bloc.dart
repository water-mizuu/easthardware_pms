import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/domain/backend/enum/database_mode.dart';
import 'package:easthardware_pms/domain/backend/extension_types/shelf_server.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/services/server_connection_service.dart'
    as connection_service;
import 'package:easthardware_pms/presentation/bloc/server/services/server_preferences_service.dart'
    as server_preferences;
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/client_connection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_configuration_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_mode_selection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_success_dialogs.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'server_event.dart';
part 'server_state.dart';

/// This is the server bloc that handles the server state and events.
///   It is responsible for managing the server connection and
///   prompting the user for server/client information.
class ServerBloc extends Bloc<ServerEvent, ServerState> {
  ServerBloc() : super(const ServerState(status: ServerStatus.initial)) {
    /// Logic paths:
    ///   read the persisting data.
    ///   if no data is found, prompt the user for server/client information.
    ///     after the user selects a mode, prompt for server/client information.
    ///     if the user selects server, host the server.
    ///     if the user selects client, connect to the server.
    ///   if data is found, load the server/client information.
    on<ServerReset>(_onReset);
    on<ServerInit>(_onInit);
    on<_ServerPromptingUserFromNull>(_onPromptingUserFromNull);

    on<_ServerPromptingClientInformation>(_onPromptingClientInformation);
    on<_ServerLoadingClientFromPreferences>(_onLoadingClientFromPreferences);

    on<_ServerPromptingServerInformation>(_onPromptingServerInformation);
    on<_ServerLoadingServerFromPreferences>(_onLoadingServerFromPreferences);

    on<_ServerClientConnectionEstablished>(_onClientConnectionEstablished);
    on<_ServerServerStarted>(_onServerStarted);

    on<_ServerSaveClientInformation>(_saveClientInformation);
    on<_ServerSaveServerInformation>(_saveServerInformation);

    on<ServerDatabaseUpdated>(_onDatabaseUpdated);
    on<_ServerResetBottomText>(_onResetBottomText);

    if (kDebugMode) {
      on<ServerDatabaseCleared>(_onServerDatabaseCleared);
      on<ServerMockDataAdded>(_onServerMockDataAdded);
    }
  }

  @override
  void onEvent(ServerEvent event) {
    if (kDebugMode) {
      print("[SERVER_BLOC] ${event.runtimeType}");
    }

    super.onEvent(event);
  }

  /// A helper method that connects to the server. It indicates that whenever the connection
  ///   is disposed, the server is reset.
  Future<(WebSocketChannel, MessageChannel, Stream<ServerEvent>)> _connectToServer(
    String serverIp,
    int port,
  ) async {
    return await connection_service.connectToWebSocketServer(
      serverIp,
      port,
      onConnectionClose: () {
        final innerContext = rootWidgetKey.currentContext;
        if (innerContext == null || !innerContext.mounted) return;
        if (kDebugMode) {
          printBoxed(
            "Connection to server at $serverIp:$port closed.",
            "ServerBloc",
          );
        }

        /// If the connection is closed, we reset the server state.
        ///   We also reset the authentication bloc.

        final authenticationBloc = innerContext.read<AuthenticationBloc>();
        if (authenticationBloc.state.user != null) {
          authenticationBloc.add(const AuthenticationLogoutEvent());
        }

        add(const ServerReset());
      },
    );
  }

  Future<void> _onReset(ServerReset event, Emitter<ServerState> emit) async {
    await server_preferences.resetSharedPreferences();

    add(const ServerInit());
  }

  Future<void> _onInit(ServerInit event, Emitter<ServerState> emit) async {
    /// Close any server or client connections that are open.
    if (state.databaseArgs case final ServerDatabaseArgs args) {
      await args.landingServer.close();
      await args.webSocketServer.close();
    } else if (state.databaseArgs case ClientDatabaseArgs(:final close?)) {
      await close();
    }

    /// Reset the state to initial.
    emit(const ServerState(status: ServerStatus.initial)
        .copyWith(status: ServerStatus.loading, bottomText: "Loading server data..."));

    /// Load the server data from the root key.
    switch (await server_preferences.getSavedDatabaseMode()) {
      case null:
        emit(state.copyWith(bottomText: "No saved data found. Prompting user..."));
        add(const _ServerPromptingUserFromNull());

        return;
      case DatabaseMode.client:
        emit(state.copyWith(bottomText: "Found existing client data."));

        final address = await server_preferences.getSavedServerAddress();
        if (address == null) {
          add(const _ServerPromptingServerInformation());
        } else {
          add(_ServerLoadingClientFromPreferences(
            address: address,
            popupToUser: true,
            saveToPreferences: true,
          ));
        }
      case DatabaseMode.server:
        final port = await server_preferences.getSavedServerPort();
        emit(state.copyWith(bottomText: "Found existing server data. $port"));

        if (port == null) {
          add(const _ServerPromptingServerInformation());
        } else {
          add(_ServerLoadingServerFromPreferences(port: port));
        }
    }
  }

  Future<void> _onPromptingUserFromNull(
    _ServerPromptingUserFromNull event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(status: ServerStatus.promptingUser));

    switch (await ServerModeSelectionDialog.show(rootWidgetKey.currentContext!)) {
      case _ when isClosed:
        return;
      case null:
        add(const _ServerPromptingUserFromNull());
      case DatabaseMode.client:
        emit(state.copyWith(
          status: ServerStatus.promptingClientInformation,
          bottomText: "Prompting for client information...",
        ));
        add(const _ServerPromptingClientInformation());
      case DatabaseMode.server:
        emit(state.copyWith(
          status: ServerStatus.promptingServerInformation,
          bottomText: "Server mode selected.",
        ));
        add(const _ServerPromptingServerInformation());
    }
  }

  Future<void> _onPromptingClientInformation(
    _ServerPromptingClientInformation event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.promptingClientInformation,
      databaseArgs: null,
      databaseHelper: null,
    ));
    final context = rootWidgetKey.currentContext!;

    await ClientConnectionDialog.show(
      onConnectToServer: _connectToServer,
      onCancel: () {
        Navigator.of(context).pop();

        add(const _ServerPromptingUserFromNull());
      },
      onConfirm: (messageChannel, databaseArgs) async {
        Navigator.of(context).pop();

        add(
          _ServerClientConnectionEstablished(
            saveToPreferences: true,
            popupToUser: true,
            args: databaseArgs,
          ),
        );
      },
    );
  }

  Future<void> _onLoadingClientFromPreferences(
    _ServerLoadingClientFromPreferences event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.loadingClient,
      databaseArgs: null,
      databaseHelper: null,
    ));

    try {
      final serverAddress = event.address;
      final [serverIp, portString] = serverAddress.split(":");
      final port = int.parse(portString);
      final (webSocket, message, stream) = await _connectToServer(serverIp, port);

      add(
        _ServerClientConnectionEstablished(
          saveToPreferences: event.saveToPreferences,
          popupToUser: false,
          args: ClientDatabaseArgs(
            parentIp: serverIp,
            port: port,
            webSocketChannel: webSocket,
            messageChannel: message,
            close: () async {
              await webSocket.sink.close();
            },
            stream: stream,
          ),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (kDebugMode) {
        print(e);
      }
      add(const _ServerPromptingClientInformation());
    }
  }

  Future<void> _onPromptingServerInformation(
    _ServerPromptingServerInformation event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.promptingServerInformation,
      databaseArgs: null,
      databaseHelper: null,
    ));

    try {
      final localIp = await connection_service.getLocalIpAddress();
      if (isClosed) return;

      await ServerConfigurationDialog.show(
        onStartServer: (port) => connection_service.startServers(port),
        onCancel: () => add(const _ServerPromptingUserFromNull()),
        onSuccess: (landing, webSocket, stream) {
          add(_ServerServerStarted(
            saveToPreferences: true,
            popupToUser: true,
            args: ServerDatabaseArgs(
              ip: localIp,
              port: landing.port,
              landingServer: landing,
              webSocketServer: webSocket,
              stream: stream,
            ),
          ));
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local IP or showing dialog: $e');
      }
      add(const _ServerPromptingUserFromNull());
    }
  }

  Future<void> _onLoadingServerFromPreferences(
    _ServerLoadingServerFromPreferences event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.loadingServer,
      databaseArgs: null,
      databaseHelper: null,
    ));

    final port = event.port;
    final localIp = await NetworkInfo().getWifiIP().then((p) => p!);
    if (isClosed) return;
    try {
      final (landing, webSocket, stream) = await connection_service.startServers(port);
      if (isClosed) return;

      add(_ServerServerStarted(
        saveToPreferences: event.saveToPreferences,
        popupToUser: false,
        args: ServerDatabaseArgs(
          ip: localIp,
          port: port,
          landingServer: landing,
          webSocketServer: webSocket,
          stream: stream,
        ),
      ));
    } on SocketException catch (e) {
      if (e.osError case OSError(errorCode: 48)) {
        /// If the port is already in use, we can either:
        ///   Connect to the existing server already running on that port.
        if (kDebugMode) {
          print("Port is already in use. Trying to connect to it.");
        }

        add(_ServerLoadingClientFromPreferences(
          address: '$localIp:$port',
          saveToPreferences: false,
          popupToUser: false,
        ));
      } else {
        add(const _ServerPromptingServerInformation());
      }
    }
  }

  Future<void> _onClientConnectionEstablished(
    _ServerClientConnectionEstablished event,
    Emitter<ServerState> emit,
  ) async {
    final address = '${event.args.parentIp}:${event.args.port}';
    emit(state.copyWith(bottomText: "Connected to: $address"));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    /// If we confirmed, stream the events to this bloc.
    event.args.stream?.listen(add);

    /// Let the user know that we are connected.
    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(event.args.messageChannel!)),
    ));

    if (event.popupToUser) {
      final didUserCancelCompleter = Completer<bool>();

      ClientConnectionSuccessDialog.show(
        context: rootWidgetKey.currentContext!,
        onCancel: () async {
          if (isClosed) return;
          emit(state.copyWith(bottomText: "Cancelled connection. Loading client data..."));
          didUserCancelCompleter.complete(true);
          Navigator.of(rootWidgetKey.currentContext!).pop();
          final args = state.databaseArgs as ClientDatabaseArgs;
          await args.close?.call();
          if (isClosed) return;

          add(const _ServerPromptingClientInformation());
        },
        onConfirm: () {
          // Dialog will be dismissed automatically
          Navigator.of(rootWidgetKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    if (event.saveToPreferences) {
      add(_ServerSaveClientInformation(serverAddress: address));
    }
  }

  /// This runs whenever a server is started.
  Future<void> _onServerStarted(_ServerServerStarted event, Emitter<ServerState> emit) async {
    final address = '${event.args.ip}:${event.args.port}';
    emit(state.copyWith(bottomText: "Hosting at: $address"));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    /// If we confirmed, start listening for events.
    event.args.stream.listen(add);

    /// We let the user know that the server is running.
    final channel = event.args.webSocketServer.channel;
    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(channel)),
    ));

    if (event.popupToUser) {
      final didUserCancelCompleter = Completer<bool>();
      ServerStartedSuccessDialog.show(
        serverIp: event.args.ip,
        port: event.args.port,
        onGoBack: () async {
          emit(state.copyWith(bottomText: "Cancelled server. Loading server data..."));
          didUserCancelCompleter.complete(true);
          Navigator.of(rootWidgetKey.currentContext!).pop();
          if (isClosed) return;

          final args = event.args;
          await args.landingServer.close();
          await args.webSocketServer.close();
          if (isClosed) return;

          add(const _ServerPromptingServerInformation());
        },
        onConfirm: () {
          Navigator.of(rootWidgetKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    if (event.saveToPreferences) {
      add(_ServerSaveServerInformation(port: event.args.port));
    }
  }

  Future<void> _saveClientInformation(
    _ServerSaveClientInformation event,
    Emitter<ServerState> emit,
  ) async {
    await server_preferences.saveClientInformation(event.serverAddress);
  }

  Future<void> _saveServerInformation(
    _ServerSaveServerInformation event,
    Emitter<ServerState> emit,
  ) async {
    await server_preferences.saveServerInformation(event.port);
  }

  Future<void> _onDatabaseUpdated(
    ServerDatabaseUpdated event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      lastUpdated: event.lastUpdated,
      bottomText: "Server updated at: ${event.lastUpdated.toLocal()}",
    ));

    Future.delayed(const Duration(seconds: 2), () {
      add(const _ServerResetBottomText());
    });
  }

  Future<void> _onResetBottomText(_ServerResetBottomText event, Emitter<ServerState> emit) async {
    if (state.databaseArgs case ServerDatabaseArgs(:final ip, :final port)) {
      emit(state.copyWith(
        bottomText: "Hosting at: $ip:$port",
      ));
    } else if (state.databaseArgs case ClientDatabaseArgs(:final parentIp, :final port)) {
      emit(state.copyWith(
        bottomText: "Connected to: $parentIp:$port",
      ));
    }
  }

  Future<void> _onServerDatabaseCleared(
    ServerDatabaseCleared event,
    Emitter<ServerState> emit,
  ) async {
    if (kDebugMode) {
      final databaseHelper = state.databaseHelper;
      if (databaseHelper == null) {
        print("Database helper is null, cannot clear database");
        showNotification(
          title: "Error",
          message: "Database helper is null",
          severity: InfoBarSeverity.error,
        );
        return;
      }

      if (databaseHelper.database case final ResettableDatabase database) {
        await database.reset();
        if (isClosed) return;

        add(ServerDatabaseUpdated(lastUpdated: DateTime.now()));
      }
    }
  }

  Future<void> _onServerMockDataAdded(
    ServerMockDataAdded event,
    Emitter<ServerState> emit,
  ) async {
    if (kDebugMode) {
      final databaseHelper = state.databaseHelper;
      if (databaseHelper == null) {
        print("Database helper is null, cannot add mock data");
        showNotification(
          title: "Error",
          message: "Database helper is null",
          severity: InfoBarSeverity.error,
        );
        return;
      }

      try {
        final usersRepository = UserRepository(databaseHelper);
        final securityQuestionsRepository = SecurityQuestionRepository(databaseHelper);

        final productsRepository = ProductRepository(databaseHelper);
        final categoryRepository = CategoryRepository(databaseHelper);

        /// Create users.
        var usersId = await usersRepository.getAllUsers().then((u) => u.length);

        const mockUsers = <MockUser>[
          (
            firstName: 'John',
            lastName: 'Doe',
            accessLevel: AccessLevel.staff,
            securityQuestions: [
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite color?',
                answer: 'Blue',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your pet\'s name?',
                answer: 'Buddy',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite food?',
                answer: 'Pizza',
              ),
            ],
          ),
          (
            firstName: 'Jane',
            lastName: 'Doe',
            accessLevel: AccessLevel.administrator,
            securityQuestions: [
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite color?',
                answer: 'Red',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your pet\'s name?',
                answer: 'Max',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite food?',
                answer: 'Sushi',
              ),
            ],
          ),
          (
            firstName: 'Alice',
            lastName: 'Smith',
            accessLevel: AccessLevel.staff,
            securityQuestions: [
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite color?',
                answer: 'Green',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your pet\'s name?',
                answer: 'Charlie',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite food?',
                answer: 'Pasta',
              ),
            ],
          ),
          (
            firstName: 'Bob',
            lastName: 'Johnson',
            accessLevel: AccessLevel.administrator,
            securityQuestions: [
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite color?',
                answer: 'Yellow',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your pet\'s name?',
                answer: 'Rocky',
              ),
              SecurityQuestion(
                userId: -1,
                question: 'What is your favorite food?',
                answer: 'Burger',
              ),
            ],
          )
        ];
        final securityQuestions = <SecurityQuestion>[];
        final users = <User>[];

        for (final mockUser in mockUsers) {
          final salt = CryptographyService.generateSalt();
          final user = User(
            id: usersId++,
            uid: const Uuid().v4(),
            firstName: mockUser.firstName,
            lastName: mockUser.lastName,
            username: '${mockUser.firstName.toLowerCase()}${mockUser.lastName.toLowerCase()}',
            accessLevel: mockUser.accessLevel,
            passwordHash: CryptographyService.generateHash(
              '${mockUser.firstName}${mockUser.lastName}123',
              salt,
            ),
            salt: salt,
            creationDate: '2022-01-01',
            archivedStatus: 0,
            loginStatus: 0,
          );

          /// Set the user ID for the security questions.
          for (final question in mockUser.securityQuestions) {
            securityQuestions.add(question.copyWith(userId: user.id!));
          }

          users.add(user);
          securityQuestions.addAll(mockUser.securityQuestions);
        }

        for (final user in users) {
          await usersRepository.insertUser(user);
        }

        usersId -= mockUsers.length;

        for (final question in securityQuestions) {
          await securityQuestionsRepository.addSecurityQuestion(question);
        }

        /// Create product categories
        const categories = [
          Category(name: "Hardware Tools"),
          Category(name: "Building Materials"),
          Category(name: "Plumbing"),
          Category(name: "Electrical"),
          Category(name: "Painting Supplies"),
          Category(name: "Safety & Security"),
          Category(name: "Automotive"),
        ];

        final categoryIds = <int>[];
        for (final category in categories) {
          final insertedCategory = await categoryRepository.insertCategory(category);
          categoryIds.add(insertedCategory.id!);
        }

        /// Create mock products (20 products)
        final mockProducts = [
          // Hardware Tools
          Product(
            sku: "HT-001",
            name: "Hammer - 16oz Claw",
            categoryId: categoryIds[0],
            description: "Standard 16oz claw hammer with fiberglass handle, "
                "suitable for general construction and household repairs.",
            salePrice: 450.00,
            orderCost: 280.00,
            quantity: 35.0,
            mainUnit: "piece",
            criticalLevel: 5.0,
            deadStockThreshold: 180.0,
            fastMovingStockThreshold: 15.0,
            creationDate: "2025-05-01",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),
          Product(
            sku: "HT-002",
            name: "Screwdriver Set - 10pc",
            categoryId: categoryIds[0],
            description: "10-piece screwdriver set with various "
                "sizes of flathead and Phillips head screwdrivers.",
            salePrice: 850.00,
            orderCost: 520.00,
            quantity: 20.0,
            mainUnit: "set",
            criticalLevel: 3.0,
            deadStockThreshold: 150.0,
            fastMovingStockThreshold: 8.0,
            creationDate: "2025-05-01",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),
          Product(
            sku: "HT-003",
            name: "Drill Machine - 650W",
            categoryId: categoryIds[0],
            description: "Heavy-duty 650W power drill with variable "
                "speed control, suitable for wood, metal, and concrete.",
            salePrice: 3200.00,
            orderCost: 1900.00,
            quantity: 12.0,
            mainUnit: "piece",
            criticalLevel: 2.0,
            deadStockThreshold: 120.0,
            fastMovingStockThreshold: 4.0,
            creationDate: "2025-05-01",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),

          // Building Materials
          Product(
            sku: "BM-001",
            name: "Cement - 40kg",
            categoryId: categoryIds[1],
            description: "40kg bag of Portland cement, suitable for "
                "concrete mixing and general construction.",
            salePrice: 320.00,
            orderCost: 240.00,
            quantity: 150.0,
            mainUnit: "bag",
            criticalLevel: 20.0,
            deadStockThreshold: 90.0,
            fastMovingStockThreshold: 30.0,
            creationDate: "2025-05-02",
            creatorId: usersId + 2,
            archivedStatus: 0,
          ),
          Product(
            sku: "BM-002",
            name: "Construction Sand - 50kg",
            categoryId: categoryIds[1],
            description: "50kg bag of washed construction sand for concrete mixing.",
            salePrice: 130.00,
            orderCost: 85.00,
            quantity: 200.0,
            mainUnit: "bag",
            criticalLevel: 30.0,
            deadStockThreshold: 120.0,
            fastMovingStockThreshold: 40.0,
            creationDate: "2025-05-02",
            creatorId: usersId + 2,
            archivedStatus: 0,
          ),

          // Plumbing
          Product(
            sku: "PL-001",
            name: "PVC Pipe - 1/2\" x 3m",
            categoryId: categoryIds[2],
            description: "3-meter length of 1/2-inch PVC pipe for residential plumbing.",
            salePrice: 95.00,
            orderCost: 60.00,
            quantity: 80.0,
            mainUnit: "length",
            criticalLevel: 10.0,
            deadStockThreshold: 100.0,
            fastMovingStockThreshold: 20.0,
            creationDate: "2025-05-03",
            creatorId: usersId + 3,
            archivedStatus: 0,
          ),
          Product(
            sku: "PL-002",
            name: "Basin Wrench",
            categoryId: categoryIds[2],
            description: "Adjustable basin wrench for tight spaces under sinks.",
            salePrice: 550.00,
            orderCost: 350.00,
            quantity: 15.0,
            mainUnit: "piece",
            criticalLevel: 3.0,
            deadStockThreshold: 120.0,
            fastMovingStockThreshold: 5.0,
            creationDate: "2025-05-03",
            creatorId: usersId + 3,
            archivedStatus: 0,
          ),
          Product(
            sku: "PL-003",
            name: "Toilet Flush Mechanism",
            categoryId: categoryIds[2],
            description: "Universal toilet tank flush valve replacement kit.",
            salePrice: 380.00,
            orderCost: 220.00,
            quantity: 25.0,
            mainUnit: "set",
            criticalLevel: 5.0,
            deadStockThreshold: 90.0,
            fastMovingStockThreshold: 8.0,
            creationDate: "2025-05-03",
            creatorId: usersId + 3,
            archivedStatus: 0,
          ),

          // Electrical
          Product(
            sku: "EL-001",
            name: "Extension Cord - 5m",
            categoryId: categoryIds[3],
            description: "5-meter heavy-duty extension cord with 3 outlets.",
            salePrice: 420.00,
            orderCost: 265.00,
            quantity: 30.0,
            mainUnit: "piece",
            criticalLevel: 5.0,
            deadStockThreshold: 100.0,
            fastMovingStockThreshold: 10.0,
            creationDate: "2025-05-04",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),
          Product(
            sku: "EL-002",
            name: "LED Bulb - 9W",
            categoryId: categoryIds[3],
            description: "9W LED light bulb, warm white, E27 base.",
            salePrice: 75.00,
            orderCost: 45.00,
            quantity: 100.0,
            mainUnit: "piece",
            criticalLevel: 15.0,
            deadStockThreshold: 150.0,
            fastMovingStockThreshold: 25.0,
            creationDate: "2025-05-04",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),
          Product(
            sku: "EL-003",
            name: "Circuit Breaker - 15A",
            categoryId: categoryIds[3],
            description: "15-amp single-pole circuit breaker for residential panels.",
            salePrice: 250.00,
            orderCost: 150.00,
            quantity: 40.0,
            mainUnit: "piece",
            criticalLevel: 8.0,
            deadStockThreshold: 120.0,
            fastMovingStockThreshold: 12.0,
            creationDate: "2025-05-04",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),

          // Painting Supplies
          Product(
            sku: "PS-001",
            name: "Interior Paint - 1 Gallon",
            categoryId: categoryIds[4],
            description: "Premium interior latex paint, white, 1 gallon.",
            salePrice: 1150.00,
            orderCost: 720.00,
            quantity: 25.0,
            mainUnit: "gallon",
            criticalLevel: 5.0,
            deadStockThreshold: 90.0,
            fastMovingStockThreshold: 8.0,
            creationDate: "2025-05-05",
            creatorId: usersId + 2,
            archivedStatus: 0,
          ),

          Product(
            sku: "PS-002",
            name: "Paint Roller Set",
            categoryId: categoryIds[4],
            description: "9-inch roller with frame and tray.",
            salePrice: 280.00,
            orderCost: 170.00,
            quantity: 35.0,
            mainUnit: "set",
            criticalLevel: 7.0,
            deadStockThreshold: 100.0,
            fastMovingStockThreshold: 10.0,
            creationDate: "2025-05-05",
            creatorId: usersId + 2,
            archivedStatus: 0,
          ),

          // Safety & Security
          Product(
            sku: "SS-001",
            name: "Door Lock Set",
            categoryId: categoryIds[5],
            description: "Deadbolt and handle set for exterior doors.",
            salePrice: 1350.00,
            orderCost: 850.00,
            quantity: 18.0,
            mainUnit: "set",
            criticalLevel: 4.0,
            deadStockThreshold: 120.0,
            fastMovingStockThreshold: 6.0,
            creationDate: "2025-05-06",
            creatorId: usersId + 3,
            archivedStatus: 0,
          ),
          Product(
            sku: "SS-002",
            name: "Smoke Detector",
            categoryId: categoryIds[5],
            description: "Battery-operated smoke detector with test button.",
            salePrice: 650.00,
            orderCost: 400.00,
            quantity: 30.0,
            mainUnit: "piece",
            criticalLevel: 6.0,
            deadStockThreshold: 150.0,
            fastMovingStockThreshold: 9.0,
            creationDate: "2025-05-06",
            creatorId: usersId + 3,
            archivedStatus: 0,
          ),
          Product(
            sku: "SS-003",
            name: "Work Gloves",
            categoryId: categoryIds[5],
            description: "Heavy-duty leather work gloves, medium size.",
            salePrice: 180.00,
            orderCost: 110.00,
            quantity: 50.0,
            mainUnit: "pair",
            criticalLevel: 10.0,
            deadStockThreshold: 120.0,
            fastMovingStockThreshold: 15.0,
            creationDate: "2025-05-06",
            creatorId: usersId + 3,
            archivedStatus: 0,
          ),

          // Automotive
          Product(
            sku: "AU-001",
            name: "Motor Oil - 1L",
            categoryId: categoryIds[6],
            description: "Synthetic motor oil 10W-30, 1 liter.",
            salePrice: 420.00,
            orderCost: 260.00,
            quantity: 45.0,
            mainUnit: "bottle",
            criticalLevel: 8.0,
            deadStockThreshold: 100.0,
            fastMovingStockThreshold: 12.0,
            creationDate: "2025-05-07",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),
          Product(
            sku: "AU-002",
            name: "Windshield Wiper - 18\"",
            categoryId: categoryIds[6],
            description: "18-inch universal windshield wiper blade.",
            salePrice: 220.00,
            orderCost: 135.00,
            quantity: 40.0,
            mainUnit: "piece",
            criticalLevel: 10.0,
            deadStockThreshold: 150.0,
            fastMovingStockThreshold: 15.0,
            creationDate: "2025-05-07",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),
          Product(
            sku: "AU-003",
            name: "Car Battery",
            categoryId: categoryIds[6],
            description: "12V car battery, 60Ah capacity.",
            salePrice: 3650.00,
            orderCost: 2400.00,
            quantity: 12.0,
            mainUnit: "piece",
            criticalLevel: 3.0,
            deadStockThreshold: 90.0,
            fastMovingStockThreshold: 4.0,
            creationDate: "2025-05-07",
            creatorId: usersId + 1,
            archivedStatus: 0,
          ),
        ];
        // Add products to the database
        final productIds = <int>[];
        for (final product in mockProducts) {
          final insertedProduct = await productsRepository.insertProduct(product);

          productIds.add(insertedProduct.id!);
        }

        // Create invoice repositories
        final invoiceRepository = InvoiceRepository(databaseHelper);
        final invoiceProductRepository = InvoiceProductRepository(databaseHelper);

        /// Create mock invoices
        final mockCustomers = [
          // Original customers
          "Maria Santos",
          "Juan Dela Cruz",
          "Andres Bonifacio",
          "Emilio Aguinaldo",
          "Gabriela Silang",
          "Jose Rizal",
          "Rodrigo Martinez",
          "Corazon Aquino",
          "Efren Reyes",
          "Manny Pacquiao",

          // Additional customers for more invoices
          "Fernando Lopez",
          "Diana Garcia",
          "Carlos Mendoza",
          "Elena Reyes",
          "Miguel Tan",
          "Sofia Cruz",
          "Rafael Villanueva",
          "Victoria Lim",
          "Eduardo Santos",
          "Isabella Ramos",

          // More customers for 50 invoices
          "Ricardo Dalisay",
          "Margarita Reyes",
          "Antonio Manahan",
          "Luzviminda Cruz",
          "Pedro Morales",
          "Divina Santos",
          "Roberto Gonzales",
          "Thelma Pineda",
          "Leandro Torres",
          "Josephine Ocampo",
          "Renato Macaraeg",
          "Carmen Bautista",
          "Alejandro Villanueva",
          "Lourdes Quiambao",
          "Emmanuel Torres",
          "Rosario Reyes",
          "Francisco Santos",
          "Aurora Dimaculangan",
          "Benito Reyes",
          "Milagros Soriano",
          "Gerardo Limcangco",
          "Corazon Enriquez",
          "Reynaldo Bautista",
          "Angelina Reyes",
          "Rogelio Marquez",
          "Zenaida Aquino",
          "Marcelo Domingo",
          "Cecilia Magallanes",
          "Teodoro Ramos",
          "Remedios Legaspi"
        ];
        final today = DateTime(2025, 6, 13); // Current date is June 13, 2025

        // Create 62 invoices with different dates spanning the last 90 days, with more concentration in recent weeks
        final mockInvoices = <Invoice>[];

        // Define the current date as June 16, 2025 (3 days after the previously defined 'today')
        final currentDate = DateTime(2025, 6, 16);

        // First add the original 50 invoices
        for (var i = 0; i < 50; i++) {
          // Date distribution logic:
          // - First 15 invoices: from last 7 days (higher density in the most recent week)
          // - Next 20 invoices: from last 30 days
          // - Remaining 15 invoices: spread over 90 days
          DateTime invoiceDate;

          if (i < 15) {
            // Last 7 days, with multiple invoices on some days
            invoiceDate = today.subtract(Duration(days: i % 7));
          } else if (i < 35) {
            // Last 30 days
            invoiceDate = today.subtract(Duration(days: 7 + (i - 15) % 23));
          } else {
            // Spread remaining invoices over 90 days
            invoiceDate = today.subtract(Duration(days: 30 + (i - 35) * 3));
          }
          // Payment date logic:
          // - 60% of invoices are paid on the same day (common for retail)
          // - 20% are paid 1-5 days later
          // - 20% are unpaid (especially more recent ones)      // Payment date logic with special handling for recent invoices
          final isVeryRecent = invoiceDate.isAfter(today.subtract(const Duration(days: 3)));

          // Determine payment date based on recency and patterns
          final paymentDate = (isVeryRecent && i % 3 == 0) || i % 5 == 0
              ? null // Unpaid for very recent invoices (33%) or generally 20% unpaid
              : (i % 3 == 0
                  ? invoiceDate.add(Duration(days: 1 + (i % 5))) // 20% paid later
                  : invoiceDate); // 60% paid same day
          final hasDiscount = i % 4 == 0; // 25% of invoices have discount
          final discountType = i % 8 == 0 ? DiscountType.value : DiscountType.percentage;
          final discountValue =
              discountType == DiscountType.percentage ? 5.0 + (i % 6) : 50.0 + (i * 10.0 % 100);

          // More varied memos
          final memos = [
            "Regular customer purchase",
            "Bulk order for construction project",
            "Monthly maintenance supplies",
            "Home renovation materials",
            "Emergency repair supplies",
            "Special order with custom pricing",
            "Contractor discount applied"
          ];

          final memo = i % 3 == 0 ? memos[i % memos.length] : null;

          final invoice = Invoice(
            customerName: mockCustomers[i],
            invoiceDate: invoiceDate,
            dueDate: invoiceDate.add(Duration(days: 15 + (i % 4) * 5)), // 15-30 days due
            paymentMethod: i % 3, // Rotate between payment methods (0=cash, 1=credit, 2=gcash)
            referenceNumber:
                "INV-${2025}${invoiceDate.month.toString().padLeft(2, '0')}${i.toString().padLeft(3, '0')}",
            memo: memo,
            discount: hasDiscount ? discountValue : null,
            discountType: discountType,
            creationDate: invoiceDate,
            paymentDate: paymentDate,
            amountDue: 0, // Will be calculated after adding products
            amountPaid: paymentDate != null ? 0 : null, // Will be updated after adding products
            creatorId: usersId + (i % users.length),
          );

          mockInvoices.add(invoice);
        }
        // Add invoices to the database
        for (final invoice in mockInvoices) {
          final insertedInvoice = await invoiceRepository.insertInvoice(invoice);
          final invoiceId =
              insertedInvoice.id!; // Add 1-8 random products to each invoice for more variety
          final customerIndex = mockInvoices.indexOf(invoice);
          final numberOfProducts = 1 +
              (invoiceId % 5) +
              (customerIndex >= 10
                  ? 3
                  : 0); // Between 1-5 products for first 10 invoices, 4-8 for others
          var totalAmount = 0.0;

          // Ensure we don't repeat products in the same invoice
          final selectedProducts = <int>{};

          for (var j = 0; j < numberOfProducts; j++) {
            // Select product from appropriate category based on invoice number
            // This creates more realistic grouping (customers tend to buy related items)
            final preferredCategoryIndex = (customerIndex % 7); // Base category on customer
            final offset = (invoiceId + j * 3) % mockProducts.length;

            // Find a product that hasn't been added to this invoice yet
            int productIndex;
            do {
              // Try to select a product from the preferred category if possible
              productIndex = mockProducts.indexWhere((p) =>
                  !selectedProducts.contains(mockProducts.indexOf(p)) &&
                  (j < 2 ? p.categoryId == categoryIds[preferredCategoryIndex] : true));

              // If no product found in preferred category or we've already added 2 from that category,
              // select any available product
              if (productIndex == -1) {
                productIndex = (offset + j + selectedProducts.length) % mockProducts.length;
              }
            } while (selectedProducts.contains(productIndex) &&
                selectedProducts.length < mockProducts.length);

            selectedProducts.add(productIndex);

            final product = mockProducts[productIndex];

            // More realistic quantities based on product type
            double quantity;
            if (product.mainUnit == "piece" || product.mainUnit == "set") {
              quantity = 1.0 + (j % 3); // 1-3 for piece/set items
            } else if (product.mainUnit == "bag" || product.mainUnit == "gallon") {
              quantity = 1.0 + (j % 2); // 1-2 for heavy items
            } else {
              quantity = 1.0 + (j % 5); // 1-5 for other items
            }

            final rate = product.salePrice;
            final amount = rate * quantity;
            totalAmount += amount;

            final invoiceProduct = InvoiceProduct(
              invoiceId: invoiceId,
              productId: productIds[productIndex],
              productName: product.name,
              description: product.description,
              quantity: quantity,
              rate: rate,
              amount: amount,
            );

            await invoiceProductRepository.insertInvoiceProduct(invoiceProduct);
          }

          // Update invoice with total amount
          final updatedInvoice = invoice.copyWith(
            id: invoiceId,
            amountDue: totalAmount,
            amountPaid: invoice.paymentDate != null ? totalAmount : null,
          );

          await invoiceRepository.updateInvoice(updatedInvoice);
        }

        // Add 12 more recent invoices including today's date (June 16, 2025) with multiple invoices on the same days
        // Additional customers for the new invoices
        final additionalCustomers = [
          "Lorenzo Villanueva",
          "Beatrice Santos",
          "Arturo Flores",
          "Patricia Castro",
          "Rolando De Leon",
          "Natividad Reyes",
          "Ernesto Bautista",
          "Carmela Gonzalez",
          "Danilo Cruz",
          "Leticia Diaz",
          "Benjamin Ramos",
          "Lolita Torres"
        ];

        // Create distribution of dates:
        // - 5 invoices today (June 16)
        // - 3 invoices yesterday (June 15)
        // - 2 invoices on June 14
        // - 2 invoices in between today and June 13

        final todaysDate = DateTime(2025, 6, 16); // Today's actual date (June 16, 2025)

        final recentDates = [
          todaysDate, // Today - June 16, 2025
          todaysDate, // Today
          todaysDate, // Today
          todaysDate, // Today
          todaysDate, // Today
          todaysDate.subtract(const Duration(days: 1)), // June 15
          todaysDate.subtract(const Duration(days: 1)), // June 15
          todaysDate.subtract(const Duration(days: 1)), // June 15
          todaysDate.subtract(const Duration(days: 2)), // June 14
          todaysDate.subtract(const Duration(days: 2)), // June 14
          todaysDate.subtract(const Duration(days: 3)), // June 13 (another one for this day)
          todaysDate.subtract(const Duration(days: 3)), // June 13 (another one for this day)
        ];

        for (var i = 0; i < 12; i++) {
          final invoiceDate = recentDates[i];

          // For recent invoices, 60% paid on same day, 40% unpaid (higher unpaid rate for more recent)
          final isPaidImmediately = i % 5 > 1; // 60% paid immediately
          final isToday = invoiceDate.day == todaysDate.day;

          // Most of today's invoices should be unpaid
          final paymentDate = (isToday && i < 3) || !isPaidImmediately
              ? null
              : invoiceDate; // paid on same day if paid at all

          final hasDiscount = i % 3 == 0; // 33% of invoices have discount
          final discountType = i % 6 == 0 ? DiscountType.value : DiscountType.percentage;
          final discountValue =
              discountType == DiscountType.percentage ? 5.0 + (i % 6) : 50.0 + (i * 15.0 % 100);

          final memos = [
            "Rush order",
            "Contractor materials",
            "Home improvement project",
            "Renovation supplies",
            "Special customer discount",
            "Large order with delivery"
          ];

          final memo = i % 2 == 0 ? memos[i % memos.length] : null;

          // Create unique reference numbers continuing from previous series
          final refNumber =
              "INV-${2025}${invoiceDate.month.toString().padLeft(2, '0')}${(i + 50).toString().padLeft(3, '0')}";

          final invoice = Invoice(
            customerName: additionalCustomers[i],
            invoiceDate: invoiceDate,
            dueDate: invoiceDate.add(Duration(days: 15 + (i % 4) * 5)),
            paymentMethod: i % 3,
            referenceNumber: refNumber,
            memo: memo,
            discount: hasDiscount ? discountValue : null,
            discountType: discountType,
            creationDate: invoiceDate,
            paymentDate: paymentDate,
            amountDue: 0, // Will be calculated after adding products
            amountPaid: paymentDate != null ? 0 : null,
            creatorId: usersId + (i % users.length),
          );

          final insertedInvoice = await invoiceRepository.insertInvoice(invoice);
          final invoiceId = insertedInvoice.id!;

          // More products in these recent invoices for better testing
          final numberOfProducts = 2 + (i % 4); // 2-5 products per invoice
          var totalAmount = 0.0;

          // Ensure we don't repeat products in the same invoice
          final selectedProducts = <int>{};

          for (var j = 0; j < numberOfProducts; j++) {
            // Select product from appropriate category
            final preferredCategoryIndex = (i + j) % 7; // Mix it up a bit

            // Find a product that hasn't been added to this invoice yet
            int productIndex;
            do {
              productIndex = mockProducts.indexWhere((p) =>
                  !selectedProducts.contains(mockProducts.indexOf(p)) &&
                  (j < 2 ? p.categoryId == categoryIds[preferredCategoryIndex] : true));

              if (productIndex == -1) {
                productIndex = ((i * 3) + j) % mockProducts.length;
              }
            } while (selectedProducts.contains(productIndex) &&
                selectedProducts.length < mockProducts.length);

            selectedProducts.add(productIndex);

            final product = mockProducts[productIndex];

            // Quantities - recent invoices tend to have higher quantities
            double quantity;
            if (product.mainUnit == "piece" || product.mainUnit == "set") {
              quantity = 1.0 + (j % 4); // 1-4 for piece/set items
            } else if (product.mainUnit == "bag" || product.mainUnit == "gallon") {
              quantity = 1.0 + (j % 3); // 1-3 for heavy items
            } else {
              quantity = 1.0 + (j % 5); // 1-5 for other items
            }

            final rate = product.salePrice;
            final amount = rate * quantity;
            totalAmount += amount;

            final invoiceProduct = InvoiceProduct(
              invoiceId: invoiceId,
              productId: productIds[productIndex],
              productName: product.name,
              description: product.description,
              quantity: quantity,
              rate: rate,
              amount: amount,
            );

            await invoiceProductRepository.insertInvoiceProduct(invoiceProduct);
          }

          // Update invoice with total amount
          final updatedInvoice = invoice.copyWith(
            id: invoiceId,
            amountDue: totalAmount,
            amountPaid: invoice.paymentDate != null ? totalAmount : null,
          );

          await invoiceRepository.updateInvoice(updatedInvoice);
        }

        showNotification(
          title: "Success",
          message: "Successfully added mock data to the database.",
          severity: InfoBarSeverity.success,
        );

        /// Let the main isolate know that we have added mock data.
        ///   and we should update the UI.
        add(ServerDatabaseUpdated(lastUpdated: DateTime.now()));
      } on Object {
        showNotification(
          title: "Error",
          message: "Failed to add mock data to the database.",
          severity: InfoBarSeverity.error,
        );
      }
    }
  }
}

typedef MockUser = ({
  String firstName,
  String lastName,
  AccessLevel accessLevel,
  List<SecurityQuestion> securityQuestions,
});
