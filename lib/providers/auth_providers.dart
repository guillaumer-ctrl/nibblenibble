import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase/firebase_auth_repository.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
