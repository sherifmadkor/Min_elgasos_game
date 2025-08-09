// lib/screens/create_account_screen.dart
import 'package:flutter/material.dart';
import 'package:min_elgasos_game/app_theme.dart';
import 'package:min_elgasos_game/widgets/background_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:min_elgasos_game/slide_transition.dart';
import 'package:min_elgasos_game/screens/online_lobby_screen.dart';

// A simple model for our user profile data
class UserProfile {
  final String uid;
  final String username;
  final String avatar;

  UserProfile({required this.uid, required this.username, required this.avatar});

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'avatar': avatar,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedAvatar;
  final List<String> freeEmojis = ['😀', '😎', '😜', '👻', '🤖'];
  final List<String> paidEmojis = ['👑', '😈', '🤠', '👽', '💀'];

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_formKey.currentState?.validate() == false || _selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إكمال جميع البيانات واختيار صورة رمزية')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Register user with email and password using Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = userCredential.user;

      if (user != null) {
        // 2. Create a UserProfile object
        final userProfile = UserProfile(
          uid: user.uid,
          username: _usernameController.text.trim(),
          avatar: _selectedAvatar!,
        );

        // 3. Save the user profile to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userProfile.toFirestore());

        // 4. Navigate to the online lobby
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            createSlideRoute(const OnlineLobbyScreen()),
                (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جداً. يرجى اختيار كلمة أقوى.';
      } else if (e.code == 'email-already-in-use') {
        message = 'هذا البريد الإلكتروني مُستخدم بالفعل.';
      } else {
        message = 'حدث خطأ. يرجى المحاولة مرة أخرى.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ غير متوقع.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حساب'),
          centerTitle: true,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('البريد الإلكتروني:', style: AppTheme.textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    _buildTextField(_emailController, 'ادخل بريدك الإلكتروني', false, (value) {
                      if (value == null || !value.contains('@')) {
                        return 'الرجاء إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    }),
                    const SizedBox(height: 20),
                    Text('كلمة المرور:', style: AppTheme.textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    _buildTextField(_passwordController, 'ادخل كلمة المرور', true, (value) {
                      if (value == null || value.length < 6) {
                        return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                      }
                      return null;
                    }),
                    const SizedBox(height: 20),
                    Text('اختر اسم المستخدم:', style: AppTheme.textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    _buildTextField(_usernameController, 'ادخل اسمك', false, (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم المستخدم';
                      }
                      return null;
                    }),
                    const SizedBox(height: 30),
                    Text('اختر صورتك الرمزية (أفاتار):', style: AppTheme.textTheme.bodyLarge),
                    const SizedBox(height: 15),
                    _buildAvatarGrid(context),
                    const SizedBox(height: 40),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                        : CoolButton(
                      text: 'إنشاء الحساب والبدء',
                      onPressed: _createAccount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(TextEditingController controller, String hintText, bool isPassword, String? Function(String?) validator) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTheme.textTheme.bodyMedium,
        filled: true,
        fillColor: AppTheme.surfaceColor.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        errorStyle: AppTheme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent, fontSize: 12),
      ),
      style: AppTheme.textTheme.bodyLarge,
      textAlign: TextAlign.right,
      validator: validator,
    );
  }

  Widget _buildAvatarGrid(BuildContext context) {
    // This part remains the same as before
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: freeEmojis.length,
      itemBuilder: (context, index) {
        final emoji = freeEmojis[index];
        return _buildAvatarItem(emoji);
      },
    ),
    const SizedBox(height: 20),
    const Divider(color: AppTheme.textSecondaryColor, thickness: 1),
    const SizedBox(height: 20),
    Text('صور رمزية مميزة (قريباً)',
    style: AppTheme.textTheme.bodyLarge?.copyWith(
    color: AppTheme.textSecondaryColor.withOpacity(0.5),
    ),
    textAlign: TextAlign.right),
    const SizedBox(height: 15),
    GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 5,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    ),
    itemCount: paidEmojis.length,
    itemBuilder: (context, index) {
    final emoji = paidEmojis[index];
    return _buildAvatarItem(emoji, isLocked: true);
    },
    ),
    ],
    );
  }

  Widget _buildAvatarItem(String emoji, {bool isLocked = false}) {
    // This part remains the same as before
    final bool isSelected = _selectedAvatar == emoji;
    return GestureDetector(
      onTap: isLocked ? null : () {
        setState(() {
          _selectedAvatar = emoji;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? AppTheme.surfaceColor.withOpacity(0.3) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: AppTheme.accentColor, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              if (isLocked)
                Icon(
                  Icons.lock_rounded,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  size: 40,
                ),
            ],
          ),
        ),
      ),
    );
  }
}