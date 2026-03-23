import 'package:flutter/material.dart';
import 'dart:math';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

// Returns 0 = weak, 1 = medium, 2 = strong
int _getPasswordStrength(String password) { 
  if (password.isEmpty) return 0;

  bool hasUpper = password.contains(RegExp(r'[A-Z]'));
  bool hasLower = password.contains(RegExp(r'[a-z]'));
  bool hasDigit = password.contains(RegExp(r'[0-9]'));
  bool hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  int types = [hasUpper, hasLower, hasDigit, hasSpecial].where((b) => b).length;

  if (password.length >= 10 && types >= 4) return 2; // strong
  if (password.length >= 6 && types >= 2) return 1; // medium
  return 0; // weak
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _emailController = TextEditingController();
  final _siteController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  bool _passwordVisible = false;
  List<Map<String, String>> _securityQuestions = [];

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onSave() {
    final site = _siteController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    String url = _urlController.text.trim();

    if (url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('www.')) {
      url = 'https://$url';
    }

    if (site.isEmpty || username.isEmpty || password.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Please fill in all fields',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'siteName': site,
      'username': username,
      'email': email,
      'password': password,
      'url': url,
      'securityQuestions': _securityQuestions,
    });
  }

  void _generateSecurePassword() {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*()';
    final rnd = Random();
    String generated = String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    setState(() {
      _passwordController.text = generated;
      _passwordVisible = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Secure password generated!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return true; // URL is optional, empty is fine
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('www.');
  }

  Widget _buildWarning(String message) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(String password) {
    if (password.isEmpty)
      return const SizedBox.shrink(); // hide if nothing typed

    final int strength = _getPasswordStrength(password);

    final List<Color> colors = [
      const Color(0xFFEF4444), // red   — weak
      const Color(0xFFF59E0B), // amber — medium
      const Color(0xFF10B981), // green — strong
    ];

    final List<String> labels = ['Weak', 'Medium', 'Strong'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // ── 3 segment bar ──
          ...List.generate(3, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= strength
                      ? colors[strength] // filled segment
                      : Colors.white.withOpacity(0.1), // empty segment
                ),
              ),
            );
          }),

          const SizedBox(width: 10),

          // ── Label ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              labels[strength],
              key: ValueKey(strength), // triggers animation on change
              style: TextStyle(
                color: colors[strength],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Same gradient as main screen ──
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Deep Slate
              Color(0xFF000000), // Pure Black
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon Header ──
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      size: 36,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Section Label ──
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'NEW PASSWORD ENTRY',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                // ── Input Fields Container ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildField(
                        controller: _siteController,
                        label: 'App/Website Name',
                        hint: 'Example: Google, Netflix',
                        icon: Icons.language_rounded,
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _urlController,
                        label: 'URL',
                        hint: 'https://example.com',
                        icon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                        onChanged: (_) => setState(
                          () {},
                        ), // ← triggers warning to appear live
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Your username or ID',
                        icon: Icons.person_rounded,
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'example@email.com',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(
                          () {},
                        ), // ← triggers warning to appear live
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter or generate',
                        icon: Icons.lock_rounded,
                        isPassword: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ), // ── Validation warnings ──

                _buildStrengthBar(_passwordController.text),

                if (_emailController.text.isNotEmpty &&
                    !_isValidEmail(_emailController.text))
                  _buildWarning(
                    'Invalid email format  (e.g. name@example.com)',
                  ),

                if (_urlController.text.isNotEmpty &&
                    !_isValidUrl(_urlController.text))
                  _buildWarning(
                    'URL should start with https:// or http:// or www.',
                  ),

                // ── Generate Password Button ──
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _generateSecurePassword,
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                    label: const Text(
                      'Generate Secure Password',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF2563EB).withOpacity(0.2),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SECURITY QUESTIONS',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    // Add new Q&A button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _securityQuestions.add({
                            'question': '',
                            'answer': '',
                          });
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: Color(0xFF3B82F6),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Q&A pairs list ──
                ..._securityQuestions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final qa = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        // Question field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.help_outline_rounded,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                  controller:
                                      TextEditingController(
                                          text: qa['question'],
                                        )
                                        ..selection = TextSelection.collapsed(
                                          offset: qa['question']?.length ?? 0,
                                        ),
                                  decoration: InputDecoration(
                                    hintText: 'Security question',
                                    hintStyle: TextStyle(
                                      color: const Color(
                                        0xFF475569,
                                      ).withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onChanged: (val) =>
                                      _securityQuestions[i]['question'] = val,
                                ),
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () => setState(
                                  () => _securityQuestions.removeAt(i),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.08),
                          indent: 16,
                        ),
                        // Answer field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.short_text_rounded,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                  controller:
                                      TextEditingController(text: qa['answer'])
                                        ..selection = TextSelection.collapsed(
                                          offset: qa['answer']?.length ?? 0,
                                        ),
                                  decoration: InputDecoration(
                                    hintText: 'Your answer',
                                    hintStyle: TextStyle(
                                      color: const Color(
                                        0xFF475569,
                                      ).withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onChanged: (val) =>
                                      _securityQuestions[i]['answer'] = val,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 32),

                // ── Save Button ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Divider between fields ──
  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.08),
      indent: 16,
    );
  }

  // ── Input field with leading icon ──
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Leading icon
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),

          // Label
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !_passwordVisible,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: const Color(0xFF475569).withOpacity(0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
