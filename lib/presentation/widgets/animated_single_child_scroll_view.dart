import 'package:fluent_ui/fluent_ui.dart';
import 'package:scroll_animator/scroll_animator.dart';

class AnimatedSingleChildScrollView extends StatefulWidget {
  const AnimatedSingleChildScrollView({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedSingleChildScrollView> createState() => _AnimatedSingleChildScrollViewState();
}

class _AnimatedSingleChildScrollViewState extends State<AnimatedSingleChildScrollView> {
  late final AnimatedScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: widget.child,
    );
  }
}
