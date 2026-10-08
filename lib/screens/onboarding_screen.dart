import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_application/widgets/brand_mark.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onCompleted});
  final Future<void> Function() onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _saving = false;
  String? _error;

  static const _steps = [
    (
      title: 'Find your next favourite',
      accent: 'favourite',
      description:
          'Everyday essentials. Unexpected finds.\nA little something that feels like you.',
      asset: 'assets/onboarding/discover.png',
      chapter: 'Discover',
      detail: 'GOOD FINDS START HERE',
      badge: 'Find it. Love it. Save it.',
      icon: Icons.favorite_outline_rounded,
      tint: Color(0xFFF2DFD0),
    ),
    (
      title: 'Your basket, your way',
      accent: 'your way',
      description:
          'Bring your favourites together.\nChoose your address and how to check out.',
      asset: 'assets/onboarding/basket.png',
      chapter: 'Make it yours',
      detail: 'ALL YOUR FAVOURITES, TOGETHER',
      badge: 'One basket. All your favourites.',
      icon: Icons.shopping_bag_outlined,
      tint: Color(0xFFE7E8DA),
    ),
    (
      title: 'Keep your orders close',
      accent: 'close',
      description:
          'Your purchases and delivery details,\nbeautifully organised in one place.',
      asset: 'assets/onboarding/orders.png',
      chapter: 'Stay organised',
      detail: 'THE GOOD FEELING CONTINUES',
      badge: 'Your orders, always together.',
      icon: Icons.inventory_2_outlined,
      tint: Color(0xFFF0E2D5),
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (_saving || page < 0 || page >= _steps.length) return;
    HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onCompleted();
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not save your preferences. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final motion =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 300);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                child: Row(children: [
                  const BrandMark(size: 34),
                  const SizedBox(width: 9),
                  Text('MyShop',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900, letterSpacing: -.7)),
                  const Spacer(),
                  TextButton(
                      onPressed: _saving ? null : _finish,
                      child: const Text('Skip')),
                ]),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  physics:
                      _saving ? const NeverScrollableScrollPhysics() : null,
                  itemCount: _steps.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return LayoutBuilder(builder: (context, constraints) {
                      final compact = constraints.maxHeight < 540;
                      final artSize = (constraints.maxHeight * .54)
                          .clamp(150.0, 350.0)
                          .clamp(0.0, constraints.maxWidth - 36);
                      return SingleChildScrollView(
                        key: PageStorageKey('onboarding-page-$index'),
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight - 28)
                                  .clamp(0, double.infinity)),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 750),
                            curve: Curves.easeOutCubic,
                            builder: (context, entrance, child) => Opacity(
                                opacity: entrance,
                                child: Transform.translate(
                                    offset: Offset(0, 22 * (1 - entrance)),
                                    child: child)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                    child: AnimatedBuilder(
                                  animation: _pages,
                                  builder: (context, child) {
                                    final distance =
                                        reduceMotion || !_pages.hasClients
                                            ? 0.0
                                            : ((_pages.page ?? 0) - index)
                                                .clamp(-1.0, 1.0);
                                    return Transform.translate(
                                        offset: Offset(distance * 32, 0),
                                        child: Transform.rotate(
                                            angle: distance * .045,
                                            child: Transform.scale(
                                                scale: 1 - distance.abs() * .08,
                                                child: child)));
                                  },
                                  child: _OnboardingArtwork(
                                      asset: step.asset,
                                      tint: step.tint,
                                      size: artSize,
                                      badge: step.badge,
                                      icon: step.icon),
                                )),
                                SizedBox(height: compact ? 24 : 32),
                                Text(step.detail,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: colors.primary,
                                        letterSpacing: 1.8,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 12),
                                Semantics(
                                    header: true,
                                    child: Text.rich(
                                        TextSpan(children: [
                                          TextSpan(
                                              text: step.title.substring(
                                                  0,
                                                  step.title.length -
                                                      step.accent.length)),
                                          TextSpan(
                                              text: step.accent,
                                              style: TextStyle(
                                                  color: colors.primary)),
                                        ]),
                                        style: theme.textTheme.headlineLarge
                                            ?.copyWith(
                                                fontSize: compact ? 32 : 38,
                                                letterSpacing: -1.5,
                                                fontWeight: FontWeight.w900,
                                                height: 1.08))),
                                const SizedBox(height: 16),
                                Text(step.description,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        height: 1.5)),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label:
                            'Step ${_page + 1} of ${_steps.length}: ${_steps[_page].chapter}',
                        liveRegion: true,
                        child: ExcludeSemantics(
                            child: Row(children: [
                          Expanded(
                              child: Text(_steps[_page].chapter,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700))),
                          Text('0${_page + 1}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w900)),
                          Text(' / 03',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ])),
                      ),
                      const SizedBox(height: 10),
                      Row(
                          children: List.generate(
                              _steps.length,
                              (index) => Expanded(
                                    child: AnimatedContainer(
                                        duration: motion,
                                        height: 3,
                                        margin: EdgeInsets.only(
                                            right: index == _steps.length - 1
                                                ? 0
                                                : 6),
                                        decoration: BoxDecoration(
                                            color: index <= _page
                                                ? colors.primary
                                                : colors.outlineVariant
                                                    .withValues(alpha: .5),
                                            borderRadius:
                                                BorderRadius.circular(4))),
                                  ))),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(_error!,
                                    style: TextStyle(color: colors.error)))),
                      const SizedBox(height: 20),
                      Row(children: [
                        if (_page > 0) ...[
                          IconButton.outlined(
                              onPressed:
                                  _saving ? null : () => _goTo(_page - 1),
                              tooltip: 'Previous page',
                              style: IconButton.styleFrom(
                                  minimumSize: const Size(56, 56),
                                  side:
                                      BorderSide(color: colors.outlineVariant)),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  size: 22)),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                            child: FilledButton(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              shape: const StadiumBorder()),
                          onPressed: _saving
                              ? null
                              : () {
                                  if (_page == _steps.length - 1) {
                                    _finish();
                                  } else {
                                    _goTo(_page + 1);
                                  }
                                },
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Flexible(
                                          child: Text(_page == _steps.length - 1
                                              ? 'Get started'
                                              : 'Continue')),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 20),
                                    ]),
                        )),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OnboardingArtwork extends StatelessWidget {
  const _OnboardingArtwork(
      {required this.asset,
      required this.tint,
      required this.size,
      required this.badge,
      required this.icon});
  final String asset;
  final Color tint;
  final double size;
  final String badge;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size + 16,
        child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                  left: 12,
                  right: 12,
                  top: 0,
                  bottom: 26,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: dark
                              ? Color.lerp(
                                  colors.surfaceContainerHigh, tint, .1)
                              : tint,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(size / 2),
                              bottom: const Radius.circular(60))))),
              Positioned.fill(
                  top: 8,
                  bottom: 18,
                  child: Image.asset(asset,
                      fit: BoxFit.contain,
                      cacheWidth: 1050,
                      excludeFromSemantics: true)),
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                      child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color:
                                colors.outlineVariant.withValues(alpha: .25)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: dark ? .12 : .06),
                              blurRadius: 20,
                              offset: const Offset(0, 8))
                        ]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 15, color: colors.primary),
                      const SizedBox(width: 7),
                      Flexible(
                          child: Text(badge,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface))),
                    ]),
                  ))),
            ]),
      ),
    );
  }
}
