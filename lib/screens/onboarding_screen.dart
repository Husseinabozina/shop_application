import 'package:flutter/material.dart';
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
      description:
          'Explore the collection, save what you love, and make it yours.',
      icon: Icons.storefront_outlined,
      detail: 'Discover · Save · Explore',
    ),
    (
      title: 'Your basket, your way',
      description:
          'Review your basket, add a delivery address, and choose how to check out.',
      icon: Icons.shopping_bag_outlined,
      detail: 'A few favourites, all together',
    ),
    (
      title: 'Keep your orders close',
      description:
          'See your purchases and delivery details together in your account.',
      icon: Icons.receipt_long_outlined,
      detail: 'Your purchases, in one place',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
              child: Row(
                children: [
                  const BrandMark(size: 38),
                  const SizedBox(width: 10),
                  Text('MyShop',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  TextButton(
                      onPressed: _saving ? null : _finish,
                      child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _steps.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - 40)
                                .clamp(0, double.infinity)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 240,
                                height: (constraints.maxHeight * .42)
                                    .clamp(120, 240),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(48),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.rotate(
                                      angle: -.12,
                                      child: Container(
                                        width: 126,
                                        height: 142,
                                        decoration: BoxDecoration(
                                          color: colors.surfaceContainerLowest,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        child: Icon(step.icon,
                                            size: 72, color: colors.primary),
                                      ),
                                    ),
                                    Positioned(
                                      right: 30,
                                      top: 18,
                                      child: CircleAvatar(
                                        backgroundColor: colors.primary,
                                        child: Icon(
                                            index == 0
                                                ? Icons.favorite_border
                                                : Icons.check_rounded,
                                            color: colors.onPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(step.detail.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.primary,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Text(step.title,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w900, height: 1.12)),
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
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Semantics(
                    label: 'Step ${_page + 1} of ${_steps.length}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          _steps.length,
                          (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: index == _page ? 28 : 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    color: index == _page
                                        ? colors.primary
                                        : colors.outlineVariant,
                                    borderRadius: BorderRadius.circular(8)),
                              )),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child:
                          Text(_error!, style: TextStyle(color: colors.error)),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_page == _steps.length - 1) {
                                _finish();
                              } else {
                                _pages.nextPage(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic);
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_page == _steps.length - 1
                              ? 'Get started'
                              : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
