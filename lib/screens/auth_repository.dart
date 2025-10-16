import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Stream<DocumentSnapshot<Map<String, dynamic>>?> currentUserDocStream() {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return const Stream<DocumentSnapshot<Map<String, dynamic>>?>.empty();
      return _usersRef.doc(user.uid).snapshots();
    });
  }

  String? get currentUid => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

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

      await user.updateDisplayName(displayName.trim());
      await user.reload();

      await _ensureUserDoc(
        uid: user.uid,
        email: email.trim(),
        displayName: displayName.trim(),
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
        message: 'حدث خطأ غير متوقع أثناء إنشاء الحساب: $e',
      );
    }
  }

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

  Future<void> signOut() async {
    final uid = currentUid;
    try {
      if (uid != null) {
        await _usersRef.doc(uid).set(
          {'isOnline': false, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // best effort
    } finally {
      await _auth.signOut();
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'لا يوجد مستخدم حالي.');
    }
    await user.sendEmailVerification();
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'لا يوجد مستخدم حالي.');
    }
    if (displayName != null) await user.updateDisplayName(displayName.trim());
    if (photoURL != null) await user.updatePhotoURL(photoURL);
    await user.reload();

    await _usersRef.doc(user.uid).set(
      {
        if (displayName != null) 'displayName': displayName.trim(),
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserDoc(Map<String, dynamic> data, {String? uid}) async {
    final targetUid = uid ?? currentUid;
    if (targetUid == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'لا يوجد مستخدم حالي.');
    }
    await _usersRef.doc(targetUid).set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'لا يوجد مستخدم حالي.');
    }
    try {
      await _usersRef.doc(user.uid).delete();
    } catch (_) {
      // ignore
    }
    await user.delete();
  }

  Future<Map<String, dynamic>?> fetchCurrentUserDoc() async {
    final uid = currentUid;
    if (uid == null) return null;
    final snap = await _usersRef.doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  Future<void> _ensureUserDoc({
    required String uid,
    required String email,
    required String displayName,
    bool isOnline = false,
  }) async {
    final docRef = _usersRef.doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // If document exists, only update specific fields without overwriting avatar
      await docRef.set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Only set defaults for new users
      await docRef.set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'avatarEmoji': '🕵️‍♂️',
        'role': 'member',
        'tier': 'free',
        'rank': 'Iron',
        'xp': 0,
        'stats': {
          'gamesPlayed': 0,
          'wins': 0,
          'losses': 0,
          'spyWins': 0,
          'detectiveWins': 0,
        },
        'isOnline': isOnline,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

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

    void onDone() => controller?.close();

    void onListen() {
      parentSub = this.listen(onData,
          onError: controller!.addError, onDone: onDone, cancelOnError: false);
    }

    Future<void> onCancel() async {
      await childSub?.cancel();
      await parentSub?.cancel();
    }

    controller = StreamController<R>(onListen: onListen, onCancel: onCancel);
    return controller!.stream;
  }
}
