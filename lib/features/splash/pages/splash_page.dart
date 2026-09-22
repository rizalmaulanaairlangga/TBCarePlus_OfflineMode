import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _exitController;

  late Animation<double> _bgOpacity;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _logoScaleEntrance;
  late Animation<double> _pulseScale;
  late Animation<Offset> _logoExitSlide;
  late Animation<double> _logoExitClip;
  late Animation<Offset> _bgExit;

  bool _showBackground = false;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Background fade 0 -> 1
    _bgOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Logo opacity 0 -> 1 with slight delay
    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.9, curve: Curves.easeOutCubic),
    ));

    _logoScaleEntrance = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // Pulse: 1.0 -> 1.22 -> 1.0
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    // Exit: logo geser sedikit ke atas (kecil) + wipe bottom->top, background geser ke atas
    // Semua pakai easeOutCubic agar langsung meluncur halus tanpa "nyangkut"
    _logoExitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.35),
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOutCubic,
    ));

    // Clip wipe: 1.0 -> 0.0 anchored di top, jadi logo terhapus dari bawah ke atas
    _logoExitClip = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _bgExit = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.0),
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOutCubic,
    ));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 1: full white for 280ms
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _showBackground = true);
    // small delay before logo appears
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showLogo = true);

    // Entrance animation: white -> background -> logo ease in ke atas
    await _entranceController.forward();
    if (!mounted) return;

    // Pulse: membesar lalu mengecil
    await _pulseController.forward();
    if (!mounted) return;

    // Hold briefly
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    // Exit: ease out ke atas dan background ke atas
    await _exitController.forward();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Widget _buildLogoWidget() {
    // Tambah padding luar agar shadow hijau tipis tidak terpotong di atas/bawah.
    // Container logo sendiri 180, beri outer padding 28 agar blur 40 terlihat utuh.
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(52),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/images/img_logo_app.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(double sw, double sh) {
    return Stack(
      children: [
        Container(color: Colors.white),
        // Scattered auras dari cover_page asli
        Positioned(
          top: -40,
          left: -40,
          child: _buildAura(100, AppColors.primary.withValues(alpha: 0.08)),
        ),
        Positioned(
          top: sh * 0.2,
          right: -60,
          child: _buildAura(80, AppColors.primary.withValues(alpha: 0.06)),
        ),
        Positioned(
          bottom: sh * 0.2,
          left: -60,
          child: _buildAura(70, AppColors.accent.withValues(alpha: 0.06)),
        ),
        Positioned(
          top: sh * 0.5,
          left: sw * 0.4,
          child: _buildAura(60, AppColors.primary.withValues(alpha: 0.05)),
        ),
      ],
    );
  }

  Widget _buildAura(double size, Color color) {
    return Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full white base is Scaffold background

          // Background dari source asli, muncul setelah delay
          if (_showBackground)
            SlideTransition(
              position: _bgExit,
              child: FadeTransition(
                opacity: _bgOpacity,
                child: _buildBackground(sw, sh),
              ),
            ),

          // Logo animation — exit: slide kecil ke atas + ClipRect wipe bottom->top
          if (_showLogo)
            Center(
              child: SlideTransition(
                position: _logoExitSlide,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: SlideTransition(
                    position: _logoSlide,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _entranceController,
                        _pulseController,
                        _exitController,
                      ]),
                      builder: (context, child) {
                        double scale = _logoScaleEntrance.value;
                        if (_entranceController.isCompleted) {
                          scale = scale * _pulseScale.value;
                        }
                        final clipFactor = _exitController.isAnimating ||
                                _exitController.isCompleted
                            ? _logoExitClip.value.clamp(0.0, 1.0)
                            : 1.0;
                        // Selama entrance/pulse jangan pakai ClipRect agar shadow hijau tidak terpotong.
                        // Clip hanya dipakai saat exit wipe bottom->top.
                        if (clipFactor >= 0.999) {
                          return Transform.scale(scale: scale, child: child);
                        }
                        return Transform.scale(
                          scale: scale,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: clipFactor,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _buildLogoWidget(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
