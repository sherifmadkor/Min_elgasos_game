// lib/data/repositories/auth_repository.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository to encapsulate FirebaseAuth + Firestore user doc lifecycle.
/// - Creates a users/{uid} document on sign up
/// - Keeps a basic presence flag (isOnline) when signing in/out
/// - Exposes auth/user streams and common actions
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    String usersCollectionPath = 'users',
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _usersCollectionPath = usersCollectionPath;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final String _usersCollectionPath;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection(_usersCollectionPath);

  /// Public streams/helpers
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Stream<DocumentSnapshot<Map<String, dynamic>>?> currentUserDocStream() {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return const Stream<DocumentSnapshot<Map<String, dynamic>>?>.empty();
      return _usersRef.doc(user.uid).snapshots();
    });
  }

  String? get currentUid => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  /// Creates an auth user, updates displayName, and ensures Firestore users/{uid} exists.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'تعذر إنشاء المستخدم. حاول مرة أخرى.',
        );
      }

      // Update profile (optional but recommended)
      await user.updateDisplayName(displayName.trim());
      await user.reload();

      // Create/merge Firestore user doc
      await _ensureUserDoc(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        // when created via signUp, assume they are currently online
        isOnline: true,
      );

      return cred;
    } on FirebaseAuthException {
      rethrow; // Let UI show e.message
    } on FirebaseException {
      rethrow;
    } catch (e) {
      // Wrap into a generic FirebaseException for consistency
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'حدث خطأ غير متوقع أثناء إنشاء الحساب: $e',
      );
    }
  }

  /// Signs in and marks the user as online in Firestore.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'internal-error',
          message: 'تعذر تسجيل الدخول. حاول مرة أخرى.',
        );
      }

      // Ensure doc exists (handles users created via other providers, etc.)
      await _ensureUserDoc(
        uid: user.uid,
        email: user.email ?? email.trim(),
        displayName: user.displayName ?? '',
        isOnline: true,
      );

      return cred;
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'حدث خطأ غير متوقع أثناء تسجيل الدخول: $e',
      );
    }
  }

  /// Signs out and marks the user offline.
  Future<void> signOut() async {
    final uid = currentUid;
    try {
      if (uid != null) {
        await _usersRef.doc(uid).set(
          {
            'isOnline': false,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Best effort: don't block signOut on a failed Firestore write
    } finally {
      await _auth.signOut();
    }
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sends email verification to the currently signed-in user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'لا يوجد مستخدم حالي.',
      );
    }
    await user.sendEmailVerification();
  }

  /// Updates display name and/or photo URL in FirebaseAuth + Firestore.
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'لا يوجد مستخدم حالي.',
      );
    }

    if (displayName != null) {
      await user.updateDisplayName(displayName.trim());
    }
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
    await user.reload();

    // Mirror to Firestore
    await _usersRef.doc(user.uid).set(
      {
        if (displayName != null) 'displayName': displayName.trim(),
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Updates arbitrary user fields in Firestore.
  Future<void> updateUserDoc(Map<String, dynamic> data, {String? uid}) async {
    final targetUid = uid ?? currentUid;
    if (targetUid == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'لا يوجد مستخدم حالي.',
      );
    }
    await _usersRef.doc(targetUid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Deletes both Firestore user doc and Auth user.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'لا يوجد مستخدم حالي.',
      );
    }

    // Delete Firestore doc first
    try {
      await _usersRef.doc(user.uid).delete();
    } catch (_) {
      // If it fails, continue to delete Auth account anyway.
    }

    await user.delete();
  }

  /// Gets the current Firestore user doc data (or null if not found/not signed in).
  Future<Map<String, dynamic>?> fetchCurrentUserDoc() async {
    final uid = currentUid;
    if (uid == null) return null;
    final snap = await _usersRef.doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  /// INTERNAL: Ensure a users/{uid} doc exists with a consistent schema.
  Future<void> _ensureUserDoc({
    required String uid,
    required String email,
    required String displayName,
    bool isOnline = false,
  }) async {
    final docRef = _usersRef.doc(uid);
    final doc = await docRef.get();

    // Base schema
    final base = <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': 'member', // adjust to your roles
      'tier': 'free',   // free/vip/admin etc.
      'isOnline': isOnline,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (doc.exists) {
      // Merge minimal updates if doc already exists
      await docRef.set(base, SetOptions(merge: true));
    } else {
      await docRef.set({
        ...base,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

/// Simple Rx switchMap without importing rxdart.
/// You can remove this if you already use rxdart's .switchMap.
extension _SwitchMapExt<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T value) mapper) {
    StreamController<R>? controller;
    StreamSubscription<T>? parentSub;
    StreamSubscription<R>? childSub;

    void onData(T value) {
      childSub?.cancel();
      childSub = mapper(value).listen(
        controller!.add,
        onError: controller!.addError,
      );
    }

    void onDone() {
      controller?.close();
    }

    void onListen() {
      parentSub = this.listen(onData,
          onError: controller!.addError, onDone: onDone, cancelOnError: false);
    }

    void onCancel() async {
      await childSub?.cancel();
      await parentSub?.cancel();
    }

    controller = StreamController<R>(
      onListen: onListen,
      onCancel: onCancel,
    );
    return controller!.stream;
  }
}
