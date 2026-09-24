import '../../models/baby_profile.dart';

/// Abstract so the mock (in-memory) and future Firestore implementations
/// are interchangeable behind the same interface.
abstract class BabyRepository {
  Stream<List<BabyProfile>> watchBabies();
  Future<BabyProfile?> getBaby(String id);
  /// Returns the new baby's id, so callers can select it immediately.
  Future<String> addBaby(BabyProfile baby);
  Future<void> updateBaby(BabyProfile baby);
  Future<void> deleteBaby(String babyId);
}
