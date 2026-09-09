import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/weather_ai_card_data.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/mausam_ai_state_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../services/api_client.dart';
import '../theme/weather_palette.dart';
import '../widgets/ai/weather_intelligence_card.dart';

class ChatMessageItem {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? weatherData;
  final WeatherAiCardData? cardData;
  final List<String> suggestedActions;
  final bool reminderCreated;

  ChatMessageItem({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.weatherData,
    this.cardData,
    this.suggestedActions = const [],
    this.reminderCreated = false,
  });
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageItem> _messages = [];

  /// Multi-turn conversation history sent to the backend (last 12 turns).
  final List<Map<String, String>> _conversationHistory = [];

  bool _isLoading = false;
  late final ApiClient _apiClient;
  late final AnimationController _typingController;

  // Active reminders list
  List<dynamic> _activeReminders = [];
  bool _loadingReminders = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ref.read(apiClientProvider);
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _loadInitialGreeting();
    _loadReminders();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _loadInitialGreeting() {
    final userState = ref.read(userProvider);
    final name = userState.displayName?.trim() ?? '';
    final greeting = name.isNotEmpty
        ? "Hello $name! I'm your Mausam personal weather intelligence companion. How can I help you with today's routine, commute, workout, or weather plans?"
        : "Hello! I'm your Mausam personal weather intelligence companion. Ask me about your routine, workout suitability, what to wear, or rain forecasts!";
    _messages.add(
      ChatMessageItem(
        id: 'initial_greeting',
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _loadReminders() async {
    setState(() => _loadingReminders = true);
    try {
      final userState = ref.read(userProvider);
      final auth = ref.read(authStateProvider);
      final idToken = userState.idToken ?? (auth.value != null ? 'test_token_user' : 'guest_token');
      final list = await _apiClient.fetchReminders(idToken: idToken);
      if (mounted) {
        setState(() {
          _activeReminders = list;
          _loadingReminders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReminders = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSend([String? textToSend]) async {
    final query = (textToSend ?? _textController.text).trim();
    if (query.isEmpty || _isLoading) return;

    _textController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    final userMsg = ChatMessageItem(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();
    ref.read(mausamAiStateProvider.notifier).setThinking();

    final locState = ref.read(locationProvider);
    final auth = ref.read(authStateProvider);

    final hasCoords = locState.latitude != 0.0 || locState.longitude != 0.0;
    final userState = ref.read(userProvider);
    final idToken = userState.idToken ?? (auth.value != null ? 'test_token_user' : 'guest_token');

    final locName = locState.cityName.isNotEmpty
        ? locState.cityName.split(',').first.trim()
        : null;

    // Append user turn to history
    _conversationHistory.add({'role': 'user', 'content': query});
    if (_conversationHistory.length > 12) {
      _conversationHistory.removeRange(0, _conversationHistory.length - 12);
    }

    final savedLocationsPayload = locState.savedLocations
        .map((l) => {
              'name': l.name,
              'latitude': l.latitude,
              'longitude': l.longitude,
            })
        .toList();

    try {
      final res = await _apiClient.sendChatMessage(
        text: query,
        lat: hasCoords ? locState.latitude : null,
        lon: hasCoords ? locState.longitude : null,
        persona: userState.selectedPersona,
        healthConcerns: userState.healthConcerns.isEmpty ? null : userState.healthConcerns,
        weatherTriggers: userState.weatherTriggers.isEmpty ? null : userState.weatherTriggers,
        whatMattersMost: userState.whatMattersMost.isEmpty ? null : userState.whatMattersMost,
        activityLevel: userState.activityLevel.isEmpty ? null : userState.activityLevel,
        userName: (userState.displayName != null && userState.displayName!.trim().isNotEmpty) ? userState.displayName : null,
        activeLocationName: locName,
        savedLocations: savedLocationsPayload.isEmpty ? null : savedLocationsPayload,
        history: _conversationHistory.length > 1
            ? _conversationHistory.sublist(0, _conversationHistory.length - 1)
            : null,
        idToken: idToken,
      );

      final replyText = res['reply'] as String? ?? "Here is your weather update.";
      final weatherData = res['weather_data'] as Map<String, dynamic>?;
      final rawCard = res['card_data'] as Map<String, dynamic>?;
      WeatherAiCardData? cardData;
      if (rawCard != null) {
        try {
          cardData = WeatherAiCardData.fromJson(rawCard);
        } catch (_) {}
      }
      final reminderCreated = res['reminder_created'] == true;
      final rawActions = res['suggested_actions'];
      final List<String> actions = rawActions is List
          ? rawActions.whereType<String>().toList()
          : [];

      // Append assistant reply to history
      _conversationHistory.add({'role': 'assistant', 'content': replyText});

      final botMsg = ChatMessageItem(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
        weatherData: weatherData,
        cardData: cardData,
        suggestedActions: actions,
        reminderCreated: reminderCreated,
      );

      if (mounted) {
        setState(() {
          _messages.add(botMsg);
          _isLoading = false;
        });
        ref.read(mausamAiStateProvider.notifier).setResponding();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) ref.read(mausamAiStateProvider.notifier).setIdle();
        });
        if (reminderCreated) _loadReminders();
        _scrollToBottom();
      }
    } catch (_) {
      _conversationHistory.add({'role': 'assistant', 'content': 'Error'});
      final localReply = _localWeatherReply(query);
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessageItem(
              id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
              text: localReply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        ref.read(mausamAiStateProvider.notifier).setIdle();
        _scrollToBottom();
      }
    }
  }

  String _localWeatherReply(String query) {
    final dash = ref.read(weatherDashboardProvider).data;
    final loc = ref.read(locationProvider);
    final locName = loc.cityName.isNotEmpty && loc.cityName != 'Current Location'
        ? loc.cityName.split(',').first
        : (dash?.current.location ?? '');
    if (dash == null) {
      return locName.isEmpty
          ? "I need an active location to use live weather. Open My Locations, pick a city, then ask again."
          : "I don't have live weather for $locName yet. Open Home to load conditions, then ask again.";
    }

    final curr = dash.current;
    final temp = curr.temperatureCelsius.round();
    final feels = (curr.feelsLikeCelsius ?? curr.temperatureCelsius).round();
    final condition = curr.condition;
    final humidity = curr.humidityPercent;
    final wind = curr.windSpeedKmh.round();
    final rain = curr.rainMm1h ?? 0.0;
    final aqiVal = dash.aqi?.aqiValue;
    final aqiCat = dash.aqi?.category;
    final q = query.toLowerCase();
    final place = locName.isNotEmpty
        ? locName
        : (curr.location.isNotEmpty ? curr.location : 'your location');

    if (q.contains('aqi') || q.contains('air quality') || q.contains('pollution')) {
      if (aqiVal == null || aqiCat == null) {
        return "I don't have air quality data for $place right now. Temperature is $temp°C with $condition.";
      }
      return "In $place, the Air Quality Index is $aqiVal ($aqiCat). Temperature is $temp°C with $condition skies.";
    }
    if (q.contains('rain') || q.contains('umbrella') || q.contains('shower')) {
      final isRainy = rain > 0 ||
          condition.toLowerCase().contains('rain') ||
          condition.toLowerCase().contains('drizzle');
      if (isRainy) {
        return "It's $temp°C with $condition in $place (${rain.toStringAsFixed(1)} mm/h). Carry an umbrella.";
      }
      return "No rain is reported right now in $place. Conditions are $condition at $temp°C (feels like $feels°C).";
    }
    final aqiPart = (aqiVal != null && aqiCat != null) ? ", with AQI at $aqiVal ($aqiCat)" : "";
    return "It's $temp°C and $condition in $place right now$aqiPart. Feels like $feels°C, humidity $humidity%, wind $wind km/h.";
  }

  void _showSetReminderModal() {
    TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);
    String selectedFrequency = 'daily';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              key: const Key('set_reminder_dialog'),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: MausamPalette.textPrimary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: MausamPalette.textPrimary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MausamPalette.textPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alarm, color: MausamPalette.textPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Set Weather Reminder',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Receive a spoken-style briefing with today's temperature, rain forecast, and AQI.",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Time Selection Tile
                  Text('BRIEFING TIME', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  InkWell(
                    key: const Key('select_time_button'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: MausamPalette.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            selectedTime.format(context),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text('Change', style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Frequency Selector
                  Text('FREQUENCY', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedFrequency = 'daily'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedFrequency == 'daily' ? MausamPalette.textPrimary : MausamPalette.cardSurfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selectedFrequency == 'daily' ? Colors.transparent : Colors.white12),
                            ),
                            child: Center(
                              child: Text(
                                'Daily',
                                style: GoogleFonts.inter(
                                  color: selectedFrequency == 'daily' ? MausamPalette.bgDeep : Colors.white,
                                  fontWeight: selectedFrequency == 'daily' ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedFrequency = 'once'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedFrequency == 'once' ? MausamPalette.textPrimary : MausamPalette.cardSurfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selectedFrequency == 'once' ? Colors.transparent : Colors.white12),
                            ),
                            child: Center(
                              child: Text(
                                'Once',
                                style: GoogleFonts.inter(
                                  color: selectedFrequency == 'once' ? MausamPalette.bgDeep : Colors.white,
                                  fontWeight: selectedFrequency == 'once' ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('confirm_reminder_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MausamPalette.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final hourStr = selectedTime.hour.toString().padLeft(2, '0');
                        final minuteStr = selectedTime.minute.toString().padLeft(2, '0');
                        final timeOfDayStr = '$hourStr:$minuteStr';

                        final userState = ref.read(userProvider);
                        final auth = ref.read(authStateProvider);
                        final idToken = userState.idToken ?? (auth.value != null ? 'test_token_user' : 'guest_token');

                        setState(() => _isLoading = true);
                        try {
                          await _apiClient.createReminder(
                            timeOfDay: timeOfDayStr,
                            frequency: selectedFrequency,
                            idToken: idToken,
                          );
                          _loadReminders();
                          if (mounted) {
                            setState(() {
                              _messages.add(
                                ChatMessageItem(
                                  id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                                  text: "✅ Reminder set for **$timeOfDayStr** ($selectedFrequency). At that time, you'll receive a spoken-style briefing. (Note: push delivery is currently simulated/logged and not yet wired to FCM).",
                                  isUser: false,
                                  timestamp: DateTime.now(),
                                  reminderCreated: true,
                                ),
                              );
                              _isLoading = false;
                            });
                            _scrollToBottom();
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _messages.add(
                                ChatMessageItem(
                                  id: 'err_${DateTime.now().millisecondsSinceEpoch}',
                                  text: "Failed to schedule reminder: $e",
                                  isUser: false,
                                  timestamp: DateTime.now(),
                                ),
                              );
                              _isLoading = false;
                            });
                            _scrollToBottom();
                          }
                        }
                      },
                      child: Text(
                        'Confirm Reminder',
                        style: GoogleFonts.inter(color: MausamPalette.bgDeep, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showActiveRemindersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: MausamPalette.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Weather Reminders',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loadingReminders)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: MausamPalette.textPrimary)),
                )
              else if (_activeReminders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No active reminders scheduled.',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                )
              else
                ..._activeReminders.map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: MausamPalette.cardSurfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_on, color: MausamPalette.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['time_of_day'] ?? '--:--',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${r['frequency']} briefing',
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            final userState = ref.read(userProvider);
                            final auth = ref.read(authStateProvider);
                            final idToken = userState.idToken ?? (auth.value != null ? 'test_token_user' : 'guest_token');
                            await _apiClient.deleteReminder(id: r['id'], idToken: idToken);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            _loadReminders();
                            if (mounted) {
                              setState(() {
                                _messages.add(
                                  ChatMessageItem(
                                    id: 'del_${DateTime.now().millisecondsSinceEpoch}',
                                    text: "Deleted reminder for **${r['time_of_day']}**.",
                                    isUser: false,
                                    timestamp: DateTime.now(),
                                  ),
                                );
                              });
                              _scrollToBottom();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: MausamPalette.bgDeep.withValues(alpha: 0.9),
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MausamPalette.cardSurfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mausam Weather AI',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Live Weather Intelligence & Reminders',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_activeReminders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _showActiveRemindersSheet,
                      icon: const Icon(Icons.notifications_active, color: MausamPalette.textSecondary, size: 16),
                      label: Text(
                        '${_activeReminders.length}',
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // 3-dot animated typing indicator
            if (_isLoading)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 6, 16, 6),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: MausamPalette.textPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: MausamPalette.textPrimary.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.wb_cloudy_rounded, color: MausamPalette.textSecondary, size: 12),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: AnimatedBuilder(
                        animation: _typingController,
                        builder: (context, _) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (i) {
                              final phase = (_typingController.value - i * 0.33).clamp(0.0, 1.0);
                              final opacity = (0.3 + 0.7 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2)).clamp(0.3, 1.0);
                              return Padding(
                                padding: EdgeInsets.only(right: i < 2 ? 4.0 : 0),
                                child: Opacity(
                                  opacity: opacity,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: MausamPalette.textSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Fetching live data…',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),

            // Quick-reply chips row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildChip(
                    key: const Key('quick_chip_todays_weather'),
                    label: "Today's weather",
                    icon: Icons.wb_sunny_outlined,
                    onTap: () => _handleSend("What is today's weather?"),
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    key: const Key('quick_chip_daily_reminder'),
                    label: 'Remind me daily at 7am',
                    icon: Icons.alarm,
                    onTap: () => _handleSend('Remind me daily at 7am'),
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    key: const Key('quick_chip_aqi'),
                    label: 'AQI right now',
                    icon: Icons.air,
                    onTap: () => _handleSend('What is the AQI right now?'),
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    key: const Key('quick_chip_set_reminder'),
                    label: 'Set a reminder ⏰',
                    icon: Icons.add_alarm,
                    onTap: _showSetReminderModal,
                  ),
                ],
              ),
            ),

            // Input Bar
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.viewInsetsOf(context).bottom > 0
                    ? (MediaQuery.viewInsetsOf(context).bottom + 12)
                    : 90,
              ),
              decoration: BoxDecoration(
                color: MausamPalette.bgDeep.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('chat_reminder_button'),
                    icon: const Icon(Icons.alarm_add_rounded, color: MausamPalette.textSecondary),
                    tooltip: 'Set Reminder',
                    onPressed: _showSetReminderModal,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        key: const Key('chat_input_field'),
                        controller: _textController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask weather or set reminder...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                        ),
                        onSubmitted: (val) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: MausamPalette.textPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MausamPalette.textPrimary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      key: const Key('chat_send_button'),
                      icon: const Icon(Icons.arrow_upward_rounded, color: MausamPalette.bgDeep, size: 20),
                      onPressed: () => _handleSend(),
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

  Widget _buildChip({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      key: key,
      onPressed: onTap,
      avatar: Icon(icon, size: 14, color: MausamPalette.textSecondary),
      label: Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
      backgroundColor: MausamPalette.cardSurfaceLight,
      side: const BorderSide(color: Colors.white12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurfaceLight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Bot message
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: MausamPalette.textPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: MausamPalette.textPrimary.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.wb_cloudy_rounded, color: MausamPalette.textSecondary, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMarkdownText(msg.text),
                  if (msg.cardData != null) ...[
                    const SizedBox(height: 10),
                    WeatherIntelligenceCard(
                      cardData: msg.cardData!,
                      onActionTap: () {
                        if (msg.cardData!.cardType == WeatherCardType.travelRoute) {
                          context.push('/weather-map', extra: msg.cardData!);
                        }
                      },
                    ),
                  ] else if (msg.weatherData != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(child: _buildMiniStat('TEMP', '${msg.weatherData!['temperature_celsius']}°C')),
                          const SizedBox(width: 6),
                          Flexible(child: _buildMiniStat('CONDITION', '${msg.weatherData!['condition']}')),
                          const SizedBox(width: 6),
                          Flexible(child: _buildMiniStat('AQI', '${msg.weatherData!['aqi']} (${msg.weatherData!['aqi_category']})')),
                        ],
                      ),
                    ),
                  ],
                  // Per-message suggested action chips from Gemini
                  if (msg.suggestedActions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.suggestedActions.map((action) {
                        return GestureDetector(
                          onTap: () => _handleSend(action),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: MausamPalette.textPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: MausamPalette.textPrimary.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              action,
                              style: GoogleFonts.inter(
                                color: MausamPalette.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Renders markdown bold (**text**) as bold [TextSpan]s inline.
  Widget _buildMarkdownText(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 14,
            height: 1.5,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 14,
          height: 1.5,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
