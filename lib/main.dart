import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope is the root of the dependency graph — every provider,
    // including the SQLite connection, is resolved from here.
    const ProviderScope(child: QualihiveApp()),
  );
}
