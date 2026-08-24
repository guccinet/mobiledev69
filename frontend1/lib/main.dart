import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _accessToken = '';
  String _refreshToken = '';
  String _statusMessage = '';

  Future<void> _login() async {
    // ใช้ 10.0.2.2 ถ้าเทสบน Android Emulator หรือใช้ 127.0.0.1/localhost สำหรับ Web, Windows, Chrome
    final url = Uri.parse('http://127.0.0.1:8000/api/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _accessToken = data['access'];
          _refreshToken = data['refresh'];
          _statusMessage = 'เข้าสู่ระบบสำเร็จ!';
        });
      } else {
        setState(() {
          _statusMessage = 'เข้าสู่ระบบไม่สำเร็จ: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frontend 1 - JWT Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login ขอ Token'),
              ),
              const SizedBox(height: 20),
              Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              if (_accessToken.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Access Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(_accessToken, style: const TextStyle(fontSize: 10, color: Colors.green)),
                const SizedBox(height: 10),
                const Text('Refresh Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(_refreshToken, style: const TextStyle(fontSize: 10, color: Colors.orange)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}