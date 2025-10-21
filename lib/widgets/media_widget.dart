import 'package:audioplayers/audioplayers.dart';
import 'package:edubee_app/data/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class MediaWidget extends StatefulWidget {
  final Question question;

  const MediaWidget({super.key, required this.question});

  @override
  State<MediaWidget> createState() => MediaWidgetState();
}

class MediaWidgetState extends State<MediaWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;
  Timer? _audioDelayTimer;
  bool _wasVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(MediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _disposeCurrentMedia();
      _initializeMedia();
    }
  }

  @override
  void dispose() {
    _disposeCurrentMedia();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// A getter to safely handle the asset path.
  String get _assetPath {
    if (widget.question.mediaUrl.isEmpty) return '';
    return widget.question.mediaUrl.startsWith('assets/')
        ? widget.question.mediaUrl.substring('assets/'.length)
        : widget.question.mediaUrl;
  }

  void _disposeCurrentMedia() {
    _audioDelayTimer?.cancel();
    _audioPlayer.stop();
    _videoController?.dispose();
    _videoController = null;
    _wasVideoPlaying = false;
  }

  void _initializeMedia() {
    if (widget.question.type == 'audio' && _assetPath.isNotEmpty) {
      _audioDelayTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          _audioPlayer.play(AssetSource(_assetPath));
        }
      });
    } else if (widget.question.type == 'video' && widget.question.mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.asset(widget.question.mediaUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });
    }
  }

  /// Renamed from _replayAudio for clarity. Plays audio from the beginning.
  void _playAudioFromStart() {
    _audioDelayTimer?.cancel();
    if (_assetPath.isNotEmpty) {
      _audioPlayer.stop(); // Stop first to ensure it plays from the start
      _audioPlayer.play(AssetSource(_assetPath));
    }
  }

  /// Called from QuestionScreen to pause everything when the quiz is paused.
  void stopPlayback() {
    _audioDelayTimer?.cancel();
    _audioPlayer.pause(); // Use pause to allow for resuming
    _wasVideoPlaying = _videoController?.value.isPlaying ?? false;
    _videoController?.pause();
  }

  /// Called from QuestionScreen to resume everything when the quiz is resumed.
  void resumePlayback() {
    if (widget.question.type == 'video' && _wasVideoPlaying) {
      _videoController?.play();
    } else if (widget.question.type == 'audio') {
      _audioPlayer.resume(); // Use resume to continue from where it was paused
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.question.type) {
      case 'image':
        return widget.question.mediaUrl.isNotEmpty
            ? Image.asset(widget.question.mediaUrl, height: 150)
            : const SizedBox.shrink();
      case 'video':
        return (_videoController?.value.isInitialized ?? false)
            ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
            : CircularProgressIndicator(color: theme.colorScheme.primary);

      case 'audio':
        return Column(
          children: [
            Icon(Icons.volume_up, color: theme.colorScheme.onSurface, size: 70),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                _AudioControlButton(icon: Icons.replay, onTap: _playAudioFromStart),
                const SizedBox(width: 20),
                _AudioControlButton(icon: Icons.stop, onTap: () => _audioPlayer.stop()),
              ],
            )
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _AudioControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AudioControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: buttonColor, width: 2),
        ),
        child: Icon(icon, color: buttonColor, size: 24),
      ),
    );
  }
}