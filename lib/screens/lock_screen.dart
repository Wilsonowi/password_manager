import 'package:flutter/material.dart';
import 'dart:async';
import 'main_screen.dart';

//Stateful widget for lock screen(Screen can change and update itself based on user interaction)
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  // ── Variables ──
  String _enteredPin = '';
  List<bool> _revealed = [false, false, false, false];
  final _hardcodedPin = '1234';
  String _message = 'Enter your PIN to continue';
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer; // ? means this variable can be null

  // ── Called when a digit key is tapped ──
  void _onKeyTap(String digit) {
    if (_enteredPin.length >= 4) return;

    int index = _enteredPin.length;

    setState(() {
      _enteredPin += digit;
      _revealed[index] = true; // show number briefly
    });

    // after 600ms, hide it behind a dot
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

  void _verifyPin() {
    if (_enteredPin == _hardcodedPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      _failedAttempts++;

      if (_failedAttempts >= 3) {
        _startLockout(); // outside setState ✅
      } else {
        setState(() {
          // only setState for message update
          _message =
              'Incorrect PIN. Remaining attempts: ${3 - _failedAttempts}';
          _enteredPin = '';
          _revealed = [false, false, false, false];
        });
      }
    }
  }

  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutRemaining = 300; // 300 seconds = 5 minutes
      _enteredPin = '';
      _revealed = [false, false, false, false];
      _message = 'Locked out due to multiple failed attempts. Try again later';
    });

    // tick every second
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _lockoutRemaining--);

      if (_lockoutRemaining <= 0) {
        timer.cancel(); // stop the timer
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

  // ── Called when backspace is tapped ──
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
    _lockoutTimer?.cancel(); // cancel timer if screen is closed
    super.dispose();
  }

  // ── UI: Keypad Row ──
  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildKey(digit),
        );
      }).toList(),
    );
  }

  // ── UI: Individual Key ──
  Widget _buildKey(String digit) {
    return SizedBox(
      width: 76,
      height: 76,
      child: TextButton(
        onPressed: () => _onKeyTap(digit),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.06), // Translucent look
          shape: const CircleBorder(), // Circular modern keys
          foregroundColor: Colors.white,
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
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
          child: _isLockedOut ? _buildLockoutView() : _buildNormalView(),
        ),
      ),
    );
  }

  // ── UI: Lockout Screen ──
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
            // Glowing Lock Icon
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
            // Sleek Timer
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
          // Logo Area
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              // Make sure to un-comment and use your asset when ready!
              // child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              child: const Icon(
                Icons.security_rounded,
                size: 36,
                color: Colors.indigoAccent,
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
                  color: filled ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: filled ? Colors.white : const Color(0xFF475569),
                    width: 2,
                  ),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
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
                            color: Color(0xFF0F172A), // Dark text on white dot
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
              const SizedBox(height: 16),
              _buildKeyRow(['4', '5', '6']),
              const SizedBox(height: 16),
              _buildKeyRow(['7', '8', '9']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 76,
                    height: 76,
                  ), // Empty space for alignment
                  const SizedBox(width: 24),
                  _buildKey('0'),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: IconButton(
                      onPressed: _onDelete,
                      icon: const Icon(
                        Icons.backspace_rounded,
                        color: Color(0xFF94A3B8),
                        size: 28,
                      ),
                      splashColor: Colors.white.withOpacity(0.1),
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
