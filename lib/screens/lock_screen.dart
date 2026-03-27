import 'package:flutter/material.dart';
import 'dart:async';
import 'main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  List<bool> _revealed = [false, false, false, false];
  String _message = 'Enter your PIN to continue';
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _checkExistingLockout();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  // ── Logic: Key Tap ──
  void _onKeyTap(String digit) {
    if (_enteredPin.length >= 4) return;
    int index = _enteredPin.length;
    setState(() {
      _enteredPin += digit;
      _revealed[index] = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _revealed[index] = false);
    });
    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 300), _verifyPin);
    }
  }

  // ── Logic: Delete ──
  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      int index = _enteredPin.length - 1;
      _enteredPin = _enteredPin.substring(0, index);
      _revealed[index] = false;
    });
  }

  // ── Logic: Verify PIN ──
  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('master_pin') ?? '1234';
    if (_enteredPin == savedPin) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _startLockout();
      } else {
        setState(() {
          _message =
              'Incorrect PIN. ${3 - _failedAttempts} attempt${3 - _failedAttempts == 1 ? '' : 's'} remaining';
          _enteredPin = '';
          _revealed = [false, false, false, false];
        });
      }
    }
  }

  // ── Logic: Lockout ──
  Future<void> _startLockout() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEnd = DateTime.now().add(const Duration(minutes: 5));
    await prefs.setString('lockout_end', lockoutEnd.toIso8601String());
    setState(() {
      _isLockedOut = true;
      _lockoutRemaining = 300;
      _enteredPin = '';
      _revealed = [false, false, false, false];
      _message = 'Too many incorrect attempts.';
    });
    _startLockoutTimer();
  }

  void _startLockoutTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEndStr = prefs.getString('lockout_end');
    if (lockoutEndStr == null) return;
    final lockoutEnd = DateTime.parse(lockoutEndStr);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = lockoutEnd.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        timer.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('lockout_end');
        if (mounted) _endLockout();
      } else {
        if (mounted) setState(() => _lockoutRemaining = remaining.inSeconds);
      }
    });
  }

  Future<void> _checkExistingLockout() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEndStr = prefs.getString('lockout_end');
    if (lockoutEndStr == null) return;
    final lockoutEnd = DateTime.parse(lockoutEndStr);
    if (DateTime.now().isBefore(lockoutEnd)) {
      setState(() => _isLockedOut = true);
      _startLockoutTimer();
    } else {
      await prefs.remove('lockout_end');
    }
  }

  void _endLockout() {
    setState(() {
      _isLockedOut = false;
      _failedAttempts = 0;
      _lockoutRemaining = 0;
      _message = 'Enter your PIN to continue';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: _isLockedOut ? _buildLockoutView() : _buildNormalView(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // LOCKOUT VIEW
  // ══════════════════════════════════════════
  Widget _buildLockoutView() {
    int minutes = _lockoutRemaining ~/ 60;
    int seconds = _lockoutRemaining % 60;
    String timer = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                size: 48,
                color: Color(0xFFF87171),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'App Locked',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Too many incorrect attempts.\nPlease wait before trying again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                ),
              ),
              child: Text(
                timer,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  color: Color(0xFFF87171),
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'remaining',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // NORMAL KEYPAD VIEW
  // ══════════════════════════════════════════
  Widget _buildNormalView() {
    return Column(
      children: [
        // ── Top: Logo + title + PIN dots ──
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─────────────────────────────────────
              // LOGO SECTION
              // To use your own logo, replace the inner Container+Icon with:
              //   Image.asset('assets/logo.png', fit: BoxFit.cover)
              // ─────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.45),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo.png', // ← your logo file
                    fit: BoxFit.cover,
                    // If logo.png is missing, remove these 3 lines and
                    // uncomment the fallback block below
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'KeySafe',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Password Is Safe With Us',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF475569),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 52),

              // ── PIN dots ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  bool filled = i < _enteredPin.length;
                  bool revealed = filled && _revealed[i];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF334155),
                        width: 2,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF2563EB,
                                ).withOpacity(0.55),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: revealed
                          ? Text(
                              _enteredPin[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // ── Message ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _message,
                  key: ValueKey(_message),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _failedAttempts > 0
                        ? const Color(0xFFF87171)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom: Keypad ──
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeyRow(['1', '2', '3']),
              const SizedBox(height: 14),
              _buildKeyRow(['4', '5', '6']),
              const SizedBox(height: 14),
              _buildKeyRow(['7', '8', '9']),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 80, height: 80),
                  const SizedBox(width: 16),
                  _buildKey('0'),
                  const SizedBox(width: 16),
                  _buildBackspaceKey(),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // ── UI: Keypad Row ──
  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildKey(digit),
        );
      }).toList(),
    );
  }

  // ── UI: Number Key ──
  Widget _buildKey(String digit) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: () => _onKeyTap(digit),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          foregroundColor: const Color(0xFF2563EB),
          overlayColor: const Color(0xFF2563EB),
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── UI: Backspace Key ──
  Widget _buildBackspaceKey() {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: _onDelete,
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          foregroundColor: const Color(0xFF64748B),
        ),
        child: const Icon(
          Icons.backspace_outlined,
          color: Color(0xFF64748B),
          size: 26,
        ),
      ),
    );
  }
}
