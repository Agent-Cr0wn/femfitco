import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // Ensure this package is added and imported
import '../models/workout_plan.dart'; // Ensure this file exists and is imported
import '../../../common/constants/colors.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb and debugPrint

class ExerciseCard extends StatefulWidget {
  // Use correct type Exercise
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

// Use correct class VideoPlayerController
class _ExerciseCardState extends State<ExerciseCard> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _showVideo = false;

  final Map<String, String> _videoMap = {
    'exercise_squat_1': 'assets/videos/placeholder_video.mp4', // Make sure this asset exists
    'exercise_pushup_1': 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    'exercise_lunge_1': 'assets/videos/placeholder_video.mp4', // Make sure this asset exists
    'no_video_id': '',
    'error': '',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
     final videoPath = _videoMap[widget.exercise.videoPlaceholder];
     if (videoPath != null && videoPath.isNotEmpty) {
        Uri? videoUri = Uri.tryParse(videoPath);
         if (videoUri != null) {
            _controller = null; // Reset controller before initializing
            try {
               if (videoUri.isAbsolute && (videoUri.scheme == 'http' || videoUri.scheme == 'https')) {
                  _controller = VideoPlayerController.networkUrl(videoUri);
                  debugPrint("Initializing network video: $videoPath");
               } else if (!videoUri.isAbsolute && !kIsWeb && videoPath.startsWith('assets/')) {
                   _controller = VideoPlayerController.asset(videoPath);
                   debugPrint("Initializing asset video: $videoPath");
               } else if (kIsWeb && (videoUri.scheme == 'http' || videoUri.scheme == 'https')) {
                   _controller = VideoPlayerController.networkUrl(videoUri);
                   debugPrint("Initializing network video for web: $videoPath");
               } else {
                   debugPrint("Unsupported video URI scheme or platform: $videoPath");
               }

               if (_controller != null) {
                 // Assign future immediately
                 _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
                   _controller!.setLooping(true);
                   if (mounted) setState(() {});
                 }).catchError((error) {
                    debugPrint("Error initializing video player ($videoPath): $error");
                    if (mounted) setState(() { _controller = null; _initializeVideoPlayerFuture = null; });
                 });
                 // Trigger a rebuild to show loading indicator if needed
                 if (mounted) setState(() {});
               }
             } catch (e) { // Catch potential errors during controller creation
                debugPrint("Error creating video controller for $videoPath: $e");
                 if (mounted) setState(() { _controller = null; _initializeVideoPlayerFuture = null; });
             }
         } else { debugPrint("Invalid video URI: $videoPath"); }
     } else { debugPrint("No video path for placeholder: ${widget.exercise.videoPlaceholder}"); }
  }

  @override
  void dispose() {
    _controller?.dispose();
    debugPrint("Disposing video controller for ${widget.exercise.name}");
    super.dispose();
  }

   void _toggleVideoPlayback() {
     if (_controller != null && _controller!.value.isInitialized) {
        setState(() {
           _showVideo = !_showVideo;
           if (_showVideo) { _controller!.play(); } else { _controller!.pause(); }
        });
     } else {
        debugPrint("Cannot toggle video: Controller not initialized or null.");
         if (mounted) { // Check mounted before showing SnackBar
           ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Video not available."), duration: Duration(seconds: 2)), );
         }
     }
   }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;
    // Check _controller and _initializeVideoPlayerFuture for state
    final bool isInitializing = _initializeVideoPlayerFuture != null && _controller != null && !_controller!.value.isInitialized;
    final bool hasVideo = _controller != null && _controller!.value.isInitialized;
    final bool videoError = _controller == null && _initializeVideoPlayerFuture == null && _videoMap[widget.exercise.videoPlaceholder] != null && _videoMap[widget.exercise.videoPlaceholder]!.isNotEmpty; // Error if path exists but controller is null

    return InkWell(
      onTap: (hasVideo || videoError) ? _toggleVideoPlayback : null, // Allow tap if video exists or if there was an error loading it
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text( widget.exercise.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16), ),
                const SizedBox(height: 6),
                Text( 'Sets: ${widget.exercise.sets}   Reps: ${widget.exercise.reps}   Rest: ${widget.exercise.rest}', style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryGrey, fontSize: 13), ), ], ), ),
              const SizedBox(width: 8),
              Icon( hasVideo ? (_showVideo ? Icons.pause_circle_filled_outlined : Icons.play_circle_outline) : (isInitializing ? Icons.hourglass_empty : Icons.videocam_off_outlined), color: hasVideo ? AppColors.primaryWineRed : AppColors.lightGrey, size: 30, ), ], ),
            AnimatedSize( duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, child: _showVideo && hasVideo ? Padding( padding: const EdgeInsets.only(top: 12.0), child: Column( children: [
                AspectRatio( aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9,
                  // Use FutureBuilder to handle initialization state within the player widget itself
                  child: FutureBuilder(
                      future: _initializeVideoPlayerFuture,
                      builder:(context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
                           return VideoPlayer(_controller!); // Use correct class VideoPlayer
                         } else {
                           // Show placeholder or loading indicator while initializing here too
                           return Container(
                              color: Colors.black,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white54)))
                           );
                         }
                      },
                  ),
                ),
                // Use correct class VideoProgressIndicator
                VideoProgressIndicator( _controller!, allowScrubbing: true, padding: const EdgeInsets.only(top: 8.0),
                  // Use correct class VideoProgressColors
                  colors: const VideoProgressColors( playedColor: AppColors.primaryWineRed, bufferedColor: AppColors.lightGrey, backgroundColor: AppColors.backgroundGrey,),),
              ],), ) : const SizedBox.shrink(), ),
            // Show simple text message on initialization error if video was tapped
             if (_showVideo && videoError)
                Padding(
                   padding: const EdgeInsets.only(top: 12.0),
                   child: Text("Could not load video.", style: TextStyle(color: Colors.red.shade800, fontStyle: FontStyle.italic)),
                ),
          ],
        ),
      ),
    );
  }
}