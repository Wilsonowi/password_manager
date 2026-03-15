import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import 'edit_entries_screen.dart'; // Ensure this matches your file name

class ViewEntryScreen extends StatelessWidget {
  final String siteName;
  final String username;
  final String email;
  final String encryptedPassword;
  final String url;
  final Color accentColor;
  final int index;

  const ViewEntryScreen({
    super.key,
    required this.siteName,
    required this.username,
    required this.email,
    required this.encryptedPassword,
    required this.url,
    required this.accentColor,
    required this.index,
  });

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              '$label copied to clipboard',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decryptedPassword = EncryptionService.decryptPassword(
      encryptedPassword,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Entry Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEntryScreen(
                      initialSiteName: siteName,
                      initialUsername: username,
                      initialEmail: email, // Passed email
                      initialPassword: decryptedPassword,
                      initialUrl: url,
                      // Note: Pass initialUrl here if you added it to EditEntryScreen
                    ),
                  ),
                );
                if (result != null && context.mounted) {
                  Navigator.pop(context, {'action': 'edit', 'data': result});
                }
              },
              icon: const Icon(
                Icons.edit_rounded,
                size: 18,
                color: Color(0xFF3B82F6),
              ),
              label: const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF000000),
            ], // Black & Dark Blue Theme
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Glowing Header Section ──
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4), // Glowing shadow
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      siteName.isNotEmpty ? siteName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  siteName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),

                // URL Pill Badge (Only shows if URL is provided)
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _copy(context, url, 'URL'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.link_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            url,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // ── Details Section ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'ACCOUNT DETAILS',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        icon: Icons.person_rounded,
                        label: 'Username',
                        value: username,
                        onCopy: () => _copy(context, username, 'Username'),
                      ),
                      _buildDivider(),
                      _buildDetailRow(
                        context,
                        icon: Icons.email_rounded,
                        label: 'Email Address',
                        value: email,
                        onCopy: () => _copy(context, email, 'Email'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Password Section ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'SECURITY',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _PasswordRevealCard(
                  password: decryptedPassword,
                  accentColor: accentColor,
                  onCopy: () => _copy(context, decryptedPassword, 'Password'),
                ),

                const SizedBox(height: 40),

                // ── Delete Button ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {'action': 'delete'});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFEF4444,
                      ).withOpacity(0.1), // Tinted Red Background
                      foregroundColor: const Color(0xFFF87171), // Red Text
                      elevation: 0,
                      side: BorderSide(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    label: const Text(
                      'Delete Entry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.08),
      indent: 56, // Indented so it aligns with the text, not the icon
    );
  }

  // ── UI: Stacked Detail Row with Tinted Icon Box ──
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    final displayValue = value.isEmpty ? '—' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Tinted Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 16),

          // Stacked Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          IconButton(
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
            splashColor: const Color(0xFF3B82F6).withOpacity(0.2),
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}

// ── Stateful widget for Password Reveal ──
class _PasswordRevealCard extends StatefulWidget {
  final String password;
  final Color accentColor;
  final VoidCallback onCopy;

  const _PasswordRevealCard({
    required this.password,
    required this.accentColor,
    required this.onCopy,
  });

  @override
  State<_PasswordRevealCard> createState() => _PasswordRevealCardState();
}

class _PasswordRevealCardState extends State<_PasswordRevealCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Tinted Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 16),

          // Password Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _visible ? widget.password : '••••••••••••',
                  style: TextStyle(
                    color: _visible ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: _visible ? 16 : 20,
                    fontWeight: _visible ? FontWeight.w500 : FontWeight.w900,
                    letterSpacing: _visible ? 1.0 : 2.5,
                  ),
                ),
              ],
            ),
          ),

          // Toggle Visibility Button
          IconButton(
            onPressed: () => setState(() => _visible = !_visible),
            icon: Icon(
              _visible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
              color: const Color(0xFF94A3B8),
            ),
            splashColor: const Color(0xFF3B82F6).withOpacity(0.2),
            highlightColor: Colors.transparent,
          ),

          // Copy Button
          IconButton(
            onPressed: widget.onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
            splashColor: const Color(0xFF3B82F6).withOpacity(0.2),
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
