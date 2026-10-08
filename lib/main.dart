import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app_theme.dart';
import 'src/auth_screen.dart';
import 'src/supplier_home.dart';
import 'src/supplier_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final raw = await rootBundle.loadString('assets/env.local.json');
  final config = jsonDecode(raw) as Map<String, dynamic>;
  await Supabase.initialize(
    url: config['SUPABASE_URL'] as String,
    publishableKey: config['SUPABASE_ANON_KEY'] as String,
  );
  runApp(const BarberSupplierApp());
}

class BarberSupplierApp extends StatelessWidget {
  const BarberSupplierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarBer Tedarikçi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SupplierAuthGate(),
    );
  }
}

class SupplierAuthGate extends StatefulWidget {
  const SupplierAuthGate({super.key});

  @override
  State<SupplierAuthGate> createState() => _SupplierAuthGateState();
}

class _SupplierAuthGateState extends State<SupplierAuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthScreen();
        return SupplierProfileGate(
          key: ValueKey('${session.user.id}-${snapshot.data?.event.name}'),
        );
      },
    );
  }
}

class SupplierProfileGate extends StatefulWidget {
  const SupplierProfileGate({super.key});

  @override
  State<SupplierProfileGate> createState() => _SupplierProfileGateState();
}

class _SupplierProfileGateState extends State<SupplierProfileGate> {
  late final SupplierRepository repository;
  late Future<SupplierProfile?> future;

  @override
  void initState() {
    super.initState();
    repository = SupplierRepository(Supabase.instance.client);
    future = repository.getMyProfile();
  }

  void reload() => setState(() => future = repository.getMyProfile());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SupplierProfile?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _BackendPendingScreen(error: snapshot.error, onRetry: reload);
        }
        final profile = snapshot.data;
        if (profile == null) {
          return SupplierApplicationScreen(
            repository: repository,
            onSaved: reload,
          );
        }
        return SupplierHome(
          repository: repository,
          profile: profile,
          onRefreshProfile: reload,
        );
      },
    );
  }
}

class _BackendPendingScreen extends StatelessWidget {
  const _BackendPendingScreen({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_sync_rounded,
                size: 72,
                color: AppTheme.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Tedarikçi altyapısı hazırlanıyor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Uygulama hazır. Tedarikçi veritabanı migration’ı canlıya alındıktan sonra hesabınızla devam edebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tekrar dene'),
              ),
              TextButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('Çıkış yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
