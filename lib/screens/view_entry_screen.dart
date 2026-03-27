import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/encryption_service.dart';
import 'edit_entries_screen.dart';

class GlowingFavicon extends StatefulWidget {
  final String url;
  final String fallbackName;
  final double size;

  const GlowingFavicon({
    super.key,
    required this.url,
    required this.fallbackName,
    this.size = 50,
  });

  @override
  State<GlowingFavicon> createState() => _GlowingFaviconState();
}

class _GlowingFaviconState extends State<GlowingFavicon> {
  bool _isTimedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Give the network exactly 4 seconds to find the logo
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isTimedOut = true; // Timer finished! Kill the spinner.
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getDomain() {
    if (widget.url.isEmpty) return '';
    try {
      final uri = Uri.parse(
        widget.url.startsWith('http') ? widget.url : 'https://${widget.url}',
      );
      String host = uri.host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host;
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = _getDomain();
    final fallbackInitial = widget.fallbackName.isNotEmpty
        ? widget.fallbackName[0].toUpperCase()
        : '?';

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B), // Dark slate background
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipOval(
        // If timed out OR no URL provided, show the letter immediately
        child: _isTimedOut || domain.isEmpty
            ? _buildFallback(fallbackInitial)
            : CachedNetworkImage(
                imageUrl: 'https://icon.horse/icon/$domain',
                fit: BoxFit.cover,
                imageBuilder: (context, imageProvider) {
                  // Success! The image loaded before 4 seconds. Cancel the timer.
                  _timer?.cancel();
                  return Image(image: imageProvider, fit: BoxFit.cover);
                },
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: widget.size * 0.4,
                    height: widget.size * 0.4,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  // Failed (like a 404 error). Cancel timer and show letter.
                  _timer?.cancel();
                  return _buildFallback(fallbackInitial);
                },
              ),
      ),
    );
  }

  Widget _buildFallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ViewEntryScreen extends StatelessWidget {
  final String siteName;
  final String username;
  final String email;
  final String encryptedPassword;
  final String url;
  final Color accentColor;
  final int index;
  final List<Map<String, String>> securityQuestions;

  // New Fields!
  final String category;
  final String notes;

  const ViewEntryScreen({
    super.key,
    required this.siteName,
    required this.username,
    required this.email,
    required this.encryptedPassword,
    required this.url,
    required this.accentColor,
    required this.index,
    required this.securityQuestions,
    required this.category,
    required this.notes,
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
                      initialEmail: email,
                      initialPassword: decryptedPassword,
                      initialUrl: url,
                      initialSecurityQuestions: securityQuestions,
                      initialCategory: category,
                      initialNotes: notes,
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
            colors: [Color(0xFF0F172A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Favicon Header
                GlowingFavicon(url: url, fallbackName: siteName, size: 88),
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

                // URL Pill Badge
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
                    'DETAILS',
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
                        icon: Icons.folder_special_rounded,
                        label: 'Category',
                        value: category.isNotEmpty ? category : 'General',
                      ),
                      _buildDivider(),
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
                      // Show Notes ONLY if they exist
                      if (notes.isNotEmpty) ...[
                        _buildDivider(),
                        _buildDetailRow(
                          context,
                          icon: Icons.note_alt_rounded,
                          label: 'Notes',
                          value: notes,
                          onCopy: () => _copy(context, notes, 'Notes'),
                        ),
                      ],
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

                // ── Security Questions Section ──
                if (securityQuestions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SECURITY QUESTIONS',
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
                      children: securityQuestions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final qa = entry.value;
                        return Column(
                          children: [
                            _buildDetailRow(
                              context,
                              icon: Icons.help_outline_rounded,
                              label: 'Question ${i + 1}',
                              value: qa['question'] ?? '',
                            ),
                            Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.08),
                              indent: 56,
                            ),
                            _buildDetailRow(
                              context,
                              icon: Icons.key_rounded,
                              label: 'Answer',
                              value: qa['answer'] ?? '',
                              onCopy: () =>
                                  _copy(context, qa['answer'] ?? '', 'Answer'),
                            ),
                            if (i < securityQuestions.length - 1)
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.15),
                                indent: 16,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
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
                      backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                      foregroundColor: const Color(0xFFF87171),
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
                      'Delete Password',
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
      indent: 56,
    );
  }

  // ── UI: Stacked Detail Row with Tinted Icon Box ──
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy, // Made this optional
  }) {
    final displayValue = value.isEmpty ? '—' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 16),
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
          if (onCopy != null)
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
