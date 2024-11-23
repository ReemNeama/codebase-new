// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';

import 'authentication/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimationRotation;
  late Animation<double> _logoAnimationScale;

  bool _showWelcomeText = false;

  @override
  void initState() {
    super.initState();
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    _logoController = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 5), // Adjusted duration for logo animation
    );

    _logoAnimationRotation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159 * 2,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.linear,
    ));

    _logoAnimationScale = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    );

    _logoController.addListener(() {
      setState(() {});
    });

    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _showText();
        _startDelayBeforeNavigation();
      }
    });

    _logoController.forward();
  }

  void _showText() {
    setState(() {
      _showWelcomeText = true;
    });
  }

  void _startDelayBeforeNavigation() {
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_logoAnimationScale.value != 1.0)
              Transform.scale(
                scale: _logoAnimationScale.value * 2,
                child: Transform.rotate(
                  angle: _logoAnimationRotation.value,
                  child: Image.asset(
                    'asset/logo.png',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
            if (_showWelcomeText) AnimatedWelcomeText(),
          ],
        ),
      ),
    );
  }
}

class AnimatedWelcomeText extends StatefulWidget {
  const AnimatedWelcomeText({super.key});

  @override
  _AnimatedWelcomeTextState createState() => _AnimatedWelcomeTextState();
}

class _AnimatedWelcomeTextState extends State<AnimatedWelcomeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<Color?> _textAnimationColor;

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 200), // Reduced text animation duration
    );

    _textAnimationColor = ColorTween(
      begin: Colors.grey[200],
      end: Colors.black,
    ).animate(_textController);

    _textController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _textAnimationColor,
      builder: (context, child) {
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Welcome!',
              style: TextStyle(
                color: _textAnimationColor.value!,
                fontSize: MediaQuery.of(context).size.width * 0.1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
