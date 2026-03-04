import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class FacebookLoginCaptchaScreen extends StatefulWidget {
  const FacebookLoginCaptchaScreen({super.key});

  @override
  State<FacebookLoginCaptchaScreen> createState() =>
      _FacebookLoginCaptchaScreenState();
}

class _FacebookLoginCaptchaScreenState
    extends State<FacebookLoginCaptchaScreen> {
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
      body: Container(
        width: double.infinity,
        color: const Color(0xFF3B5999),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: -1,
                            right: 0,
                            child: const Icon(
                              FontAwesomeIcons.facebookF,
                              color: Color(0xFF3b5998),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '(Captcha)',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'English',
                          style: TextStyle(
                            color: Colors.white.withAlpha(150),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: Colors.white.withAlpha(100),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          _buildTextField(
                            hint: 'Account',
                            controller: _accountController,
                          ),
                          const SizedBox(height: 16),
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: SvgPicture.string(
                                          _captchaSvg!,
                                          width: 150,
                                          height: 50,
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
                                  onTap: _isLoadingCaptcha
                                      ? null
                                      : _loadCaptcha,
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
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0x664E69A2),
                                foregroundColor: const Color(0xFFbdcce8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
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
                                      'LOG IN',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Sign Up for Facebook',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decorationColor: Colors.white,
                          decorationThickness: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Positioned(
                            right: 30,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.question,
                                  color: Color(0xFF3b5998),
                                  size: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x99FFFFFF), fontSize: 16),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF8b9dc3)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
