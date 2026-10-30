import 'package:flutter/material.dart';

/// Provides a shared shimmer animation controller and styling to nested skeleton widgets.
class SkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.grey.shade300);
    final highlight = widget.highlightColor ??
        (isDark
            ? Theme.of(context).colorScheme.surfaceBright
            : Colors.grey.shade100);

    return SkeletonShimmerScope(
      animation: _controller,
      baseColor: base,
      highlightColor: highlight,
      child: widget.child,
    );
  }
}

/// InheritedWidget that shares the shimmer animation and theme colors down the tree.
class SkeletonShimmerScope extends InheritedWidget {
  final Animation<double> animation;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonShimmerScope({
    super.key,
    required this.animation,
    required this.baseColor,
    required this.highlightColor,
    required super.child,
  });

  static SkeletonShimmerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SkeletonShimmerScope>();
  }

  @override
  bool updateShouldNotify(SkeletonShimmerScope oldWidget) {
    return oldWidget.animation != animation ||
        oldWidget.baseColor != baseColor ||
        oldWidget.highlightColor != highlightColor;
  }
}

/// A gradient transform that translates the linear gradient horizontally based on [slidePercent].
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Translate from -bounds.width to +bounds.width * 2
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// A foundational skeleton element that renders a shimmering box.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.padding,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hasScope = SkeletonShimmerScope.of(context) != null;
    if (!hasScope && _localController == null) {
      _localController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();
    } else if (hasScope && _localController != null) {
      _localController!.dispose();
      _localController = null;
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = SkeletonShimmerScope.of(context);
    final animation = scope?.animation ?? _localController!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        scope?.baseColor ??
        (isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.grey.shade300);
    final highlight = widget.highlightColor ??
        scope?.highlightColor ??
        (isDark
            ? Theme.of(context).colorScheme.surfaceBright
            : Colors.grey.shade100);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // slidePercent translates from -1.5 to +1.5 across the animation cycle
        final slidePercent = -1.5 + (animation.value * 3.0);

        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? (widget.borderRadius ?? BorderRadius.circular(4))
                : null,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: slidePercent),
            ),
          ),
        );
      },
    );
  }
}

/// A convenience widget for rendering skeleton text lines.
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      margin: margin,
    );
  }
}

/// Skeleton representation of an [ArticleCard].
class ArticleCardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const ArticleCardSkeleton({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          margin: margin ??
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 110,
                  height: 110,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      // Title line 1
                      SkeletonLine(
                        width: double.infinity,
                        height: 16,
                      ),
                      SizedBox(height: 8),
                      // Title line 2
                      SkeletonLine(
                        width: 180,
                        height: 16,
                      ),
                      SizedBox(height: 16),
                      // Date
                      SkeletonLine(
                        width: 90,
                        height: 12,
                      ),
                      SizedBox(height: 8),
                      // Author
                      SkeletonLine(
                        width: 130,
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton screen for an article list.
class ArticleListSkeleton extends StatelessWidget {
  final int itemCount;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  const ArticleListSkeleton({
    super.key,
    this.itemCount = 6,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.shrinkWrap = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemCount: itemCount,
        itemBuilder: (context, index) => const ArticleCardSkeleton(),
      ),
    );
  }
}

/// Full-page skeleton screen for the article detail view.
class ArticleDetailSkeleton extends StatelessWidget {
  const ArticleDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge and date row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(
                        width: 90,
                        height: 22,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      SkeletonLine(
                        width: 80,
                        height: 13,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Headline lines
                  SkeletonLine(
                    width: double.infinity,
                    height: 24,
                  ),
                  SizedBox(height: 8),
                  SkeletonLine(
                    width: double.infinity,
                    height: 24,
                  ),
                  SizedBox(height: 8),
                  SkeletonLine(
                    width: 220,
                    height: 24,
                  ),
                  SizedBox(height: 18),

                  // Author chip
                  SkeletonBox(
                    width: 140,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  SizedBox(height: 18),

                  // Hero featured image
                  SkeletonBox(
                    width: double.infinity,
                    height: 220,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  SizedBox(height: 24),

                  // Body paragraph 1
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: 200, height: 14),
                  SizedBox(height: 20),

                  // Body paragraph 2
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: 280, height: 14),
                  SizedBox(height: 20),

                  // Body paragraph 3
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: 160, height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton screen for the [AboutScreen].
class AboutScreenSkeleton extends StatelessWidget {
  const AboutScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // About Title
                    SkeletonBox(
                      width: 110,
                      height: 32,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    SizedBox(height: 20),

                    // Paragraph 1
                    SkeletonLine(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: 260, height: 14),
                    SizedBox(height: 24),

                    // Paragraph 2
                    SkeletonLine(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: 190, height: 14),
                    SizedBox(height: 24),

                    // Paragraph 3
                    SkeletonLine(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(width: 220, height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for the related articles section in [ArticleDetailScreen].
class RelatedArticlesSkeleton extends StatelessWidget {
  const RelatedArticlesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(15, 8, 15, 12),
            child: SkeletonBox(
              width: 160,
              height: 22,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          ArticleCardSkeleton(
            margin: EdgeInsets.only(bottom: 10),
          ),
          ArticleCardSkeleton(
            margin: EdgeInsets.only(bottom: 10),
          ),
        ],
      ),
    );
  }
}
