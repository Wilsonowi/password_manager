import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? _expandedIndex; // which card is currently expanded (null if none)
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

  Color _getColorForSite(String siteName) {
    if (siteName.isEmpty) return const Color(0xFF6366F1); // Default Indigo

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
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'My Vault',
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

              // List Content
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
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(
          Icons.add_rounded,
          color: Color(0xFF0F172A),
          size: 32,
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
            'Tap the + button below to add your first entry.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
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
          // Toggle expansion
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: isExpanded
              ? 16
              : 20, // Expands slightly wider when tapped
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isExpanded
              ? accentColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isExpanded
                ? accentColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.05),
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
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    // Allows user to highlight and copy manually too
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
                                    );
                                  }
                                },
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text('Edit'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                ),
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
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(), // Takes up 0 space when closed
            ),
          ],
        ),
      ),
    );
  }
}
