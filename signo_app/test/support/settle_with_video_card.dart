import 'package:flutter_test/flutter_test.dart';

/// Pumps frames for a screen that has a video-backed sign on it.
///
/// A sign that ships a clip renders through [SignVideoPlayer], whose
/// `loading` state is a `LinearProgressIndicator` — an animation that never
/// ends while it is mounted. In the test environment `VideoPlayerController
/// .initialize()` never completes (no video platform is registered), so that
/// loading state is PERMANENT and `pumpAndSettle` can never settle on any
/// screen holding a video-backed card. It does not throw, it simply never
/// resolves.
///
/// So the rule for the learn/translator screens: settle normally while no
/// video card is mounted (the tree, the hub, the dictionary), and switch to
/// bounded pumps from the moment one is. The bound is deliberately generous —
/// it has to cover the route push, the async provider reads behind the screen
/// and the exercise build — but it is finite, so a genuinely stuck test still
/// fails instead of hanging for the full timeout.
///
/// Assertions about what a sign card CONTAINS belong on clip-less entries
/// (which bypass the player and render the text-mode card directly), not here:
/// with a video-backed entry the card is the loading indicator and its content
/// is unreachable in tests.
Future<void> settleWithVideoCard(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
