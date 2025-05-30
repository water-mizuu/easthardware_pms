import 'package:flutter/services.dart';

@pragma('vm:prefer-inline')
void assertMainIsolate() {
  assert(RootIsolateToken.instance != null, "This function should be run on the main isolate.");
}

@pragma('vm:prefer-inline')
void assertChildIsolate() {
  assert(RootIsolateToken.instance == null, "This function should be run on the main isolate.");
}
