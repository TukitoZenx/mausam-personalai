import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/weather_dashboard_provider.dart';
import '../../theme/weather_palette.dart';

/// Opens the Mausam AI Assistant chat bottom sheet.
Future<void> showMausamAiChatSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => const MausamAiChatSheet(),
  );
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Obsidian AI weather assistant sheet. Replies from live dashboard data, or
/// the backend weather templates when the dashboard is empty. No paid LLM key.
class MausamAiChatSheet extends ConsumerStatefulWidget {
  const MausamAiChatSheet({super.key});

  @override
  ConsumerState<MausamAiChatSheet> createState() => _MausamAiChatSheetState();
}

class _MausamAiChatSheetState extends ConsumerState<MausamAiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isThinking = false;
  bool _initialized = false;

  final List<({String emoji, String query})> _quickPrompts = const [
    (emoji: '🌦️', query: 'What should I wear today?'),
    (emoji: '🏃', query: 'Best window for outdoor workout?'),
    (emoji: '🚗', query: 'Commute weather & safety advice'),
    (emoji: '😷', query: 'Air Quality & pollution check'),
    (emoji: '☔', query: 'Will it rain in the next 4 hours?'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialized) {
        _initialized = true;
        _initWelcomeMessage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _placeName() {
    final locationState = ref.read(locationProvider);
    final data = ref.read(weatherDashboardProvider).data;
    if (locationState.cityName.isNotEmpty && locationState.cityName != 'Current Location') {
      return locationState.cityName.split(',').first;
    }
    final fromWeather = data?.current.location ?? '';
    if (fromWeather.isNotEmpty) return fromWeather;
    return 'your location';
  }

  void _initWelcomeMessage() {
    final userState = ref.read(userProvider);
    final persona = userState.selectedPersona ?? 'Fitness';
    final data = ref.read(weatherDashboardProvider).data;
    final locName = _placeName();

    String greeting;
    if (data != null) {
      final temp = data.current.temperatureCelsius.round();
      final cond = data.current.condition;
      greeting =
          'Hello! I am your Mausam AI Assistant tuned for **$persona** in **$locName**.\n\n'
          'Right now it is **$temp°C** with **$cond**. Ask me about outfit, workout timing, '
          'commute weather, or air quality.';
    } else {
      greeting =
          'Hello! I am your Mausam AI Assistant. Load live weather on Home, or pick a city in '
          'My Locations, then ask about conditions for **$locName**.';
    }

    setState(() {
      _messages.add(_ChatMessage(
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _handleSubmitted(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isThinking) return;

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isThinking = true;
    });

    _scrollToBottom();

    final loc = ref.read(locationProvider);
    final user = ref.read(userProvider);
    final dash = ref.read(weatherDashboardProvider).data;
    final hasCoords = loc.latitude != 0.0 || loc.longitude != 0.0;
    String reply;

    if (dash != null) {
      reply = _generateAiResponse(trimmed);
    } else if (hasCoords) {
      try {
        final res = await ref.read(apiClientProvider).sendChatMessage(
              text: trimmed,
              lat: loc.latitude,
              lon: loc.longitude,
              persona: user.selectedPersona,
              healthConcerns: user.healthConcerns.isEmpty ? null : user.healthConcerns,
              idToken: user.idToken ?? 'guest_token',
            );
        reply = res['reply'] as String? ?? 'I could not form a reply just now.';
      } catch (_) {
        reply = _generateAiResponse(trimmed);
      }
    } else {
      reply =
          'I need an active location to use live weather. Open My Locations, pick a city, then ask again.';
    }

    if (!mounted) return;

    setState(() {
      _isThinking = false;
      _messages.add(_ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _generateAiResponse(String query) {
    final q = query.toLowerCase();
    final userState = ref.read(userProvider);
    final dash = ref.read(weatherDashboardProvider);
    final persona = userState.selectedPersona ?? 'Fitness';
    final data = dash.data;
    final locName = _placeName();

    if (data == null) {
      return 'I do not have live weather for **$locName** yet. Open Home to load conditions, then ask again.';
    }

    final curr = data.current;
    final temp = curr.temperatureCelsius.round();
    final feelsLike = (curr.feelsLikeCelsius ?? curr.temperatureCelsius).round();
    final humidity = curr.humidityPercent;
    final wind = curr.windSpeedKmh.round();
    final rain = curr.rainMm1h ?? 0;
    final uv = curr.uvIndex;
    final aqiVal = data.aqi?.aqiValue;
    final aqiCat = data.aqi?.category;
    final aqiLine = (aqiVal != null && aqiCat != null) ? 'AQI $aqiVal ($aqiCat)' : 'AQI unavailable';

    if (q.contains('wear') ||
        q.contains('outfit') ||
        q.contains('clothes') ||
        q.contains('jacket') ||
        q.contains('coat') ||
        q.contains('umbrella')) {
      if (rain > 0 || curr.condition.toLowerCase().contains('rain')) {
        return 'Outfit for $locName ($temp°C)\n\n'
            '• Outerwear: waterproof jacket or compact umbrella (${rain.toStringAsFixed(1)} mm precipitation).\n'
            '• Footwear: closed waterproof shoes with grip.\n'
            '• Layers: light breathable inner layer; humidity is $humidity%.';
      } else if (temp >= 32) {
        return 'Hot weather outfit ($temp°C, feels like $feelsLike°C)\n\n'
            '• Fabric: light, loose cotton or moisture-wicking cloth.\n'
            '• Sun: sunglasses and a hat (UV Index ${uv.toStringAsFixed(1)}).\n'
            '• Hydration: carry water.';
      } else if (temp <= 16) {
        return 'Cool weather outfit ($temp°C, wind $wind km/h)\n\n'
            '• Layering: thermal or mid-layer plus a windbreaker.\n'
            '• Check the hourly forecast before heading out for the evening drop.';
      } else {
        return 'Comfortable day outfit ($temp°C)\n\n'
            '• Attire: t-shirt with a light jacket for morning or evening.\n'
            '• Humidity: $humidity% — breathable fabrics are better.';
      }
    }

    if (q.contains('workout') ||
        q.contains('run') ||
        q.contains('fitness') ||
        q.contains('exercise') ||
        q.contains('outdoor')) {
      if (temp >= 33) {
        return 'Fitness note ($persona)\n\n'
            '• Heat-limited outdoor conditions ($temp°C, $aqiLine).\n'
            '• Prefer indoor sessions or the coolest hours on the hourly chart.\n'
            '• UV index is ${uv.toStringAsFixed(1)}. Stay hydrated.';
      } else if (rain > 0) {
        return 'Fitness note ($persona)\n\n'
            '• Wet conditions in $locName (${rain.toStringAsFixed(1)} mm rain).\n'
            '• Indoor session, or outdoor with rain gear if you still go out.';
      } else {
        return 'Workout conditions\n\n'
            '• Temperature: $temp°C (feels like $feelsLike°C)\n'
            '• Air: $aqiLine\n'
            '• Wind: $wind km/h\n'
            '• Outdoor training is reasonable for your $persona goal right now.';
      }
    }

    if (q.contains('commute') || q.contains('drive') || q.contains('travel') || q.contains('traffic')) {
      if (rain > 0 || curr.condition.toLowerCase().contains('rain')) {
        final vis = curr.visibilityKm;
        final visLine = vis != null ? '\n• Visibility: ${vis.toStringAsFixed(1)} km.' : '';
        return 'Commute weather ($locName)\n\n'
            '• Roads: wet from ${curr.condition}.\n'
            '• Allow extra time; I do not have live traffic.$visLine';
      }
      return 'Commute weather\n\n'
          '• Roads: dry under ${curr.condition}.\n'
          '• Wind: $wind km/h. I do not have live traffic.';
    }

    if (q.contains('air') ||
        q.contains('aqi') ||
        q.contains('pollution') ||
        q.contains('smog') ||
        q.contains('breath')) {
      if (aqiVal == null || aqiCat == null) {
        return 'I do not have air quality data for $locName right now. Temperature is $temp°C with ${curr.condition}.';
      }
      return 'Air quality for $locName\n\n'
          '• AQI: $aqiVal ($aqiCat)\n'
          '• Humidity: $humidity%\n'
          '• ${aqiVal > 100 ? "Sensitive people should wear a mask and shorten outdoor sessions." : "Air quality is suitable for outdoor time."}';
    }

    if (q.contains('rain') || q.contains('shower') || q.contains('storm')) {
      final rainProb = data.hourly.isNotEmpty ? data.hourly.first.rainProbabilityPercent : null;
      final probLine = rainProb != null ? '\n• Next-hour rain chance: $rainProb%' : '';
      return 'Rain outlook for $locName\n\n'
          '• Now: ${curr.condition} ($rain mm/h)$probLine\n'
          '• ${(rain > 0 || (rainProb != null && rainProb > 40)) ? "Keep an umbrella handy." : "No significant rain in the current report."}';
    }

    return 'Mausam AI summary for $locName\n\n'
        '• Temperature: $temp°C (feels like $feelsLike°C)\n'
        '• Condition: ${curr.condition}\n'
        '• Air: $aqiLine\n'
        '• UV Index: ${uv.toStringAsFixed(1)}\n'
        '• Persona: $persona';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final userState = ref.watch(userProvider);
    ref.watch(locationProvider);
    final dash = ref.watch(weatherDashboardProvider);

    final persona = userState.selectedPersona ?? 'Fitness';
    final data = dash.data;
    final locName = _placeName();
    final currentTemp = data != null ? '${data.current.temperatureCelsius.round()}°C' : '--';
    final condition = data?.current.condition ?? 'Waiting for weather';

    return Container(
      height: screenHeight * 0.84,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: MausamPalette.bgDeep.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.heroShadow,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Column(
            children: [
              _buildHeader(
                context,
                locName: locName,
                temp: currentTemp,
                condition: condition,
                persona: persona,
                isLive: data != null,
              ),
              _buildQuickPromptsBar(),
              const Divider(height: 1, color: MausamPalette.cardBorder),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isThinking) {
                      return _buildThinkingBubble();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              _buildInputBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String locName,
    required String temp,
    required String condition,
    required String persona,
    required bool isLive,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MausamPalette.cardSurfaceLight,
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: MausamPalette.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mausam AI Assistant',
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MausamPalette.cardSurfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: MausamPalette.cardBorder),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              color: isLive ? MausamPalette.textPrimary : MausamPalette.textTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$locName · $temp · $condition · $persona',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                tooltip: 'Close AI Assistant',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = _quickPrompts[i];
          return ActionChip(
            elevation: 0,
            pressElevation: 2,
            backgroundColor: MausamPalette.cardSurface,
            side: const BorderSide(color: MausamPalette.cardBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            avatar: Text(item.emoji, style: const TextStyle(fontSize: 13)),
            label: Text(
              item.query,
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _handleSubmitted(item.query),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MausamPalette.cardSurfaceLight,
                border: Border.all(color: MausamPalette.cardBorder),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: MausamPalette.textSecondary,
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? MausamPalette.cardSurfaceLight : MausamPalette.cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(color: MausamPalette.cardBorder),
                boxShadow: MausamPalette.cardShadow,
              ),
              child: SelectableText(
                message.text.replaceAll('**', ''),
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MausamPalette.cardSurfaceLight,
              border: Border.all(color: MausamPalette.cardBorder),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: MausamPalette.textSecondary,
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MausamPalette.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: MausamPalette.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Checking live weather...',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: MausamPalette.bgDeep,
        border: Border(top: BorderSide(color: MausamPalette.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MausamPalette.cardBorder),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                onSubmitted: _handleSubmitted,
                style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask about weather & your day...',
                  hintStyle: GoogleFonts.inter(
                    color: MausamPalette.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _handleSubmitted(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasText ? MausamPalette.textPrimary : MausamPalette.cardSurfaceLight,
                border: hasText ? null : Border.all(color: MausamPalette.cardBorder),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: hasText ? MausamPalette.bgDeep : Colors.white54,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
