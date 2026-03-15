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
  // ── Logic: Variables ──
  String _enteredPin = '';
  List<bool> _revealed = [false, false, false, false];
  final _hardcodedPin = '1234';
  String _message = 'Enter your PIN to continue';
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer;

  // ── Logic: Key Tap ──
  void _onKeyTap(String digit) {
    if (_enteredPin.length >= 4) return;

    int index = _enteredPin.length;

    setState(() {
      _enteredPin += digit;
      _revealed[index] = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _revealed[index] = false;
        });
      }
    });

    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 300), _verifyPin);
    }
  }

  // ── Logic: Verification ──
  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('master_pin') ?? '1234';

    if (_enteredPin == savedPin) {
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
              'Incorrect PIN. Remaining attempts: ${3 - _failedAttempts}';
          _enteredPin = '';
          _revealed = [false, false, false, false];
        });
      }
    }
  }

  // ── Logic: Lockout ──
  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutRemaining = 300;
      _enteredPin = '';
      _revealed = [false, false, false, false];
      _message = 'Locked out due to multiple failed attempts.';
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _lockoutRemaining--);

      if (_lockoutRemaining <= 0) {
        timer.cancel();
        _endLockout();
      }
    });
  }

  void _endLockout() {
    setState(() {
      _isLockedOut = false;
      _failedAttempts = 0;
      _lockoutRemaining = 0;
      _message = 'Enter your PIN to continue';
    });
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

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  // ── UI: Keypad Row ──
  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ), // Slightly tighter spacing for squares
          child: _buildKey(digit),
        );
      }).toList(),
    );
  }

  // ── UI: Individual Square Key ──
  Widget _buildKey(String digit) {
    return SizedBox(
      width: 76,
      height: 76,
      child: TextButton(
        onPressed: () => _onKeyTap(digit),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(
            0.06,
          ), // Translucent dark glass
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16,
            ), // Gives it a smooth square look
            side: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ), // Subtle border
          ),
          foregroundColor: const Color(0xFF2563EB), // Dark blue splash ripple
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── UI: Square Backspace Key ──
  Widget _buildBackspaceKey() {
    return SizedBox(
      width: 76,
      height: 76,
      child: TextButton(
        onPressed: _onDelete,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(
            0.02,
          ), // Slightly dimmer than number keys
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.02), width: 1),
          ),
          foregroundColor: const Color(0xFF2563EB),
        ),
        child: const Icon(
          Icons.backspace_rounded,
          color: Color(0xFF94A3B8),
          size: 28,
        ),
      ),
    );
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
          child: _isLockedOut ? _buildLockoutView() : _buildNormalView(),
        ),
      ),
    );
  }

  // ── UI: Lockout View ──
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                size: 64,
                color: Color(0xFFF87171),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'App Locked',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Too many incorrect attempts.\nPlease wait before trying again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              timer,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Color(0xFFF87171),
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI: Normal Keypad Screen ──
  Widget _buildNormalView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const Icon(
                Icons.security_rounded,
                size: 36,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'KeySafe',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _failedAttempts > 0
                  ? const Color(0xFFF87171)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 48),

          // ── PIN Indicators ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              bool filled = i < _enteredPin.length;
              bool revealed = filled && _revealed[i];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? const Color(0xFF2563EB)
                      : Colors.transparent, // Dark Blue Filled
                  border: Border.all(
                    color: filled
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF475569),
                    width: 2,
                  ),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.4),
                            blurRadius: 10,
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 64),

          // ── Keypad Grid ──
          Column(
            children: [
              _buildKeyRow(['1', '2', '3']),
              const SizedBox(
                height: 12,
              ), // Reduced gap slightly to fit the square layout better
              _buildKeyRow(['4', '5', '6']),
              const SizedBox(height: 12),
              _buildKeyRow(['7', '8', '9']),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 76,
                    height: 76,
                  ), // Empty space for alignment
                  const SizedBox(width: 20),
                  _buildKey('0'),
                  const SizedBox(width: 20),
                  _buildBackspaceKey(), // New matching square backspace key!
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
