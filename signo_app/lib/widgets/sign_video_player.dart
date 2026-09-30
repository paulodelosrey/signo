import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Renders a sign clip from the asset bundle and owns the
/// [VideoPlayerController] lifecycle for it.
///
/// The widget is deliberately cadence-agnostic: it never starts a timer. The
/// translator screen already advances the sign index on its own periodic
/// timer, so playback simply restarts whenever [assetPath] changes. Looping
/// only repeats the CURRENT clip, it never moves the sequence forward.
///
/// Resilience: a clip declared in `VocabEntry` but absent (or undecodable) at
/// runtime makes [VideoPlayerController.initialize] throw. That is swallowed
/// and [fallback] is rendered instead, so a curation gap degrades to the
/// text-mode surface and never crashes the lesson.
class SignVideoPlayer extends StatefulWidget {
  const SignVideoPlayer({
    super.key,
    required this.assetPath,
    required this.fallback,
    this.loading,
    this.autoplay = false,
  });

  /// Bundle-relative path of the clip (e.g. `assets/videos/l1-001.mp4`).
  final String assetPath;

  /// Rendered while the clip loads and whenever it cannot be decoded.
  final Widget fallback;

  /// Rendered while [VideoPlayerController.initialize] is still in flight.
  ///
  /// It must NOT claim the sign has no clip: initialization takes about a
  /// second on a real device, and showing [fallback] meanwhile made every
  /// freshly-loaded sign flash a "video en curaduría" card before its clip
  /// appeared. Defaults to [fallback] when the caller has nothing better.
  final Widget? loading;

  /// Start playing as soon as the clip is ready. Off for compact option
  /// cards so a grid of answers never plays N clips at once.
  final bool autoplay;

  @override
  State<SignVideoPlayer> createState() => _SignVideoPlayerState();
}

class _SignVideoPlayerState extends State<SignVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load(widget.assetPath);
  }

  @override
  void didUpdateWidget(SignVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new sign means a new clip: tear the old controller down first so
    // controllers never accumulate across the lesson sequence.
    if (oldWidget.assetPath != widget.assetPath) {
      _load(widget.assetPath);
      return;
    }
    if (oldWidget.autoplay != widget.autoplay) {
      _syncPlayback();
    }
  }

  @override
  void dispose() {
    // Detach the listener before disposing so no callback fires on a dead
    // controller.
    final VideoPlayerController? controller = _controller;
    if (controller != null) {
      controller.removeListener(_onControllerChanged);
      controller.pause();
      controller.dispose();
      _controller = null;
    }
    super.dispose();
  }

  Future<void> _load(String assetPath) async {
    final VideoPlayerController? previous = _controller;
    _controller = null;
    if (previous != null) {
      previous.removeListener(_onControllerChanged);
      await previous.pause();
      await previous.dispose();
    }

    final VideoPlayerController controller =
        VideoPlayerController.asset(assetPath);
    try {
      await controller.initialize();
    } catch (_) {
      // Missing or corrupt clip: fall back, never crash.
      await controller.dispose();
      if (mounted) {
        setState(() => _failed = true);
      }
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    controller.addListener(_onControllerChanged);
    setState(() {
      _controller = controller;
      _failed = false;
    });
    _syncPlayback();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncPlayback() {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (widget.autoplay) {
      // Loop the current clip only: the sign cadence belongs to the screen.
      controller.setLooping(true);
      controller.play();
    } else {
      controller.setLooping(false);
      controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    if (_failed || controller == null || !controller.value.isInitialized) {
      // Distinguish "not ready yet" from "this sign has no clip": the second
      // one may say so, the first one must not.
      if (_controller == null && !_failed) {
        return widget.loading ?? widget.fallback;
      }
      return widget.fallback;
    }
    final VideoPlayerValue value = controller.value;
    // FittedBox scales the clip down to whatever box the caller offers and
    // can never overflow it, so portrait clips cannot break the Kinetic
    // layout that sizes the surrounding surface.
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: value.size.width,
        height: value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
