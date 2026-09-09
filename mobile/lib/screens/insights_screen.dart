import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/routine_reminder.dart';
import '../models/weather_ai_card_data.dart';
import '../providers/auth_provider.dart';
import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/mausam_ai_state_provider.dart';
import '../providers/routine_reminder_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../services/activity_recommendation_engine.dart';
import '../services/notification_service.dart';
import '../services/routine_intent_parser.dart';
import '../services/routine_reminder_scheduler.dart';
import '../services/weather_ai_engine.dart';
import '../theme/weather_palette.dart';
import '../widgets/ai/active_routine_reminder_card.dart';
import '../widgets/ai/chat_atmosphere_background.dart';
import '../widgets/ai/initial_chat_animated_logo.dart';
import '../widgets/ai/routine_recommendation_card.dart';
import '../widgets/ai/weather_intelligence_card.dart';

class _ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isError;
  final DateTime timestamp;
  final bool isStreaming;
  final List<String>? followUps;
  final ActivityRecommendation? recommendation;
  final RoutineReminder? reminder;
  final WeatherAiCardData? cardData;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isError = false,
    required this.timestamp,
    this.isStreaming = false,
    this.followUps,
    this.recommendation,
    this.reminder,
    this.cardData,
  });

  bool get isAssistant => !isUser && !isError;

  _ChatMessage copyWith({
    String? text,
    bool? isStreaming,
    List<String>? followUps,
    bool? isError,
    ActivityRecommendation? recommendation,
    RoutineReminder? reminder,
    WeatherAiCardData? cardData,
  }) {
    return _ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      isError: isError ?? this.isError,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      followUps: followUps ?? this.followUps,
      recommendation: recommendation ?? this.recommendation,
      reminder: reminder ?? this.reminder,
      cardData: cardData ?? this.cardData,
    );
  }
}

