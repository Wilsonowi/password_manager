import 'package:flutter/material.dart';

class EditEntryScreen extends StatefulWidget {
  final String initialSiteName;
  final String initialUsername;
  final String initialEmail;
  final String initialPassword;
  final String initialUrl;
  final List<Map<String, String>> initialSecurityQuestions;
  final String initialCategory;
  final String initialNotes;

  const EditEntryScreen({
    super.key,
    required this.initialSiteName,
    required this.initialUsername,
    required this.initialPassword,
    required this.initialEmail,
    required this.initialUrl,
    this.initialSecurityQuestions = const [],
    required this.initialCategory,
    required this.initialNotes,
  });

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

int _getPasswordStrength(String password) {
  if (password.isEmpty) return 0;
  bool hasUpper = password.contains(RegExp(r'[A-Z]'));
  bool hasLower = password.contains(RegExp(r'[a-z]'));
  bool hasDigit = password.contains(RegExp(r'[0-9]'));
  bool hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  int types = [hasUpper, hasLower, hasDigit, hasSpecial].where((b) => b).length;
  if (password.length >= 10 && types >= 4) return 2;
  if (password.length >= 6 && types >= 2) return 1;
  return 0;
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late TextEditingController _siteController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  bool _passwordVisible = false;
  late List<Map<String, String>> _securityQuestions;

  late String _selectedCategory;
  final List<String> _categories = [
    'General',
    'Banking',
    'Social',
    'Work',
    'Shopping',
    'Streaming',
  ];
  @override
  void initState() {
    super.initState();
    _siteController = TextEditingController(text: widget.initialSiteName);
    _usernameController = TextEditingController(text: widget.initialUsername);
    _passwordController = TextEditingController(text: widget.initialPassword);
    _emailController = TextEditingController(text: widget.initialEmail);
    _urlController = TextEditingController(text: widget.initialUrl);
    _notesController = TextEditingController(text: widget.initialNotes);
    _selectedCategory = widget.initialCategory.isNotEmpty
        ? widget.initialCategory
        : 'General';
    _securityQuestions = widget.initialSecurityQuestions
        .map((e) => Map<String, String>.from(e))
        .toList();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  bool _isValidUrl(String url) {
    if (url.isEmpty) return true;
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('www.');
  }

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _urlController.dispose();
    _notesController.dispose();
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

    if (site.isEmpty || username.isEmpty || password.isEmpty) {
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
      'password': password,
      'email': email,
      'url': url,
      'securityQuestions': _securityQuestions,
      'category': _selectedCategory,
      'notes': _notesController.text.trim(),
    });
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
    if (password.isEmpty) return const SizedBox.shrink();
    final int strength = _getPasswordStrength(password);
    final List<Color> colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];
    final List<String> labels = ['Weak', 'Medium', 'Strong'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          ...List.generate(3, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= strength
                      ? colors[strength]
                      : Colors.white.withOpacity(0.1),
                ),
              ),
            );
          }),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              labels[strength],
              key: ValueKey(strength),
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
          'Edit Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Icons.edit_rounded,
                      size: 36,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'EDIT ACCOUNT DETAILS',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
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
                        label: 'Website',
                        hint: 'e.g. Google, Netflix',
                        icon: Icons.language_rounded,
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _urlController,
                        label: 'URL',
                        hint: 'https://example.com',
                        icon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                        onChanged: (_) => setState(() {}),
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Your username',
                        icon: Icons.person_rounded,
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'example@email.com',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter password',
                        icon: Icons.lock_rounded,
                        isPassword: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                _buildStrengthBar(_passwordController.text),

                if (_emailController.text.isNotEmpty &&
                    !_isValidEmail(_emailController.text))
                  _buildWarning(
                    'Invalid email format  (e.g. name@example.com)',
                  ),
                if (_urlController.text.isNotEmpty &&
                    !_isValidUrl(_urlController.text))
                  _buildWarning('URL should start with https:// or http://'),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'CATEGORY',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _selectedCategory = category);
                          },
                          backgroundColor: Colors.white.withOpacity(0.04),
                          selectedColor: const Color(
                            0xFF2563EB,
                          ).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF94A3B8),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF3B82F6).withOpacity(0.5)
                                : Colors.white.withOpacity(0.08),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'ADDITIONAL DETAILS',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: _buildField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Optional details, PINs, etc.',
                    icon: Icons.note_alt_rounded,
                    maxLines: 3,
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
                    GestureDetector(
                      onTap: () => setState(
                        () => _securityQuestions.add({
                          'question': '',
                          'answer': '',
                        }),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                              color: Color(0xFF60A5FA),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Add New',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ..._securityQuestions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final qa = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.help_outline_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 15,
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
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onChanged: (val) =>
                                      _securityQuestions[i]['question'] = val,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFFEF4444),
                                ),
                                splashRadius: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.key_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 15,
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
                                      fontSize: 14,
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
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _onSave,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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

  Widget _buildDivider() =>
      Divider(height: 1, color: Colors.white.withOpacity(0.08), indent: 16);

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
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
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !_passwordVisible,
              keyboardType: keyboardType,
              onChanged: onChanged,
              maxLines: maxLines,
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
