/// Entry point for the TavernUp Flutter client.
///
/// This is the only place in the client that knows about concrete
/// infrastructure types. All dependencies are wired here and injected
/// via [ProviderScope] overrides — the rest of the app depends only
/// on interfaces from [tavernup_domain].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tavernup_auth_supabase/tavernup_auth_supabase.dart';

import 'src/infrastructure/websocket_realtime_transport.dart';
import 'src/state/auth_providers.dart';
import 'src/state/realtime_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final serverUrl = Uri.parse(const String.fromEnvironment(
    'TAVERNUP_SERVER_WS',
    defaultValue: 'ws://localhost:8080/ws',
  ));
  final transport = WebSocketRealtimeTransport(serverUrl);

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(
          SupabaseAuthService(Supabase.instance.client),
        ),
        realtimeTransportProvider.overrideWithValue(transport),
      ],
      child: const TavernUpApp(),
    ),
  );
}

class TavernUpApp extends ConsumerWidget {
  const TavernUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'TavernUp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Placeholder(),
    );
  }
}
