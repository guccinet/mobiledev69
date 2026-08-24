import 'package:flutter/material.dart';
import 'package:openid_client/openid_client_browser.dart' as openid;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OpenIDLoginPage(),
    );
  }
}

class OpenIDLoginPage extends StatefulWidget {
  const OpenIDLoginPage({super.key});

  @override
  State<OpenIDLoginPage> createState() => _OpenIDLoginPageState();
}

class _OpenIDLoginPageState extends State<OpenIDLoginPage> {
  String _status = 'ยังไม่ได้ล็อกอิน';
  String _idToken = '';

  @override
  void initState() {
    super.initState();
    _checkTokenFromUrl();
  }

  // ตรวจสอบ Token ที่ส่งกลับมาจาก OpenID Server ผ่าน URL
  Future<void> _checkTokenFromUrl() async {
    final currentUrl = Uri.base.toString();
    
    // ตรวจสอบว่าใน URL มี id_token หรือ access_token แนบกลับมาหรือไม่
    if (currentUrl.contains('id_token=') || currentUrl.contains('access_token=')) {
      final fragment = Uri.base.fragment; // ดึงข้อความหลัง #
      final params = Uri.splitQueryString(fragment);
      
      final token = params['id_token'] ?? params['access_token'] ?? '';
      
      if (token.isNotEmpty) {
        setState(() {
          _idToken = token;
          _status = 'เข้าสู่ระบบด้วย OpenID สำเร็จ!';
        });
        return;
      }
    }

    // หากไม่พบใน URL ให้ลองดึงผ่าน openid_client
    try {
      final uri = Uri.parse('http://127.0.0.1:8001/openid');
      const clientId = '320962';

      var issuer = await openid.Issuer.discover(uri);
      var client = openid.Client(issuer, clientId);
      var authenticator = openid.Authenticator(client, scopes: ['openid']);

      var credential = await authenticator.credential;
      if (credential != null) {
        var token = await credential.getTokenResponse();
        setState(() {
          _idToken = token.idToken.toString();
          _status = 'เข้าสู่ระบบด้วย OpenID สำเร็จ!';
        });
      }
    } catch (e) {
      // ไม่ต้องทำอะไรหากเพิ่งเปิดแอปครั้งแรก
    }
  }

  Future<void> _loginWithOpenID() async {
    final uri = Uri.parse('http://127.0.0.1:8001/openid');
    const clientId = '320962';

    try {
      var issuer = await openid.Issuer.discover(uri);
      var client = openid.Client(issuer, clientId);

      var authenticator = openid.Authenticator(
        client,
        scopes: ['openid'],
      );

      authenticator.authorize();
    } catch (e) {
      setState(() {
        _status = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frontend 2 - OpenID Connect')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  color: _idToken.isNotEmpty ? Colors.green : Colors.black
                )
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loginWithOpenID,
                child: const Text('Login ด้วย OpenID Server (backend2)'),
              ),
              if (_idToken.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('ID Token / Access Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: SelectableText(
                    _idToken, 
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}