import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/app/bottom_text.dart';
import 'package:easthardware_pms/app/dependency_injector.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/userloglist/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final AsyncQueue asyncQueue = AsyncQueue.autoStart();
  late final GlobalKey<NavigatorState> rootKey = GlobalKey();
  late final ValueNotifier<String> bottomText = ValueNotifier<String>("");

  late final GoRouter _router = router(rootKey);
  late final ServerBloc serverBloc;
  late DatabaseHelper? databaseHelper;
  late DependencyInjector di;

  List<SingleChildWidget> get providers {
    return [
      ...di.inject(),
      BlocProvider.value(value: serverBloc),
      Provider.value(value: BottomTextNotifier(bottomText)),
    ];
  }

  List<SingleChildWidget> get blocListeners {
    return [
      BlocListener<ServerBloc, ServerState>(
        bloc: serverBloc,
        listenWhen: (p, c) => p.databaseHelper != c.databaseHelper,
        listener: (context, state) async {
          databaseHelper = state.databaseHelper;
          await di.initialize(databaseHelper);
          if (!mounted || !context.mounted) return;

          setState(() {});
        },
      ),
      BlocListener<ServerBloc, ServerState>(
        bloc: serverBloc,
        listenWhen: (p, c) => p.lastUpdated != c.lastUpdated,
        listener: (context, state) {
          di.markNeedsRefresh();
        },
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    di = DependencyInjector();
    di.initialize(null);

    serverBloc = ServerBloc(rootKey, bottomText)..add(const ServerInit());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      final user = context.read<AuthenticationBloc>().state.user;
      if (user != null) {
        context.read<UserLogListBloc>().add(AddLogoutEvent(user));
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    serverBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MultiBlocListener(
        listeners: blocListeners,
        child: FluentApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          themeMode: ThemeMode.light,
          theme: FluentThemeData(micaBackgroundColor: Colors.grey[10]),
        ),
      ),
    );
  }
}
