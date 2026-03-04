import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'facebook_login_captcha_screen.dart';

class InstagramLoginCaptchaScreen extends StatefulWidget {
  const InstagramLoginCaptchaScreen({super.key});

  @override
  State<InstagramLoginCaptchaScreen> createState() =>
      _InstagramLoginCaptchaScreenState();
}

class _InstagramLoginCaptchaScreenState
    extends State<InstagramLoginCaptchaScreen> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingCaptcha = false;
  String? _captchaSvg;
  int? _captchaId;

  @override
  void initState() {
    super.initState();
    _loadCaptcha();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _loadCaptcha() async {
    setState(() => _isLoadingCaptcha = true);
    try {
      final response = await http.get(
        Uri.parse('https://backend.ongbantat.io.vn/api/auth/create-captcha'),
        headers: {'authorization': 'customer', 'api-version': 'public'},
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        String svgData = data['data'] ?? '';
        svgData = svgData.replaceAll(
          'viewBox="0,0,150,50"',
          'viewBox="0 0 150 50"',
        );
        svgData = svgData.replaceAll('width="100%"', 'width="150"');
        svgData = svgData.replaceAll('height="100%"', 'height="50"');
        setState(() {
          _captchaSvg = svgData;
          _captchaId = data['id'];
          _captchaController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi tải captcha: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingCaptcha = false);
    }
  }

  Future<void> _login() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();
    final captchaText = _captchaController.text.trim();

    if (account.isEmpty || password.isEmpty || captchaText.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ Account, Password và Captcha');
      return;
    }

    if (_captchaId == null) {
      _showMessage('Captcha chưa được tải. Vui lòng nhấn Refresh.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://backend.ongbantat.io.vn/api/auth/sign-in/account'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'customer',
          'api-version': 'public',
        },
        body: jsonEncode({
          'account': account,
          'password': password,
          'captcha': '$_captchaId|$captchaText',
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(response.statusCode == 200 ? 'Thành công' : 'Thất bại'),
            content: Text(data.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi kết nối: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _bottomSignUpBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7F4EAA), Color(0xFFAC2A8C), Color(0xFFC13967)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        SvgPicture.network(
                          'https://upload.wikimedia.org/wikipedia/commons/2/2a/Instagram_logo.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          height: 50,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '(Captcha)',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          hint: 'Account',
                          controller: _accountController,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          hint: 'Password',
                          isPassword: true,
                          controller: _passwordController,
                        ),

                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withAlpha(50),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'CAPTCHA',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _isLoadingCaptcha
                                  ? const SizedBox(
                                      height: 50,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _captchaSvg != null
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: SizedBox(
                                        width: 150,
                                        height: 50,
                                        child: SvgPicture.string(
                                          _captchaSvg!,
                                          key: ValueKey('captcha_$_captchaId'),
                                          fit: BoxFit.contain,
                                          width: 150,
                                          height: 50,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(
                                      height: 50,
                                      child: Center(
                                        child: Text(
                                          'Không tải được captcha',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _isLoadingCaptcha ? null : _loadCaptcha,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: Colors.white.withAlpha(200),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tải captcha mới',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          hint: 'Nhập mã captcha',
                          controller: _captchaController,
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: const Color(0x80FFFFFF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                                side: const BorderSide(
                                  color: Color(0x26FFFFFF),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white38,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Forgot your login details? ",
                              style: TextStyle(
                                color: const Color(0xCCFFFFFF),
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                "Get help signing in.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FacebookLoginCaptchaScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      bottom: -1,
                                      right: 0,
                                      child: const Icon(
                                        FontAwesomeIcons.facebookF,
                                        color: Color(0xFFA65886),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Log in with Facebook (Captcha)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _bottomSignUpBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0x1AFFFFFF),
        border: Border(top: BorderSide(color: Color(0x2EFFFFFF), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  "Sign up.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
