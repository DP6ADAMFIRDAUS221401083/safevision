import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    // 1. Create user in Firebase Authentication
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Save user data to Firestore
    try {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user',
        'isActive': true,
      });
    } catch (e) {
      // Throw custom exception if firestore fails
      throw Exception('auth-success-firestore-failed');
    }

    return userCredential;
  }

  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
