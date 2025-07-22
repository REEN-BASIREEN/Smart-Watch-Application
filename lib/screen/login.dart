import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // เพิ่ม Firebase Auth
import 'package:capstone_project/screen/signup.dart'; // นำเข้า SignupPage

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    try {
      // ใช้ Firebase Authentication สำหรับล็อกอิน
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // ล็อกอินสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Successful!')),
      );

      // นำผู้ใช้ไปยังหน้า HomePage
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // จัดการข้อผิดพลาด
      if (e.code == 'user-not-found') {
        _showErrorSnackBar('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        _showErrorSnackBar('Wrong password provided for that user.');
      } else {
        _showErrorSnackBar(e.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      // ข้อผิดพลาดทั่วไป
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFF0F1419),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/img/rmbio.png', // โลโก้หัวใจหรือสัญญาณชีพ
                height: 220,
                width: 300,
                // color: Color(0xFF008080),
              ),
              SizedBox(height: 16),
              Text(
                'Welcome to BIOSENTINEL',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE1E8ED)),
              ),
              SizedBox(height: 24),
              TextField(
                controller: _emailController,
                style: TextStyle(color: Color(0xFFE1E8ED)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color(0xFF8899A6)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF192734)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF192734)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1D9BF0)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                style: TextStyle(color: Color(0xFFE1E8ED)),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Color(0xFF8899A6)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF192734)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF192734)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1D9BF0)),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: Theme.of(context).elevatedButtonTheme.style,
                onPressed: _login,
                child: Text('Login'),
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Color(0xFF8899A6),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Signup here",
                      style: TextStyle(
                        color: Color(0xFF1D9BF0),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
