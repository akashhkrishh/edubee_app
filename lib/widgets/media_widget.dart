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

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  void _initializeMedia() {
    if (widget.question.type == 'audio' && widget.question.mediaUrl.isNotEmpty) {
      final String assetPath = widget.question.mediaUrl.replaceFirst('assets/', '');
      _audioDelayTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _audioPlayer.play(AssetSource(assetPath));
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

  void _replayAudio() {
    _audioDelayTimer?.cancel();
    if (widget.question.mediaUrl.isNotEmpty) {
      final String assetPath = widget.question.mediaUrl.replaceFirst('assets/', '');
      _audioPlayer.stop();
      _audioPlayer.play(AssetSource(assetPath));
    }
  }

  void stopPlayback() {
    _audioDelayTimer?.cancel();
    if (widget.question.type == 'audio') {
      _audioPlayer.stop();
    } else if (widget.question.type == 'video') {
      _videoController?.pause();
    }
  }

  @override
  void dispose() {
    _audioDelayTimer?.cancel();
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.type != widget.question.type || oldWidget.question.mediaUrl != widget.question.mediaUrl) {
      _audioDelayTimer?.cancel();
      stopPlayback();
      _initializeMedia();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.question.type) {
      case 'image':
        return widget.question.mediaUrl.isNotEmpty
            ? SizedBox(
          width: 300,
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              widget.question.mediaUrl,
              fit: BoxFit.contain,
              semanticLabel: widget.question.secondaryQuestion,
            ),
          ),
        )
            : const SizedBox.shrink();
      case 'video':
        return Semantics(
          label: widget.question.secondaryQuestion,
          child: _videoController != null && _videoController!.value.isInitialized
              ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )
              : Container(
            height: 200,
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      case 'audio':
        return Semantics(
          label: widget.question.secondaryQuestion,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.audiotrack, size: 50),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _replayAudio,
                icon: const Icon(Icons.replay),
                label: const Text('Replay Audio'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'text':
      default:
        return const SizedBox.shrink();
    }
  }
}