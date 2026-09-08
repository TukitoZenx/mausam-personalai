import React from 'react';
import { GlassCard } from './ui/GlassCard';
import {
  CloudSun,
  TrendingUp,
  Wind,
  ShieldAlert,
  Sliders,
  Compass,
  Bot,
  Zap,
  type LucideIcon,
} from 'lucide-react';

interface FeatureItem {
  icon: LucideIcon;
  title: string;
  category: string;
  description: string;
  codeAnchor: string;
  accent: string;
}

const features: FeatureItem[] = [
  {
    icon: CloudSun,
    category: 'METEOROLOGY',
    title: 'Real-Time Hyperlocal Telemetry',
    description:
      'Grounded in Open-Meteo & OpenWeatherMap APIs with 10-minute Redis caching. Tracks temperature, feels-like, dew point, humidity, pressure, and wind speed.',
    codeAnchor: 'weather_service.py',
    accent: 'text-amber-400',
  },
  {
    icon: TrendingUp,
    category: 'FORECASTING',
    title: 'Hourly & 7-Day Precision Forecasts',
    description:
      'Granular hourly precipitation curves, rain probabilities, overnight lows, and daily progression with tabular typography for crisp readability.',
    codeAnchor: 'forecast_screen.dart',
    accent: 'text-sky-400',
  },
  {
    icon: Wind,
    category: 'AIR QUALITY',
    title: 'Live AQI & Respiratory Health',
    description:
      'Real-time European/US AQI standards, particulate monitoring (PM2.5, PM10, Ozone), with automatic mask and exertion advisories for sensitive groups.',
    codeAnchor: 'aqi.py & AlertService',
    accent: 'text-emerald-400',
  },
  {
    icon: ShieldAlert,
    category: 'ADVISORIES',
    title: 'Severe Environmental Alerts',
    description:
      'Instant alert notifications for severe storms, heat warnings, and custom sensitivities like dust, pollen, smoke, high humidity, and monsoon damp.',
    codeAnchor: 'alerts_screen.dart',
    accent: 'text-red-400',
  },
  {
    icon: Sliders,
    category: 'INTELLIGENCE',
    title: 'Adaptive Persona Reranking Engine',
    description:
      'Deterministic rule-based card scoring combined with a lightweight scikit-learn GradientBoostingClassifier ML reranker with mandatory safety fallback.',
    codeAnchor: 'reranker.py & PersonalizationService',
    accent: 'text-purple-400',
  },
  {
    icon: Compass,
    category: 'GEOLOCATION',
    title: 'Multi-Destination Switching & Caching',
    description:
      'Automatic device GPS location retrieval, forward/reverse geocoding, and saved city favorites with offline fallback for reliable travel.',
    codeAnchor: 'locations.py & saved_locations_screen.dart',
    accent: 'text-blue-400',
  },
  {
    icon: Bot,
    category: 'CONVERSATIONAL AI',
    title: 'Mausam Weather AI Assistant',
    description:
      'Centerpiece natural language weather conversationalist. Inquire directly about commute viability, workout timing, or weekend packing in natural prose.',
    codeAnchor: 'chat_screen.dart & chat.py',
    accent: 'text-zinc-200',
  },
];

export const CoreFeatures: React.FC = () => {
  return (
    <section id="features" className="py-24 px-4 max-w-6xl mx-auto relative z-10">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/[0.04] border border-white/[0.08] text-xs font-medium text-obsidian-300 mb-4">
          <Zap size={12} className="text-sky-400" />
          <span>Engineered Capabilities</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-normal tracking-tight text-white mb-4">
          Built on real physics,{' '}
          <span className="font-serif italic text-obsidian-200">not generic summaries</span>.
        </h2>
        <p className="text-obsidian-300 text-sm sm:text-base leading-relaxed font-light">
          Every screen in Mausam PersonalAI queries actual meteorological sensors and adapts dynamically through an on-device persona pipeline.
        </p>
      </div>

      {/* 7-Card Grid with Minimal Line Icons */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {features.map((feat, idx) => {
          const Icon = feat.icon;
          const isWide = idx === 6; // Last item (Weather AI) spans nicely
          return (
            <GlassCard
              key={feat.title}
              hoverEffect
              className={`p-6 md:p-7 flex flex-col justify-between ${
                isWide ? 'md:col-span-2 lg:col-span-3' : ''
              }`}
            >
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="w-10 h-10 rounded-xl bg-white/[0.05] border border-white/[0.08] flex items-center justify-center text-white">
                    <Icon size={18} className={feat.accent} />
                  </div>
                  <span className="text-[10px] font-mono tracking-widest text-obsidian-400 uppercase">
                    {feat.category}
                  </span>
                </div>

                <h3 className="text-base font-semibold text-white mb-2 tracking-tight">
                  {feat.title}
                </h3>
                <p className="text-xs text-obsidian-300 leading-relaxed font-light">
                  {feat.description}
                </p>
              </div>

              <div className="mt-6 pt-3 border-t border-white/[0.06] flex items-center justify-between text-[11px] text-obsidian-500 font-mono">
                <span>Ref: {feat.codeAnchor}</span>
                <span className="text-obsidian-400 font-sans font-medium">Verified</span>
              </div>
            </GlassCard>
          );
        })}
      </div>
    </section>
  );
};
