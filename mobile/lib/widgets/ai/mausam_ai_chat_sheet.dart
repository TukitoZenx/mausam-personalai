import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/homepage_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/weather_dashboard_provider.dart';
import '../../theme/weather_palette.dart';

/// Opens the Ultra-Premium Obsidian Mausam AI Assistant Chat bottom sheet modal.
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

/// Ultra-Premium Obsidian AI Weather Assistant Chat Sheet for Mausam AI.
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

  void _initWelcomeMessage() {
    final userState = ref.read(userProvider);
    final locationState = ref.read(locationProvider);
    final dash = ref.read(weatherDashboardProvider);

    final persona = userState.selectedPersona ?? 'Fitness';
    final data = dash.data;

    final locName = locationState.cityName.isNotEmpty
        ? locationState.cityName.split(',').first
        : (data?.current.location ?? 'your location');

    String greeting;
    if (data != null) {
      final temp = data.current.temperatureCelsius.round();
      final cond = data.current.condition;
      greeting =
          'Hello! I am your Mausam AI Assistant tuned for **$persona** persona in **$locName**.\n\n'
          'Right now it is **$temp°C** with **$cond**. Ask me anything about outfit recommendations, '
          'workout timing, commute weather, or air quality precautions!';
    } else {
      greeting =
          'Hello! I am your Mausam AI Assistant. I can help you with hyper-local weather insights, '
          'personalized recommendations, and activity timing for **$locName**. What would you like to know?';
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

    // Simulate hyper-fast AI streaming / calculation lag
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    final reply = _generateAiResponse(trimmed);

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
    final locationState = ref.read(locationProvider);
    final dash = ref.read(weatherDashboardProvider);
    final home = ref.read(homepageProvider);

    final persona = userState.selectedPersona ?? home.data?.persona ?? 'Fitness';
    final data = dash.data;
    final locName = locationState.cityName.isNotEmpty
        ? locationState.cityName.split(',').first
        : (data?.current.location ?? 'Active Location');

    if (data == null) {
      return 'I am currently fetching live satellite & radar weather data for **$locName**. Please retry in a few seconds!';
    }

    final curr = data.current;
    final temp = curr.temperatureCelsius.round();
    final feelsLike = (curr.feelsLikeCelsius ?? curr.temperatureCelsius).round();
    final humidity = curr.humidityPercent;
    final wind = curr.windSpeedKmh.round();
    final rain = curr.rainMm1h ?? 0;
    final uv = curr.uvIndex;
    final aqiVal = data.aqi?.aqiValue ?? 45;
    final aqiCat = data.aqi?.category ?? 'Good';

    if (q.contains('wear') || q.contains('outfit') || q.contains('clothes') || q.contains('jacket') || q.contains('coat') || q.contains('umbrella')) {
      if (rain > 0 || curr.condition.toLowerCase().contains('rain')) {
        return '☔ **Outfit Recommendation for $locName ($temp°C)**\n\n'
            '• **Outerwear**: Carry a waterproof rain jacket or compact umbrella (${rain.toStringAsFixed(1)} mm precipitation).\n'
            '• **Footwear**: Closed waterproof shoes or boots with good grip.\n'
            '• **Layers**: Light breathable inner layer, humidity is high at $humidity%.';
      } else if (temp >= 32) {
        return '☀️ **Hot Weather Outfit ($temp°C, feels like $feelsLike°C)**\n\n'
            '• **Fabric**: Light, loose-fitting cotton or moisture-wicking synthetic fabric.\n'
            '• **Sun Protection**: Sunglasses + UV protection hat (UV Index is **${uv.toStringAsFixed(1)}**).\n'
            '• **Hydration**: Carry an insulated water bottle.';
      } else if (temp <= 16) {
        return '🧥 **Cool Weather Outfit ($temp°C, wind $wind km/h)**\n\n'
            '• **Layering**: Thermal base layer + light fleece or windbreaker.\n'
            '• **Evening Note**: Temperatures drop by 3-5°C after sunset, bring a warm mid-layer.';
      } else {
        return '👕 **Comfortable Day Outfit ($temp°C)**\n\n'
            '• **Attire**: Standard t-shirt with a light transitional jacket for early morning / evening.\n'
            '• **Humidity**: $humidity% — breathable fabrics are optimal.';
      }
    }

    if (q.contains('workout') || q.contains('run') || q.contains('fitness') || q.contains('exercise') || q.contains('outdoor')) {
      if (temp >= 33) {
        return '🏃 **Fitness Advisory ($persona Persona)**\n\n'
            '• **Status**: Heat-limited outdoor conditions ($temp°C, AQI $aqiVal).\n'
            '• **Recommendation**: Shift intensive sessions indoors or schedule early morning before 8:00 AM.\n'
            '• **Precaution**: UV index is ${uv.toStringAsFixed(1)}. Stay hydrated!';
      } else if (rain > 0) {
        return '🌧️ **Fitness Advisory ($persona Persona)**\n\n'
            '• **Status**: Wet conditions in $locName (${rain.toStringAsFixed(1)} mm rain).\n'
            '• **Recommendation**: Indoor treadmill, strength workout, or outdoor trail run with rain gear.';
      } else {
        return '🟢 **Optimal Workout Conditions!**\n\n'
            '• **Temperature**: $temp°C (feels like $feelsLike°C)\n'
            '• **Air Quality**: AQI $aqiVal ($aqiCat)\n'
            '• **Wind**: $wind km/h\n'
            '• **Verdict**: High outdoor training suitability for your **$persona** goal right now.';
      }
    }

    if (q.contains('commute') || q.contains('drive') || q.contains('travel') || q.contains('traffic')) {
      if (rain > 0 || curr.condition.toLowerCase().contains('rain')) {
        return '🚗 **Commute Safety Alert ($locName)**\n\n'
            '• **Road Condition**: Wet surfaces due to ${curr.condition}.\n'
            '• **Time Buffer**: Add 10-15 minutes extra buffer for traffic slowing.\n'
            '• **Visibility**: ${(curr.visibilityKm ?? 10.0).toStringAsFixed(1)} km.';
      } else {
        return '🚗 **Commute Weather Clear**\n\n'
            '• **Road Condition**: Normal dry pavements under ${curr.condition}.\n'
            '• **Wind**: $wind km/h — stable driving conditions.';
      }
    }

    if (q.contains('air') || q.contains('aqi') || q.contains('pollution') || q.contains('smog') || q.contains('breath')) {
      return '😷 **Air Quality Briefing for $locName**\n\n'
          '• **AQI Score**: **$aqiVal** ($aqiCat)\n'
          '• **Humidity**: $humidity%\n'
          '• **Health Action**: ${aqiVal > 100 ? "Sensitive individuals should wear an N95 mask and restrict long outdoor sessions." : "Air quality is good. Great time for outdoor ventilation!"}';
    }

    if (q.contains('rain') || q.contains('shower') || q.contains('storm')) {
      final rainProb = data.hourly.isNotEmpty ? data.hourly.first.rainProbabilityPercent : 0;
      return '☔ **Rain Outlook for $locName**\n\n'
          '• **Current Condition**: ${curr.condition} ($rain mm/h)\n'
          '• **Probability Next Hours**: **$rainProb%**\n'
          '• **Advice**: ${rainProb > 40 || rain > 0 ? "Keep an umbrella handy today." : "No significant rain expected in the immediate window."}';
    }

    return '🤖 **Mausam AI Summary for $locName**\n\n'
        '• **Temperature**: $temp°C (Feels like $feelsLike°C)\n'
        '• **Condition**: ${curr.condition}\n'
        '• **Air Quality**: AQI $aqiVal ($aqiCat)\n'
        '• **UV Index**: ${uv.toStringAsFixed(1)}\n'
        '• **Active Persona**: $persona\n\n'
        'I am continuously monitoring atmospheric changes for you. Feel free to ask about specific workout times, commute safety, or what to wear!';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final userState = ref.watch(userProvider);
    final locationState = ref.watch(locationProvider);
    final dash = ref.watch(weatherDashboardProvider);

    final persona = userState.selectedPersona ?? 'Fitness';
    final data = dash.data;

    final locName = locationState.cityName.isNotEmpty
        ? locationState.cityName.split(',').first
        : (data?.current.location ?? 'San Francisco');

    final currentTemp = data != null ? '${data.current.temperatureCelsius.round()}°C' : '24°C';
    final condition = data?.current.condition ?? 'Clear Sky';

    return Container(
      height: screenHeight * 0.84,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xF20B0D12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0x3D00F2FE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Column(
            children: [
              // 1. Drag handle & Header
              _buildHeader(context, locName: locName, temp: currentTemp, condition: condition, persona: persona),

              // 2. Quick Prompts Horizontal Carousel
              _buildQuickPromptsBar(),

              const Divider(height: 1, color: Color(0x1AFFFFFF)),

              // 3. Messages Stream
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

              // 4. Input Bar
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
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x2000F2FE),
            Color(0x000B0D12),
          ],
        ),
      ),
      child: Column(
        children: [
          // Drag indicator
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
              // Glowing AI Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F2FE).withValues(alpha: 0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
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
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00F2FE),
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
                      '📍 $locName · $temp · $condition · $persona',
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
            backgroundColor: const Color(0xFF181E2E),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
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
                color: const Color(0xFF1B2336),
                border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF00F2FE),
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1E283F) : const Color(0xFF141926),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF4FACFE).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
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
              color: const Color(0xFF1B2336),
              border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF00F2FE),
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141926),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F2FE)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Mausam AI is thinking...',
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
        color: Color(0xFF0D1017),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF171C28),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                onSubmitted: _handleSubmitted,
                style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask Mausam AI about weather & your day...',
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
                gradient: hasText
                    ? const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)])
                    : LinearGradient(colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ]),
                boxShadow: hasText
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00F2FE).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: hasText ? Colors.black : Colors.white54,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
