import 'package:flutter/material.dart';
import 'add_entry_screen.dart';
import 'dart:convert'; // for jsonEncode/jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // for storage
import '../services/encryption_service.dart';
import 'edit_entries_screen.dart';

// ── Data class — just holds data, like a struct in C ──
class PasswordEntry {
  String siteName;
  String username;
  String password;

  PasswordEntry({
    required this.siteName,
    required this.username,
    required this.password,
  });

  // convert entry → Map (so we can encode to JSON)
  Map<String, dynamic> toJson() {
    return {'siteName': siteName, 'username': username, 'password': password};
  }

  // convert Map → entry (so we can decode from JSON)
  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
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
  // ── List lives here inside state, not global ──
  List<PasswordEntry> _entries = [];
  List<bool> _passwordVisible = [];

  @override
  void initState() {
    super.initState();
    _loadEntries(); // load saved entries on startup
  }

  // ── Add a new entry ──
  void _addEntry(String siteName, String username, String password) {
    setState(() {
      _entries.add(
        PasswordEntry(
          siteName: siteName,
          username: username,
          password: EncryptionService.encryptPassword(
            password,
          ), // ← encrypt before storing
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
  ) {
    setState(() {
      _entries[index].siteName = siteName;
      _entries[index].username = username;
      _entries[index].password = EncryptionService.encryptPassword(
        password,
      ); // ← encrypt
    });
    _saveEntries();
  }

  // ── Delete entry by index ──
  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _passwordVisible.removeAt(index); // ← add this
    });
    _saveEntries(); // save after deleting
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: Color(0xFFE2E8F0)),
        ),
        content: Text(
          'Delete "${_entries[index].siteName}"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          // Confirm delete button
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog first
              _deleteEntry(index); // then delete
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save all entries to device ──
  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();

    // convert each entry to JSON, then encode the whole list
    final jsonList = _entries.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await prefs.setString('entries', jsonString);
  }

  // ── Load entries from device ──
  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('entries');

    // if nothing saved yet, do nothing
    if (jsonString == null) return;

    final jsonList = jsonDecode(jsonString) as List;

    setState(() {
      _entries = jsonList
          .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _passwordVisible = List.generate(_entries.length, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── UI: Modern Gradient Background ──
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF020617), // Slate 950
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Top App Bar to blend with gradient
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.indigoAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'KeySafe',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: _entries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 100,
                        ), // Padding for FAB
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _card(entry, index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      // ── UI: Floating Action Button ──
      floatingActionButton: FloatingActionButton(
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
            );
          }
        },
        backgroundColor: Colors.indigoAccent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── UI: Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 72,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Vault is Empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button below to safely\nstore your first password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── UI: Password Card ──
  Widget _card(PasswordEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04), // Glassmorphic background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ), // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  entry.siteName.isNotEmpty
                      ? entry.siteName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.indigoAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.siteName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.3,
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
                  const SizedBox(height: 6),
                  Text(
                    _passwordVisible[index]
                        ? EncryptionService.decryptPassword(entry.password)
                        : '••••••••••••',
                    style: TextStyle(
                      color: _passwordVisible[index]
                          ? Colors.white70
                          : const Color(0xFF64748B),
                      fontSize: _passwordVisible[index] ? 14 : 18,
                      letterSpacing: _passwordVisible[index] ? 0 : 2,
                      fontWeight: _passwordVisible[index]
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _passwordVisible[index]
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: _passwordVisible[index]
                        ? Colors.indigoAccent
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible[index] = !_passwordVisible[index];
                    });
                  },
                ),
                // Wrap the popup options in a subtle menu to save space
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      // 1. Decrypt the password to show in the edit screen
                      final decryptedPassword =
                          EncryptionService.decryptPassword(entry.password);

                      // 2. Navigate and wait for the returned data
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

                      // 3. Update the entry if the user saved changes
                      if (result != null) {
                        _editEntry(
                          index,
                          result['siteName'],
                          result['username'],
                          result['password'],
                        );
                      }
                    } else if (value == 'delete') {
                      _confirmDelete(index);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            color: Color(0xFFF87171),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: Color(0xFFF87171)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
