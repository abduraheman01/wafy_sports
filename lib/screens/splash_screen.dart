import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sports_app/screens/home_screen.dart';
import 'package:sports_app/config/app_config.dart';
import 'package:sports_app/widgets/safe_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _showVideo = false;
  bool _videoError = false;

  late AnimationController _fallbackController;
  late Animation<double> _fallbackAnimation;

  @override
  void initState() {
    super.initState();

    _fallbackController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fallbackAnimation = CurvedAnimation(
      parent: _fallbackController,
      curve: Curves.easeInOut,
    );

    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      if (kIsWeb) {
        // For web, try to load video but have fallback ready
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse('assets/videos/splash_video.mp4'), // This might not work on web
        );
      } else {
        // For mobile platforms
        _videoController = VideoPlayerController.asset('assets/videos/splash_video.mp4');
      }

      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _showVideo = true;
        });

        _videoController!.play();
        _videoController!.setLooping(false);

        _videoController!.addListener(() {
          if (_videoController!.value.position >= _videoController!.value.duration) {
            _navigateToHome();
          }
        });
      }
    } catch (e) {
      // Fallback for web or if video fails to load
      if (mounted) {
        setState(() {
          _videoError = true;
        });
        _startFallbackAnimation();
      }
    }
  }

  void _startFallbackAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fallbackController.forward();

    await Future.delayed(const Duration(milliseconds: 3500));
    _navigateToHome();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _fallbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = AppConfig.isWeb(size.width);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player or fallback
            if (_showVideo && _videoController != null && !_videoError) ...[
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ] else ...[
              // Elegant fallback with branding
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1a1a2e),
                      Color(0xFF16213e),
                      Color(0xFF0f3460),
                    ],
                  ),
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _fallbackAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with animation
                        ScaleTransition(
                          scale: _fallbackAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logored.png',
                              width: isWeb ? 200 : 160,
                              height: isWeb ? 200 : 160,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: isWeb ? 60 : 40),
                        // Text with glow effect
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_fallbackAnimation),
                          child: Column(
                            children: [
                              // Simple championship badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppConfig.accentColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '⚽ FOOTBALL CHAMPIONSHIP ⚽',
                                  style: TextStyle(
                                    fontSize: isWeb ? 14 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppConfig.secondaryColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              // Simple main title
                              Text(
                                'SPORTIFY',
                                style: TextStyle(
                                  fontSize: isWeb ? 42 : 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isWeb ? 20 : 16),
                              // Subtitle with enhanced styling
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'YOUR MUSIC-POWERED SPORTS HUB',
                                  style: TextStyle(
                                    fontSize: isWeb ? 16 : 12,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Loading indicator for video
            if (!_showVideo && !_videoError)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),

            // Tap to skip
            Positioned(
              bottom: 50,
              right: 30,
              child: GestureDetector(
                onTap: _navigateToHome,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Skip →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}