import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final int initialPage;

const OnboardingScreen({
  super.key,
  this.initialPage = 0,
});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
late int _currentPage;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color blue = Color(0xFF1677FF);
  static const Color lightBlue = Color(0xFF4DA3FF);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
_pageController = PageController(
  initialPage: widget.initialPage,
);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // ============================================================
  // NEXT PAGE
  // ============================================================

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _openLogin() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool(
    'onboarding_completed',
    true,
  );

  if (!mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ),
  );
}

  // ============================================================
  // REGISTER
  // ============================================================

  void _openRegister() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const RegisterScreen(),
    ),
  );
}

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // MAIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031B49),
      extendBodyBehindAppBar: true,

      body: PageView(
        controller: _pageController,

        physics: const BouncingScrollPhysics(),

        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },

        children: [
          _buildPage(
            imagePath: 'assets/images/onboarding_1.png',
            pageIndex: 0,
          ),

          _buildPage(
            imagePath: 'assets/images/onboarding_2.png',
            pageIndex: 1,
          ),

          _buildPage(
            imagePath: 'assets/images/onboarding_3.png',
            pageIndex: 2,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE
  // ============================================================

  Widget _buildPage({
    required String imagePath,
    required int pageIndex,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [

            // ==================================================
            // YOUR COMPLETE BACKGROUND IMAGE
            // ==================================================

            Image.asset(
              imagePath,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF031B49),
                  alignment: Alignment.center,
                  child: const Text(
                    'Background image not found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              },
            ),

            // ==================================================
            // VISIBLE CONTROLS
            // ==================================================

            _buildControls(
              width,
              height,
              pageIndex,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ALL CONTROLS
  // ============================================================

  Widget _buildControls(
    double width,
    double height,
    int pageIndex,
  ) {
    return Stack(
      children: [

        // ======================================================
        // SKIP
        // ======================================================

        if (pageIndex < 2)
  Positioned(
    top: height * 0.055,
    right: width * 0.055,
    child: TextButton(
      onPressed: _openLogin,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'Skip',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),

        // ======================================================
        // PAGE INDICATORS
        // ======================================================

        
        // ======================================================
        // PAGE 1 + PAGE 2
        // ======================================================

        if (pageIndex < 2)
          Positioned(
  left: width * 0.12,
  right: width * 0.12,
  bottom: height * 0.035,
  height: height * 0.055,
  child: _buildNextButton(),
),

        // ======================================================
        // PAGE 3 SIGN IN
        // ======================================================

        if (pageIndex == 2)
          Positioned(
  left: width * 0.12,
  right: width * 0.12,
  bottom: height * 0.070,
  height: height * 0.055,
  child: _buildSignInButton(),
),

        // ======================================================
        // PAGE 3 CREATE ACCOUNT
        // ======================================================

        if (pageIndex == 2)
          Positioned(
  left: width * 0.12,
  right: width * 0.12,
  bottom: height * 0.010,
  height: height * 0.050,
  child: _buildCreateAccountButton(),
),
      ],
    );
  }

  // ============================================================
  // DOT INDICATORS
  // ============================================================

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) {
          final bool selected = index == _currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),

            margin: const EdgeInsets.symmetric(
              horizontal: 4,
            ),

            width: selected ? 13 : 9,
            height: selected ? 13 : 9,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: selected
                  ? blue
                  : Colors.white.withOpacity(0.35),

              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 0.8,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // NEXT BUTTON
  // ============================================================

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextPage,

      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,

        elevation: 5,

        shadowColor: Colors.black.withOpacity(0.30),

        padding: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            'Next',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(width: 12),

          Icon(
            Icons.arrow_forward_rounded,
            size: 24,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIGN IN BUTTON
  // ============================================================

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _openLogin,

      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,

        elevation: 5,

        shadowColor: Colors.black.withOpacity(0.30),

        padding: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            'Sign In',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(width: 12),

          Icon(
            Icons.arrow_forward_rounded,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CREATE ACCOUNT BUTTON
  // ============================================================

  Widget _buildCreateAccountButton() {
    return OutlinedButton(
      onPressed: _openRegister,

      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,

        side: const BorderSide(
          color: lightBlue,
          width: 1.5,
        ),

        padding: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      child: const Text(
        'Create Account',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}