/// Premier Weather AI Assistant Chatbot for Mausam (`/insights`).
///
/// Fully incorporates all 18 UX requirements:
/// - Chatbot Identity Logo rule: avatar ONLY on the first assistant message of a sequence.
/// - Progressive dynamic loading state ("Checking the weather..." -> "Analyzing the forecast..." -> "Still checking...").
/// - Realistic streaming responses with subtle typing cursor `▌` and instant Stop / Cancel generation.
/// - Weather-specific structured formatting (rain chance, temperature, AQI, bullet highlights, advice).
/// - Intelligent auto-scroll with user-scroll detection and floating "↓ New response" button.
/// - Rounded capsule input dock with Enter to send / Shift+Enter for newline, rotating hints, and keyboard handling.
/// - Rich Welcome state with capability introduction and 6 clickable weather suggestion chips.
/// - Error handling with "Try again" retry action.
/// - Copy response with instant checkmark feedback.
/// - Desktop/tablet readable constraint centering (max width 768px).
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;
  bool _isStreaming = false;
  int _loadingElapsedSeconds = 0;
  Timer? _generationDelayTimer;
  Timer? _loadingTimer;
  Timer? _streamTimer;
  Timer? _focusScrollTimer;
  String? _lastUserQuery;

  bool _userScrolledAwayFromBottom = false;

  // Placeholder rotating animation
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;
  final List<String> _placeholders = const [
    'Ask about the weather...',
    'Remind me at 9 PM to walk tomorrow...',
    'Will it rain today?',
    'Best time for walking tomorrow?',
    'Should I carry an umbrella?',
    'What should I wear tonight?',
    'Weekend forecast in detail...',
  ];

  // Copied message tracker for quick visual confirmation
  String? _copiedMessageId;
  Timer? _copiedResetTimer;

  late final AnimationController _pulseAnim;

  // Welcome state suggestions settled above search bar
  final List<({String icon, String label, String query})> _welcomePrompts = const [
    (icon: '🌧️', label: 'Will it rain today?', query: 'Will it rain today in my area?'),
    (icon: '📅', label: 'Weather tomorrow', query: 'What is the full weather forecast for tomorrow?'),
    (icon: '☔', label: 'Carry an umbrella?', query: 'Should I carry an umbrella today? What is the rain chance?'),
    (icon: '🌤️', label: 'Weekend forecast', query: 'Give me the weekend weather outlook and outdoor conditions.'),
    (icon: '🏃', label: 'Best workout window', query: 'When is the best time for an outdoor workout tomorrow morning?'),
    (icon: '😷', label: 'Air quality check', query: 'Check current air quality and pollution levels for outdoor safety.'),
    (icon: '⏰', label: 'Daily walking reminder', query: 'Every day at 9:00 PM, remind me what time I should go walking tomorrow.'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _pulseAnim.repeat(reverse: true);
    } else {
      _pulseAnim.value = 0.5;
    }

    _scrollController.addListener(_onScrollChanged);

    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus && !isTest) {
        _focusScrollTimer?.cancel();
        _focusScrollTimer = Timer(const Duration(milliseconds: 220), () {
          if (mounted) _scrollToBottom();
        });
      }
    });

    _placeholderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _controller.text.isEmpty) {
        setState(() {
          _placeholderIndex = (_placeholderIndex + 1) % _placeholders.length;
        });
      }
    });

    NotificationService.pendingNotificationQuery.addListener(_checkPendingNotificationQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotificationQuery();
    });
  }

  void _checkPendingNotificationQuery() {
    final query = NotificationService.pendingNotificationQuery.value;
    if (query != null && query.isNotEmpty) {
      NotificationService.pendingNotificationQuery.value = null;
      if (mounted) {
        _handleSubmitted(query);
      }
    }
  }

  @override
  void dispose() {
    NotificationService.pendingNotificationQuery.removeListener(_checkPendingNotificationQuery);
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _controller.dispose();
    _inputFocusNode.dispose();
    _pulseAnim.dispose();
    _focusScrollTimer?.cancel();
    _generationDelayTimer?.cancel();
    _loadingTimer?.cancel();
    _streamTimer?.cancel();
    _placeholderTimer?.cancel();
    _copiedResetTimer?.cancel();
    try {
      ref.read(mausamAiStateProvider.notifier).setIdle();
    } catch (_) {}
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Safely clear in-memory state during development hot-reloads
    _messages.clear();
    _isThinking = false;
    _isStreaming = false;
    _generationDelayTimer?.cancel();
    _loadingTimer?.cancel();
    _streamTimer?.cancel();
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final extentAfter = _scrollController.position.extentAfter;
    final isAway = extentAfter > 70;
    if (isAway != _userScrolledAwayFromBottom) {
      setState(() {
        _userScrolledAwayFromBottom = isAway;
      });
    }
  }

  void _scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (smooth) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _handleSubmitted(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isThinking || _isStreaming) return;

    _lastUserQuery = trimmed;
    _controller.clear();

    final userMsg = _ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
      _loadingElapsedSeconds = 0;
      _userScrolledAwayFromBottom = false;
    });
    ref.read(mausamAiStateProvider.notifier).setThinking();

    _scrollToBottom();

    // Progressive loading status timer
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isThinking) {
        setState(() {
          _loadingElapsedSeconds++;
        });
      }
    });

    // Managed generation delay timer
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final waitMs = isTest ? 60 : 850;

    _generationDelayTimer?.cancel();
    _generationDelayTimer = Timer(Duration(milliseconds: waitMs), () async {
      if (!mounted) return;
      _loadingTimer?.cancel();

      // Check for direct notification permission query
      if (trimmed.toLowerCase() == 'enable notifications' || trimmed.toLowerCase() == 'allow notifications') {
        final granted = await RoutineReminderScheduler.requestPermissions();
        final text = granted
            ? '✅ Mobile notification permissions are **granted**! You will receive daily weather and routine alerts directly in your phone\'s system tray.'
            : '⚠️ Notification permission is still disabled in system settings. Please open phone Settings > Apps > Mausam > Notifications and toggle them on.';
        _startStreamingResponse(text, followUps: ['My active reminders', 'Weather tomorrow', 'Will it rain today?']);
        return;
      }

      // Check for routine & activity intelligence intent first
      final routineIntent = RoutineIntentParser.parse(trimmed);
      if (routineIntent.type != RoutineIntentType.none) {
        final result = await _handleRoutineIntent(routineIntent);
        if (!mounted) return;
        _startStreamingResponse(
          result.text,
          followUps: result.followUps,
          recommendation: result.recommendation,
          reminder: result.reminder,
        );
        return;
      }

      final userState = ref.read(userProvider);
      final dash = ref.read(weatherDashboardProvider);
      final locationState = ref.read(locationProvider);
      final locName = locationState.cityName.isNotEmpty
          ? locationState.cityName.split(',').first.trim()
          : (dash.data?.current.location ?? 'Active Location');

      // 1. Compute on-device offline fallback upfront
      final offlineFallback = WeatherAiEngine.process(
        query: trimmed,
        userState: userState,
        dashboard: dash.data,
        locationName: locName,
      );

      String responseText = offlineFallback.text;
      List<String> responseFollowUps = offlineFallback.followUps;
      WeatherAiCardData? responseCardData = offlineFallback.cardData;

      // 2. Query backend Gemini LLM (in non-test mode or when custom mock ApiClient is provided)
      final apiClient = ref.read(apiClientProvider);
      final shouldUseBackend = !isTest || apiClient.runtimeType.toString() != 'ApiClient';

      if (shouldUseBackend) {
        try {
          final lat = locationState.latitude != 0.0
              ? locationState.latitude
              : 12.9716;
          final lon = locationState.longitude != 0.0
              ? locationState.longitude
              : 77.5946;
          final idToken = userState.idToken ?? 'test_token';

          // Extract last 6 conversation turns for multi-turn context
          final history = _messages
              .where((m) => !m.isError && m.text.isNotEmpty)
              .take(6)
              .map((m) => {
                    'role': m.isUser ? 'user' : 'assistant',
                    'content': m.text,
                  })
              .toList();

          final savedLocationsPayload = locationState.savedLocations
              .map((l) => {
                    'name': l.name,
                    'latitude': l.latitude,
                    'longitude': l.longitude,
                  })
              .toList();

          final backendRes = await apiClient.sendChatMessage(
            text: trimmed,
            lat: lat,
            lon: lon,
            persona: userState.selectedPersona,
            healthConcerns: userState.healthConcerns,
            activeLocationName: locName,
            savedLocations: savedLocationsPayload,
            history: history,
            idToken: idToken,
          );

          final reply = backendRes['reply'] as String?;
          if (reply != null && reply.trim().isNotEmpty) {
            responseText = reply.trim();
            final actions = backendRes['suggested_actions'];
            if (actions is List && actions.isNotEmpty) {
              responseFollowUps = actions.map((e) => e.toString()).toList();
            }
            final rawCard = backendRes['card_data'];
            if (rawCard is Map<String, dynamic>) {
              try {
                responseCardData = WeatherAiCardData.fromJson(rawCard);
              } catch (e) {
                debugPrint('[InsightsScreen] Card parsing error: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('[InsightsScreen] Backend chat failed, falling back to offline engine: $e');
        }
      }

      if (!mounted) return;

      _startStreamingResponse(
        responseText,
        followUps: responseFollowUps,
        cardData: responseCardData,
      );
    });
  }

  Future<({
    String text,
    List<String> followUps,
    ActivityRecommendation? recommendation,
    RoutineReminder? reminder,
  })> _handleRoutineIntent(RoutineIntentResult intent) async {
    final dash = ref.read(weatherDashboardProvider);
    final userState = ref.read(userProvider);
    final locationState = ref.read(locationProvider);
    final locName = locationState.cityName.isNotEmpty
        ? locationState.cityName.split(',').first.trim()
        : (dash.data?.current.location ?? 'your area');

    if (intent.type == RoutineIntentType.listReminders) {
      final activeReminders = ref.read(routineReminderProvider);
      if (activeReminders.isEmpty) {
        return (
          text: 'You do not have any active routine reminders set right now.\n\n'
              'Try saying: *"Every day at 9:00 PM, remind me what time I should go walking tomorrow."*',
          followUps: ['Set 9 PM walking reminder', 'Best time for walking tomorrow'],
          recommendation: null,
          reminder: null,
        );
      }
      final latest = activeReminders.first;
      return (
        text: 'Here is your active routine reminder schedule for $locName:',
        followUps: ['Best time for walking tomorrow', 'Pause this reminder'],
        recommendation: null,
        reminder: latest,
      );
    }

    if (intent.rawQuery.toLowerCase().contains('pause') &&
        (intent.rawQuery.toLowerCase().contains('reminder') || intent.rawQuery.toLowerCase().contains('schedule'))) {
      final activeReminders = ref.read(routineReminderProvider);
      if (activeReminders.isNotEmpty) {
        final target = activeReminders.first;
        await ref.read(routineReminderProvider.notifier).togglePauseResume(target.id);
        return (
          text: 'I have paused your daily **${target.activity}** reminder for **${target.reminderTimeDisplay}**. No notifications will be sent while paused.',
          followUps: ['Resume this reminder', 'My active reminders'],
          recommendation: null,
          reminder: null,
        );
      }
    }

    if (intent.rawQuery.toLowerCase().contains('resume') &&
        (intent.rawQuery.toLowerCase().contains('reminder') || intent.rawQuery.toLowerCase().contains('schedule'))) {
      final reminders = ref.read(routineReminderProvider);
      if (reminders.isNotEmpty) {
        final target = reminders.first;
        await ref.read(routineReminderProvider.notifier).togglePauseResume(target.id);
        return (
          text: 'I have resumed your daily **${target.activity}** reminder for **${target.reminderTimeDisplay}**. Notifications are active again.',
          followUps: ['Tomorrow\'s activity window', 'My active reminders'],
          recommendation: null,
          reminder: null,
        );
      }
    }

    if (intent.type == RoutineIntentType.deleteReminder) {
      final activeReminders = ref.read(routineReminderProvider);
      if (activeReminders.isNotEmpty) {
        final toDelete = activeReminders.first;
        await ref.read(routineReminderProvider.notifier).deleteReminder(toDelete.id);
        return (
          text: 'I have deleted your daily **${toDelete.activity}** reminder scheduled for **${toDelete.reminderTimeDisplay}**.',
          followUps: ['Set new reminder', 'Weather forecast tomorrow'],
          recommendation: null,
          reminder: null,
        );
      } else {
        return (
          text: 'You do not have any active routine reminders to delete.',
          followUps: ['Set 9 PM walking reminder'],
          recommendation: null,
          reminder: null,
        );
      }
    }

    ActivityRecommendation? rec;
    if (intent.isRecommendationIntent) {
      rec = ActivityRecommendationEngine.calculateRecommendation(
        dashboardData: dash.data,
        userState: userState,
        activity: intent.activity,
        targetPeriod: intent.targetPeriod,
      );
    }

    RoutineReminder? reminder;
    bool hasPerm = true;
    if (intent.isReminderIntent && intent.reminderHour != null) {
      await RoutineReminderScheduler.init();
      hasPerm = await RoutineReminderScheduler.checkPermissionStatus();
      if (!hasPerm) {
        hasPerm = await RoutineReminderScheduler.requestPermissions();
      }

      final notifBody = rec != null
          ? "Tomorrow's best ${intent.activity} window is ${rec.recommendedWindow} (${rec.temperatureCelsius}°C, ${rec.aqiCategory} AQI)."
          : "Your daily weather check is ready. Open Mausam for the latest forecast.";

      reminder = await ref.read(routineReminderProvider.notifier).createOrUpdateReminder(
        activity: intent.activity,
        reminderHour: intent.reminderHour!,
        reminderMinute: intent.reminderMinute ?? 0,
        targetPeriod: intent.targetPeriod,
        notificationBody: notifBody,
      );
    }

    String responseText;
    List<String> followUps;

    if (!hasPerm && reminder != null) {
      responseText =
          'I\'ve scheduled your daily **${intent.activity}** reminder for **${reminder.reminderTimeDisplay}**.\n\n'
          '⚠️ **Allow notifications**: Mausam needs notifications to remind you about your weather routines. Please enable notifications in your phone Settings so the alert can be delivered.';
      followUps = [
        'Enable notifications',
        'Tomorrow\'s activity window',
        'Pause this reminder',
      ];
    } else if (intent.type == RoutineIntentType.reminderAndRecommendation) {
      responseText =
          'I\'ve scheduled your daily reminder for **${reminder!.reminderTimeDisplay}**.\n\n'
          'Every evening at ${reminder.reminderTimeDisplay}, I\'ll compute tomorrow morning\'s optimal ${intent.activity} window using live forecast radar and your profile. Here is your preview for tomorrow:';
      followUps = [
        'Pause this reminder',
        'What should I wear tomorrow?',
        'Hourly rain breakdown',
      ];
    } else if (intent.type == RoutineIntentType.createReminderOnly) {
      responseText =
          'I\'ve scheduled your daily routine reminder for **${reminder!.reminderTimeDisplay}**.\n\n'
          'At that time each day, you\'ll receive an alert with the best ${intent.activity} window tailored to weather conditions in $locName.';
      followUps = [
        'Tomorrow\'s activity window',
        'Pause this reminder',
      ];
    } else {
      // Recommendation only
      responseText =
          'Here is tomorrow\'s optimal **${intent.activity}** window for $locName, calculated from live forecast data and your personal profile:';
      followUps = [
        'Set a daily reminder for this',
        'What should I wear tomorrow?',
        'Will it rain tomorrow?',
      ];
    }

    return (
      text: responseText,
      followUps: followUps,
      recommendation: rec,
      reminder: reminder,
    );
  }

  void _startStreamingResponse(
    String fullText, {
    List<String>? followUps,
    ActivityRecommendation? recommendation,
    RoutineReminder? reminder,
    WeatherAiCardData? cardData,
  }) {
    final assistantMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isThinking = false;
      _isStreaming = true;
      _messages.add(_ChatMessage(
        id: assistantMsgId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
        followUps: followUps,
        recommendation: recommendation,
        reminder: reminder,
        cardData: cardData,
      ));
    });
    ref.read(mausamAiStateProvider.notifier).setResponding();

    _scrollToBottom();

    // Stream word-by-word
    final words = fullText.split(' ');
    int currentWordIndex = 0;
    final buffer = StringBuffer();

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final interval = isTest ? const Duration(milliseconds: 8) : const Duration(milliseconds: 32);

    _streamTimer?.cancel();
    _streamTimer = Timer.periodic(interval, (timer) {
      if (!mounted || !_isStreaming) {
        timer.cancel();
        return;
      }

      if (currentWordIndex < words.length) {
        if (currentWordIndex > 0) buffer.write(' ');
        buffer.write(words[currentWordIndex]);
        currentWordIndex++;

        final msgIndex = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (msgIndex != -1) {
          setState(() {
            _messages[msgIndex] = _messages[msgIndex].copyWith(
              text: buffer.toString(),
              isStreaming: true,
            );
          });
        }

        // Only auto-scroll if user has not manually scrolled away
        if (!_userScrolledAwayFromBottom) {
          _scrollToBottom();
        }
      } else {
        timer.cancel();
        _finishStreaming(assistantMsgId, buffer.toString());
      }
    });
  }

  void _finishStreaming(String msgId, String finalText) {
    if (!mounted) return;
    final msgIndex = _messages.indexWhere((m) => m.id == msgId);
    setState(() {
      _isStreaming = false;
      if (msgIndex != -1) {
        _messages[msgIndex] = _messages[msgIndex].copyWith(
          text: finalText,
          isStreaming: false,
        );
      }
    });
    ref.read(mausamAiStateProvider.notifier).setIdle();
    if (!_userScrolledAwayFromBottom) {
      _scrollToBottom();
    }
  }

  void _stopGeneration() {
    _generationDelayTimer?.cancel();
    _loadingTimer?.cancel();
    _streamTimer?.cancel();
    setState(() {
      _isThinking = false;
      if (_isStreaming && _messages.isNotEmpty && _messages.last.isAssistant) {
        _messages.last = _messages.last.copyWith(isStreaming: false);
      }
      _isStreaming = false;
    });
    ref.read(mausamAiStateProvider.notifier).setIdle();
  }

  void _retryLastQuery() {
    if (_lastUserQuery != null && _lastUserQuery!.isNotEmpty) {
      _handleSubmitted(_lastUserQuery!);
    }
  }

  void _clearChat() {
    _stopGeneration();
    setState(() {
      _messages.clear();
      _userScrolledAwayFromBottom = false;
    });
  }

  KeyEventResult _handleKeyInput(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored; // Allow newline on Shift+Enter
      } else {
        _handleSubmitted(_controller.text);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Rule 1: Logo appears ONLY on the assistant's FIRST message in a conversation/sequence.
  /// For consecutive assistant messages, do NOT repeat the logo.
  bool _shouldShowAssistantLogo(int index) {
    final msg = _messages[index];
    if (msg.isUser) return false;
    if (index == 0) return true;
    // Show if preceding message was from user
    return _messages[index - 1].isUser;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewInsetsBottom = media.viewInsets.bottom;
    final isKeyboardOpen = viewInsetsBottom > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: ChatAtmosphereBackground(
        child: SafeArea(
          bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Persistent Top Action Header (New chat)
                    if (_messages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 68, 16, 0),
                        child: _buildHeader(),
                      ),

                    // Main Chat Scrollable Content
                    Expanded(
                      child: RefreshIndicator(
                        color: MausamPalette.accentCyan,
                        backgroundColor: MausamPalette.cardSurface,
                        onRefresh: () async {
                          await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                          await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                        },
                        child: _messages.isEmpty && !_isThinking
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          child: InitialChatAnimatedLogo(
                                            onPromptSelected: (query) => _handleSubmitted(query),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : ListView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  isKeyboardOpen ? (viewInsetsBottom + 84) : 120,
                                ),
                                children: [
                                  // Chat Messages
                                  for (int i = 0; i < _messages.length; i++)
                                    _buildMessageRow(i),

                                  // Progressive Loading State
                                  if (_isThinking)
                                    _buildProgressiveLoadingIndicator(),
                                ],
                              ),
                      ),
                    ),

                    // Suggestion Chips Row settled directly ABOVE the search bar
                    if (_messages.isEmpty && !isKeyboardOpen)
                      _buildSuggestionChipsRow(),

                    // Floating Capsule Input Dock
                    _buildInputDock(isKeyboardOpen, viewInsetsBottom),
                  ],
                ),

                // Floating "↓ New response" button when scrolled up
                if (_userScrolledAwayFromBottom && (_isThinking || _isStreaming || _messages.isNotEmpty))
                  Positioned(
                    bottom: (isKeyboardOpen ? viewInsetsBottom + 74 : 148),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildScrollToBottomButton(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHeader() {
    if (_messages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            label: 'New conversation',
            button: true,
            child: Tooltip(
              message: 'New conversation',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _clearChat,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_comment_outlined, size: 14, color: MausamPalette.textTertiary),
                      const SizedBox(width: 5),
                      Text(
                        'New chat',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Suggestion chips settled in a single horizontal row right above the search bar
  Widget _buildSuggestionChipsRow() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (int i = 0; i < _welcomePrompts.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _SuggestionChip(
                icon: _welcomePrompts[i].icon,
                label: _welcomePrompts[i].label,
                onTap: () => _handleSubmitted(_welcomePrompts[i].query),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(int index) {
    final msg = _messages[index];
    final isUser = msg.isUser;
    final showLogo = _shouldShowAssistantLogo(index);

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 48),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF202530),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SelectableText(
                      msg.text,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(msg.timestamp),
                      style: GoogleFonts.inter(
                        color: MausamPalette.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant / Error Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Rule: Only on the FIRST message in a sequence. Consecutive assistant messages get an empty indent.
          if (showLogo)
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.wb_cloudy_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            )
          else
            const SizedBox(width: 38), // 26 + 12 margin for clean vertical alignment

          // Message Body & Weather Scannable Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageContent(msg),

                // Post-message actions for completed responses
                if (!msg.isStreaming && msg.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildCopyButton(msg),
                      _buildShareButton(msg),
                      if (index == _messages.length - 1 && !_isThinking)
                        _buildRegenerateButton(),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _formatTimestamp(msg.timestamp),
                          style: GoogleFonts.inter(
                            color: MausamPalette.textTertiary,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Suggested follow-up prompt chips
                  if (msg.followUps != null && msg.followUps!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.followUps!.map((followUp) {
                        return _FollowUpChip(
                          text: followUp,
                          onTap: () => _handleSubmitted(followUp),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(_ChatMessage msg) {
    if (msg.isError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1B1B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Connection issue',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.text,
              style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _retryLastQuery,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    // Dynamic routine reminder card lookup
    Widget? reminderWidget;
    if (msg.reminder != null) {
      final activeReminders = ref.watch(routineReminderProvider);
      final index = activeReminders.indexWhere((r) => r.id == msg.reminder!.id);
      if (index != -1) {
        final currentReminder = activeReminders[index];
        reminderWidget = ActiveRoutineReminderCard(
          reminder: currentReminder,
          onTogglePause: () {
            ref.read(routineReminderProvider.notifier).togglePauseResume(currentReminder.id);
          },
          onDelete: () {
            ref.read(routineReminderProvider.notifier).deleteReminder(currentReminder.id);
          },
        );
      } else {
        // Reminder was deleted by the user
        reminderWidget = Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: MausamPalette.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Reminder deleted',
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormattedWeatherText(
          text: msg.text,
          isStreaming: msg.isStreaming,
        ),
        if (msg.cardData != null && msg.recommendation == null) ...[
          const SizedBox(height: 10),
          WeatherIntelligenceCard(
            cardData: msg.cardData!,
            onActionTap: () {
              final action = msg.cardData!.actionLabel ?? '';
              if (action.toLowerCase().contains('remind')) {
                _handleSubmitted('Every day at 9:00 PM, remind me what time I should walk tomorrow.');
              } else if (action.toLowerCase().contains('7-day') || action.toLowerCase().contains('forecast')) {
                _handleSubmitted('What is the full weather forecast for tomorrow?');
              } else if (action.toLowerCase().contains('hourly')) {
                _handleSubmitted('What is the hourly temperature forecast?');
              } else if (action.toLowerCase().contains('health') || action.toLowerCase().contains('metrics')) {
                _handleSubmitted('Check current air quality and pollution levels for outdoor safety.');
              }
            },
          ),
        ],
        if (msg.recommendation != null) ...[
          const SizedBox(height: 10),
          RoutineRecommendationCard(
            recommendation: msg.recommendation!,
          ),
        ],
        if (reminderWidget != null) ...[
          const SizedBox(height: 10),
          reminderWidget,
        ],
      ],
    );
  }

  Widget _buildCopyButton(_ChatMessage msg) {
    final isCopied = _copiedMessageId == msg.id;

    return Semantics(
      label: isCopied ? 'Copied to clipboard' : 'Copy message text',
      button: true,
      child: Tooltip(
        message: 'Copy to clipboard',
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            Clipboard.setData(ClipboardData(text: msg.text));
            HapticFeedback.lightImpact();
            setState(() {
              _copiedMessageId = msg.id;
            });
            _copiedResetTimer?.cancel();
            _copiedResetTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _copiedMessageId = null;
                });
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCopied ? Icons.check_rounded : Icons.copy_rounded,
                  color: isCopied ? const Color(0xFF10B981) : MausamPalette.textTertiary,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  isCopied ? 'Copied!' : 'Copy',
                  style: GoogleFonts.inter(
                    color: isCopied ? const Color(0xFF10B981) : MausamPalette.textTertiary,
                    fontSize: 11.5,
                    fontWeight: isCopied ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(_ChatMessage msg) {
    return Semantics(
      label: 'Share response',
      button: true,
      child: Tooltip(
        message: 'Share response',
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            Clipboard.setData(ClipboardData(text: msg.text));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Response copied to clipboard ready to share!',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                backgroundColor: const Color(0xFF1E2433),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.share_outlined,
                  color: MausamPalette.textTertiary,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  'Share',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegenerateButton() {
    return Semantics(
      label: 'Regenerate response',
      button: true,
      child: Tooltip(
        message: 'Regenerate response',
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            if (_lastUserQuery != null && !_isThinking && !_isStreaming) {
              HapticFeedback.lightImpact();
              if (_messages.isNotEmpty && _messages.last.isAssistant) {
                setState(() {
                  _messages.removeLast();
                });
              }
              _handleSubmitted(_lastUserQuery!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: MausamPalette.textTertiary,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  'Regenerate',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  /// Progressive Dynamic Loading Indicator (Requirement 4):
  /// - 0–3s: "Checking the weather..."
  /// - 3–6s: "Analyzing the forecast..."
  /// - 6+s: "Still checking the latest forecast..."
  Widget _buildProgressiveLoadingIndicator() {
    String statusText;
    if (_loadingElapsedSeconds < 3) {
      statusText = 'Checking the weather...';
    } else if (_loadingElapsedSeconds < 6) {
      statusText = 'Analyzing the forecast...';
    } else {
      statusText = 'Still checking the latest forecast...';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small Assistant Avatar
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10B981),
            ),
            child: const Center(
              child: Icon(
                Icons.wb_cloudy_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),

          // Calming pulsing dots
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final opacity = (math.sin((_pulseAnim.value * math.pi * 2) + (index * 0.8)) + 1) / 2;
                  return Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.3 + (0.7 * opacity)),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 10),

          // Dynamic Progressive Loading Status Text
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                statusText,
                key: ValueKey<String>(statusText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating "↓ New response" button when user scrolls away
  Widget _buildScrollToBottomButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _scrollToBottom(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: MausamPalette.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MausamPalette.cardBorder, width: 1),
            boxShadow: MausamPalette.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'New response',
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_downward_rounded,
                size: 14,
                color: MausamPalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ergonomic Bottom Input Dock:
  /// - Rounded capsule container matching `MausamPalette`.
  /// - Multiline text field with Enter to send, Shift+Enter for newline.
  /// - Send / Stop toggle button.
  /// - Full keyboard inset handling.
  Widget _buildInputDock(bool isKeyboardOpen, double viewInsetsBottom) {
    final hasText = _controller.text.trim().isNotEmpty;
    final isGenerating = _isThinking || _isStreaming;
    final bottomPadding = isKeyboardOpen ? (viewInsetsBottom + 10) : 88.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52, maxHeight: 130),
        padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF131722),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: _inputFocusNode.hasFocus
                ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                : const Color(0xFF242B3D),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text Input Field (No left icon, seamless transparent background)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) => _handleKeyInput(_inputFocusNode, event),
                  child: TextField(
                    controller: _controller,
                    focusNode: _inputFocusNode,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (text) => _handleSubmitted(text),
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 4,
                    cursorColor: const Color(0xFF38BDF8),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText: _placeholders[_placeholderIndex],
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Trailing Send / Stop Action Button integrated inside capsule
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _buildActionButton(isGenerating: isGenerating, hasText: hasText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required bool isGenerating, required bool hasText}) {
    if (isGenerating) {
      return Semantics(
        label: 'Stop generating response',
        button: true,
        child: Tooltip(
          message: 'Stop generating',
          child: GestureDetector(
            onTap: _stopGeneration,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF281C1C),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6), width: 1.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.stop_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final canSend = hasText;

    return Semantics(
      label: 'Send message to Mausam AI',
      button: true,
      child: Tooltip(
        message: 'Send message',
        child: GestureDetector(
          onTap: canSend ? () => _handleSubmitted(_controller.text) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canSend ? const Color(0xFFFAFAFA) : const Color(0xFF1E2433),
              boxShadow: canSend
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                Icons.arrow_upward_rounded,
                color: canSend ? const Color(0xFF09090B) : const Color(0xFF475569),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Formatted Weather Text Renderer (Requirement 6 & 11):
/// Parses bold tags, bullets, emojis, and renders an active blinking cursor `▌` during streaming.
class _FormattedWeatherText extends StatelessWidget {
  final String text;
  final bool isStreaming;

  const _FormattedWeatherText({
    required this.text,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Parse bold markers: **content**
      final parts = line.split('**');
      for (int p = 0; p < parts.length; p++) {
        final isBold = p % 2 == 1;
        spans.add(
          TextSpan(
            text: parts[p],
            style: GoogleFonts.inter(
              color: isBold ? MausamPalette.textPrimary : const Color(0xFFD4D4D8),
              fontSize: 14.5,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              height: 1.55,
            ),
          ),
        );
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    // Typing cursor indicator at the end of active stream
    if (isStreaming) {
      spans.add(
        const TextSpan(
          text: ' ▌',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: GoogleFonts.inter(
        fontSize: 14.5,
        height: 1.55,
      ),
    );
  }
}

/// Suggestion Chip for the Welcome Screen
class _SuggestionChip extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF131722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF242B3D), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Follow-up prompt chip beneath completed assistant responses
class _FollowUpChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FollowUpChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF161A24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3448), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.subdirectory_arrow_right_rounded, color: Color(0xFF10B981), size: 12),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
