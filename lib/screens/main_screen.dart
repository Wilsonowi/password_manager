import 'package:flutter/material.dart';
import 'add_entry_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/encryption_service.dart';
import 'view_entry_screen.dart';

// ── Data class ──
class PasswordEntry {
  String email;
  String siteName;
  String username;
  String password;
  String url;
  List<Map<String, String>> securityQuestions;

  PasswordEntry({
    required this.email,
    required this.siteName,
    required this.username,
    required this.password,
    required this.url,
    this.securityQuestions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'siteName': siteName,
      'username': username,
      'password': password,
      'email': email,
      'url': url,
      'securityQuestions': securityQuestions,
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      email: json['email'] ?? '',
      siteName: json['siteName'],
      username: json['username'],
      password: json['password'],
      url: json['url'] ?? '',
      securityQuestions: (json['securityQuestions'] as List? ?? [])
          .map((e) => Map<String, String>.from(e))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN — bottom nav shell
// ─────────────────────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedTab == 0 ? const PasswordsTab() : const SettingsTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.vpn_key_rounded,
                  label: 'Passwords',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2563EB).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASSWORDS TAB
// ─────────────────────────────────────────────────────────────────────────────
class PasswordsTab extends StatefulWidget {
  const PasswordsTab({super.key});

  @override
  State<PasswordsTab> createState() => _PasswordsTabState();
}

class _PasswordsTabState extends State<PasswordsTab> {
  List<PasswordEntry> _entries = [];
  List<bool> _passwordVisible = [];

  // ── Bug 1 fixed: renamed to _isSearching and _searchQuery (with underscore) ──
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  // ── Bug 2 fixed: added missing _filteredEntries getter ──
  List<PasswordEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    return _entries.where((entry) {
      return entry.siteName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          entry.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addEntry(
    String siteName,
    String username,
    String password,
    String email,
    String url,
    List<Map<String, String>> securityQuestions,
  ) {
    setState(() {
      _entries.add(
        PasswordEntry(
          siteName: siteName,
          username: username,
          email: email,
          password: EncryptionService.encryptPassword(password),
          url: url,
          securityQuestions: securityQuestions,
        ),
      );
      _passwordVisible.add(false);
    });
    _saveEntries();
  }

  void _editEntry(
    int index,
    String siteName,
    String username,
    String password,
    String email,
    String url,
    List<Map<String, String>> securityQuestions,
  ) {
    setState(() {
      _entries[index].siteName = siteName;
      _entries[index].username = username;
      _entries[index].email = email;
      _entries[index].password = EncryptionService.encryptPassword(password);
      _entries[index].url = url;
      _entries[index].securityQuestions = securityQuestions;
    });
    _saveEntries();
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _passwordVisible.removeAt(index);
    });
    _saveEntries();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete "${_entries[index].siteName}"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF94A3B8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(index);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFF87171),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'entries',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('entries');
    if (jsonString == null) return;
    final jsonList = jsonDecode(jsonString) as List;
    setState(() {
      _entries = jsonList
          .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _passwordVisible = List.generate(_entries.length, (_) => false);
    });
  }

  Color _getColorForSite(String siteName) {
    if (siteName.isEmpty) return const Color(0xFF2563EB);
    final int hash = siteName.toLowerCase().codeUnitAt(0);
    final List<Color> colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF000000)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Passwords',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),

                  // ── Count badge + search icon ──
                  Row(
                    children: [
                      if (_entries.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_entries.length} saved',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // ── Bug 3 fixed: correctly references _isSearching ──
                      GestureDetector(
                        onTap: () => setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching)
                            _searchQuery = ''; // clear on close
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _isSearching
                                ? const Color(0xFF2563EB).withOpacity(0.2)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isSearching
                                  ? const Color(0xFF2563EB).withOpacity(0.4)
                                  : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: _isSearching
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF64748B),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search bar — only shows when _isSearching is true ──
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search passwords...',
                            hintStyle: TextStyle(
                              color: const Color(0xFF64748B).withOpacity(0.8),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _searchQuery = ''),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF64748B),
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ── Entry list ──
            Expanded(
              child: _filteredEntries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: _filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredEntries[index];
                        // map filtered index back to real index for edit/delete
                        final realIndex = _entries.indexOf(entry);
                        return _buildCard(entry, realIndex);
                      },
                    ),
            ),

            // ── Add button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEntryScreen(),
                      ),
                    );
                    if (result != null) {
                      _addEntry(
                        result['siteName'],
                        result['username'],
                        result['password'],
                        result['email'] ?? '',
                        result['url'] ?? '',
                        (result['securityQuestions'] as List? ?? []) // ← add
                            .map((e) => Map<String, String>.from(e))
                            .toList(),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Add New Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.lock_outline_rounded,
            size: 72,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No Passwords Saved',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? ''
                : 'Tap the button below to add your passwords.',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(PasswordEntry entry, int index) {
    final Color accentColor = _getColorForSite(entry.siteName);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewEntryScreen(
              siteName: entry.siteName,
              username: entry.username,
              email: entry.email,
              encryptedPassword: entry.password,
              url: entry.url,
              accentColor: accentColor,
              index: index,
              securityQuestions: entry.securityQuestions,
            ),
          ),
        );

        if (result != null) {
          if (result['action'] == 'delete') {
            _confirmDelete(index);
          } else if (result['action'] == 'edit') {
            final data = result['data'];
            _editEntry(
              index,
              data['siteName'],
              data['username'],
              data['password'],
              data['email'] ?? entry.email,
              data['url'] ?? '',
              (data['securityQuestions'] as List? ?? [])
                  .map((e) => Map<String, String>.from(e))
                  .toList(),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  entry.siteName.isNotEmpty
                      ? entry.siteName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.siteName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.username,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF475569),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS TAB
// ─────────────────────────────────────────────────────────────────────────────
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  static const _pinKey = 'master_pin';

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      setState(() {
        _message = 'Please fill in all fields.';
        _isSuccess = false;
      });
      return;
    }
    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      setState(() {
        _message = 'New PIN must be exactly 4 digits.';
        _isSuccess = false;
      });
      return;
    }
    if (newPin != confirmPin) {
      setState(() {
        _message = 'New PINs do not match.';
        _isSuccess = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey) ?? '1234';

    if (currentPin != savedPin) {
      setState(() {
        _message = 'Current PIN is incorrect.';
        _isSuccess = false;
      });
      return;
    }

    await prefs.setString(_pinKey, newPin);
    _currentPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();
    setState(() {
      _message = 'PIN changed successfully!';
      _isSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF000000)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'CHANGE MASTER PIN',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    _buildPinField(
                      controller: _currentPinController,
                      label: 'Current PIN',
                      isVisible: _currentVisible,
                      onToggle: () =>
                          setState(() => _currentVisible = !_currentVisible),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                      indent: 16,
                    ),
                    _buildPinField(
                      controller: _newPinController,
                      label: 'New PIN',
                      isVisible: _newVisible,
                      onToggle: () =>
                          setState(() => _newVisible = !_newVisible),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                      indent: 16,
                    ),
                    _buildPinField(
                      controller: _confirmPinController,
                      label: 'Confirm PIN',
                      isVisible: _confirmVisible,
                      onToggle: () =>
                          setState(() => _confirmVisible = !_confirmVisible),
                    ),
                  ],
                ),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSuccess
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFFEF4444).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: _isSuccess
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _message,
                        style: TextStyle(
                          color: _isSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF87171),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _changePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Update PIN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'ABOUT',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('App', 'KeySafe'),
                    Divider(height: 20, color: Colors.white.withOpacity(0.08)),
                    _buildInfoRow('Version', '1.0.0'),
                    Divider(height: 20, color: Colors.white.withOpacity(0.08)),
                    _buildInfoRow('Encryption', 'AES-256 CBC'),
                    Divider(height: 20, color: Colors.white.withOpacity(0.08)),
                    _buildInfoRow('Storage', 'Local (SharedPreferences)'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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
              obscureText: !isVisible,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: TextStyle(
                  color: const Color(0xFF64748B).withOpacity(0.5),
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: onToggle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
