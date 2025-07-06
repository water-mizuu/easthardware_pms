import 'package:easthardware_pms/domain/backend/server_host/web_socket_isolate.dart';
import 'package:easthardware_pms/utils/parallelism.dart';

sealed class InvocationContext {
  const InvocationContext({required this.sendPort});

  final NamedSendPort sendPort;

  ClientChannel? get clientChannel;
}

final class MainInvocationContext implements InvocationContext {
  const MainInvocationContext({required this.sendPort});

  @override
  final NamedSendPort sendPort;

  @override
  Null get clientChannel => null;
}

final class ClientInvocationContext implements InvocationContext {
  const ClientInvocationContext({
    required this.sendPort,
    required this.clientChannel,
  });

  @override
  final NamedSendPort sendPort;

  @override
  final ClientChannel clientChannel;
}
