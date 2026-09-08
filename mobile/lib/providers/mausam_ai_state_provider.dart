import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the active operational state of Mausam AI Assistant.
enum MausamAiState {
  /// Assistant is waiting for user queries. Logo is still and calm.
  idle,

  /// Assistant is analyzing live weather data and formulating recommendation. Logo pulses/breathes.
  thinking,

  /// Assistant is actively streaming or presenting the response. Logo remains subtly animated.
  responding;

  bool get isIdle => this == MausamAiState.idle;
  bool get isThinking => this == MausamAiState.thinking;
  bool get isResponding => this == MausamAiState.responding;
  bool get isActive => this != MausamAiState.idle;
}

class MausamAiStateNotifier extends Notifier<MausamAiState> {
  @override
  MausamAiState build() => MausamAiState.idle;

  void setThinking() {
    state = MausamAiState.thinking;
  }

  void setResponding() {
    state = MausamAiState.responding;
  }

  void setIdle() {
    state = MausamAiState.idle;
  }
}

final mausamAiStateProvider =
    NotifierProvider<MausamAiStateNotifier, MausamAiState>(() {
  return MausamAiStateNotifier();
});
