import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_entry_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/encryption_service.dart';
import 'edit_entries_screen.dart';

// ── Data class ──
class PasswordEntry {
  String email;
  String siteName;
  String username;
  String password;

  PasswordEntry({
    required this.email,
    required this.siteName,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'siteName': siteName,
      'username': username,
      'password': password,
      'email': email,
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      email: json['email'],
      siteName: json['siteName'],
      username: json['username'],
      password: json['password'],
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<PasswordEntry> _entries = [];
  List<bool> _passwordVisible = [];
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _addEntry(
    String siteName,
    String username,
    String password,
    String email,
  ) {
    setState(() {
      _entries.add(
        PasswordEntry(
          siteName: siteName,
          username: username,
          email: email,
          password: EncryptionService.encryptPassword(password),
        ),
      );
      _passwordVisible.add(false);
      _expandedIndex = null;
    });
    _saveEntries();
  }

  void _editEntry(
    int index,
    String siteName,
    String username,
    String password,
    String email,
  ) {
    setState(() {
      _entries[index].siteName = siteName;
      _entries[index].username = username;
      _entries[index].email = email;
      _entries[index].password = EncryptionService.encryptPassword(password);
    });
    _saveEntries();
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _passwordVisible.removeAt(index);
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else if (_expandedIndex != null && _expandedIndex! > index) {
        _expandedIndex = _expandedIndex! - 1;
      }
    });
    _saveEntries();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B), // Slate 800
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
    final jsonList = _entries.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString('entries', jsonString);
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
    if (siteName.isEmpty) return const Color(0xFF2563EB); // Default Dark Blue

    final int hash = siteName.toLowerCase().codeUnitAt(0);
    final List<Color> colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Deep Slate/Blue-Black
              Color(0xFF000000), // Pure Black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB), // Dark Blue
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
                  ],
                ),
              ),
              Expanded(
                child: _entries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          return _buildSmartCard(_entries[index], index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.4), // Dark Blue Glow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEntryScreen()),
            );

            if (result != null) {
              _addEntry(
                result['siteName'],
                result['username'],
                result['password'],
                result['email'],
              );
            }
          },
          backgroundColor: const Color(0xFF2563EB), // Dark Blue FAB
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
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
            Icons.lock_outline_rounded,
            size: 72,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── UI: Expandable Smart Card ──
  Widget _buildSmartCard(PasswordEntry entry, int index) {
    final bool isExpanded = _expandedIndex == index;
    final Color accentColor = _getColorForSite(entry.siteName);

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: isExpanded ? 16 : 20,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04), // Glassmorphic card
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isExpanded
                ? accentColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // Top Section (Always Visible)
            Padding(
              padding: const EdgeInsets.all(16),
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
                            fontSize: 18,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.username,
                          style: TextStyle(
                            color: isExpanded
                                ? Colors.white70
                                : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? accentColor : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),

            // Bottom Section (Only Visible When Expanded)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Divider(
                            color: accentColor.withOpacity(0.2),
                            height: 1,
                          ),
                          const SizedBox(height: 16),

                          // Password Reveal Area
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                0.3,
                              ), // Darker reveal box
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    EncryptionService.decryptPassword(
                                      entry.password,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    final decrypted =
                                        EncryptionService.decryptPassword(
                                          entry.password,
                                        );
                                    Clipboard.setData(
                                      ClipboardData(text: decrypted),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Copied ${entry.siteName} password',
                                        ),
                                        backgroundColor: accentColor,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final decryptedPassword =
                                      EncryptionService.decryptPassword(
                                        entry.password,
                                      );
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditEntryScreen(
                                        initialSiteName: entry.siteName,
                                        initialUsername: entry.username,
                                        initialPassword: decryptedPassword,
                                      ),
                                    ),
                                  );

                                  if (result != null) {
                                    _editEntry(
                                      index,
                                      result['siteName'],
                                      result['username'],
                                      result['password'],
                                      result['email'],
                                    );
                                  }
                                },
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text('Edit'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF3B82F6),
                                ), // Light Blue
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _confirmDelete(index),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFF87171),
                                ), // Red
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
