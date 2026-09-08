import React, { useState } from 'react';
import { GlassCard } from './ui/GlassCard';
import {
  Activity,
  Heart,
  Plane,
  Car,
  Users,
  Sprout,
  CalendarDays,
  Camera,
  Check,
  Sparkles,
  type LucideIcon,
} from 'lucide-react';

interface PersonaData {
  id: string;
  title: string;
  roleSubtitle: string;
  tagline: string;
  icon: LucideIcon;
  accentColor: string;
  hexColor: string;
  primaryMetric: { label: string; value: string; support: string };
  secondaryMetric: { label: string; value: string; support: string };
  reasonCodes: string[];
  sampleCard: {
    title: string;
    subtitle: string;
    advice: string;
    category: string;
  };
}

export const personas: PersonaData[] = [
  {
    id: 'fitness',
    title: 'Outdoor Fitness',
    roleSubtitle: 'Runners, cyclists & athletes',
    tagline: 'Workout windows, UV exertion curves, and heat/hydration caution.',
    icon: Activity,
    accentColor: 'text-obsidian-100',
    hexColor: '#FAFAFA',
    primaryMetric: { label: 'RUN WINDOW', value: '06:00 – 08:30', support: 'Great for Running' },
    secondaryMetric: { label: 'HEAT EXERTION', value: '23° Feels', support: 'Moderate intensity safe' },
    reasonCodes: ['#OutdoorFitness', '#RunningWindow', '#Hydration'],
    sampleCard: {
      title: 'Optimal Outdoor Run Window',
      subtitle: 'Great for Running • Morning 6:00 AM - 8:30 AM',
      advice: 'Air is crisp at 22°C with 55% humidity. Peak heat and UV index start accelerating after 09:15 AM.',
      category: 'Fitness',
    },
  },
  {
    id: 'health',
    title: 'Health-Conscious',
    roleSubtitle: 'Respiratory & sensitivity care',
    tagline: 'AQI thresholds, mask advisories, humidity index, and UV 30+ guidance.',
    icon: Heart,
    accentColor: 'text-zinc-300',
    hexColor: '#D4D4D8',
    primaryMetric: { label: 'AIR QUALITY', value: 'AQI 42', support: 'Good Condition' },
    secondaryMetric: { label: 'UV INDEX', value: '3.4 Mod', support: 'SPF 30+ recommended' },
    reasonCodes: ['#AirQuality', '#HealthPrecautions', '#UVIndex'],
    sampleCard: {
      title: 'Clean Air Status & UV Advisory',
      subtitle: 'AQI 42 (Good) • Great condition for outdoor breathing',
      advice: 'No respiratory masks required today. UV peaks at 12:30 PM—apply sunscreen if outdoors for >30 mins.',
      category: 'Health',
    },
  },
  {
    id: 'traveler',
    title: 'Active Traveler',
    roleSubtitle: 'Exploring new destinations',
    tagline: 'Multi-destination switching, packing lists, and sightseeing ratings.',
    icon: Plane,
    accentColor: 'text-zinc-400',
    hexColor: '#A1A1AA',
    primaryMetric: { label: 'SIGHTSEEING', value: '9.2 / 10', support: 'Favorable for Travel' },
    secondaryMetric: { label: 'PACKING', value: 'Light Layer', support: 'Sunglasses & windbreaker' },
    reasonCodes: ['#TravelSuitability', '#Sightseeing', '#PackingTips'],
    sampleCard: {
      title: 'Daily Packing & Sightseeing Essentials',
      subtitle: 'Recommended: Light Jacket or Sweater • 19° to 27°',
      advice: 'Mild evening drop expected after 19:00. Clear skies throughout the city; ideal for walking tours.',
      category: 'Traveler',
    },
  },
  {
    id: 'commuter',
    title: 'Daily Commuter',
    roleSubtitle: 'Transit, highway & urban routes',
    tagline: 'Visibility distance, wet road disruption status, and crosswinds.',
    icon: Car,
    accentColor: 'text-sky-400',
    hexColor: '#38BDF8',
    primaryMetric: { label: 'COMMUTE STATUS', value: 'CLEAR', support: 'Dry roads, 10 km vis' },
    secondaryMetric: { label: 'WIND VELOCITY', value: '16 km/h', support: 'Crosswinds negligible' },
    reasonCodes: ['#CommuteWarning', '#RainCheck', '#Visibility'],
    sampleCard: {
      title: 'Transit & Route Visibility Check',
      subtitle: 'CLEAR • 10.0 km sight distance across highways',
      advice: 'No precipitation radar signals detected on morning or evening travel corridors. Typical transit times.',
      category: 'Commuter',
    },
  },
  {
    id: 'family',
    title: 'Parents / Family',
    roleSubtitle: 'School runs & family outings',
    tagline: 'School run advisories, playground safety, and rain arrival warnings.',
    icon: Users,
    accentColor: 'text-pink-400',
    hexColor: '#F472B6',
    primaryMetric: { label: 'SCHOOL RUN', value: 'Pleasant', support: 'No rain delays' },
    secondaryMetric: { label: 'PLAYGROUND', value: 'Safe Heat', support: 'UV under caution limit' },
    reasonCodes: ['#FamilyCare', '#SchoolRun', '#PlaygroundSafety'],
    sampleCard: {
      title: 'School Morning & Afternoon Advisory',
      subtitle: 'Dry morning pickup • Light cloud cover in afternoon',
      advice: 'Pack a light jacket for early drop-off at 18°C. Afternoon temperatures settle safely below 30°C.',
      category: 'Family',
    },
  },
  {
    id: 'garden',
    title: 'Garden & Farm',
    roleSubtitle: 'Growers, horticulturists & fields',
    tagline: 'Rainfall accumulation (mm), frost risk monitoring, and spray windows.',
    icon: Sprout,
    accentColor: 'text-emerald-400',
    hexColor: '#34D399',
    primaryMetric: { label: 'PRECIPITATION', value: '0.0 mm', support: 'Dry past 24h' },
    secondaryMetric: { label: 'FROST RISK', value: 'Low', support: 'Overnight low 14°C' },
    reasonCodes: ['#RainAccumulation', '#FrostRisk', '#SoilMoisture'],
    sampleCard: {
      title: 'Irrigation & Frost Monitoring',
      subtitle: 'Zero frost risk • High soil evaporation rate',
      advice: 'Overnight lows will not drop below 14°C. Scheduled drip irrigation recommended due to low humidity.',
      category: 'Garden',
    },
  },
  {
    id: 'events',
    title: 'Event Planner',
    roleSubtitle: 'Outdoor weddings, sports & festivals',
    tagline: 'Rain probability curves, gust monitoring, and outdoor comfort index.',
    icon: CalendarDays,
    accentColor: 'text-amber-400',
    hexColor: '#F59E0B',
    primaryMetric: { label: 'RAIN PROB', value: '5%', support: 'Clear venue window' },
    secondaryMetric: { label: 'GUST SPEED', value: '18 km/h', support: 'Canopy safe' },
    reasonCodes: ['#RainProbability', '#WindGusts', '#OutdoorComfort'],
    sampleCard: {
      title: 'Outdoor Venue Comfort Index',
      subtitle: 'Optimal conditions • 5% rain probability window',
      advice: 'Steady atmospheric pressure at 1014 mbar. Tents and outdoor setups are secure with gentle breezes.',
      category: 'Events',
    },
  },
  {
    id: 'creative',
    title: 'Photographer / Golden Hour',
    roleSubtitle: 'Visual creatives & golden hour chasers',
    tagline: 'Evening golden hour (~50m before sunset), solar noon, and moon phases.',
    icon: Camera,
    accentColor: 'text-amber-300',
    hexColor: '#FBBF24',
    primaryMetric: { label: 'GOLDEN HOUR', value: '17:42 – 18:32', support: 'Warm ambient light' },
    secondaryMetric: { label: 'MOON PHASE', value: 'Waxing Gibbous', support: '78% illumination' },
    reasonCodes: ['#GoldenHour', '#SolarNoon', '#NaturalLighting'],
    sampleCard: {
      title: 'Golden Hour & Light Intelligence',
      subtitle: 'Golden window begins 17:42 • Sunset at 18:32 IST',
      advice: 'Atmosphere is clear with negligible haze. Optimal 50-minute warm light corridor for natural portraits.',
      category: 'Creative',
    },
  },
];

export const WhatIsMausam: React.FC = () => {
  const [activePersona, setActivePersona] = useState<PersonaData>(personas[0]);

  return (
    <section id="personas" className="py-24 px-4 relative z-10 max-w-6xl mx-auto">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/[0.04] border border-white/[0.08] text-xs font-medium text-obsidian-300 mb-4">
          <Sparkles size={12} className="text-amber-400" />
          <span>Extracted From Actual Codebase</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-normal tracking-tight text-white mb-4">
          Intelligent weather for <span className="font-serif italic text-obsidian-200">every routine</span>.
        </h2>
        <p className="text-obsidian-300 text-sm sm:text-base leading-relaxed font-light">
          Weather doesn&apos;t affect everyone the same way. Mausam includes dedicated, code-level persona algorithms that re-rank cards, calculate safe exertion hours, and evaluate commute disruption automatically.
        </p>
      </div>

      {/* Interactive Persona Grid Selector */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-10">
        {personas.map((p) => {
          const Icon = p.icon;
          const isActive = activePersona.id === p.id;
          return (
            <button
              key={p.id}
              onClick={() => setActivePersona(p)}
              className={`flex flex-col items-start p-4 rounded-2xl text-left transition-all duration-200 border relative overflow-hidden group ${
                isActive
                  ? 'bg-white/[0.08] border-white/30 shadow-[0_4px_20px_rgba(255,255,255,0.06)]'
                  : 'bg-white/[0.02] border-white/[0.06] hover:bg-white/[0.04] hover:border-white/15'
              }`}
            >
              <div className="flex items-center justify-between w-full mb-3">
                <div
                  className="w-8 h-8 rounded-lg flex items-center justify-center transition-colors"
                  style={{ backgroundColor: `${p.hexColor}15`, color: p.hexColor }}
                >
                  <Icon size={16} />
                </div>
                {isActive && (
                  <span className="w-2 h-2 rounded-full" style={{ backgroundColor: p.hexColor }} />
                )}
              </div>
              <div className="text-xs font-semibold text-white group-hover:text-white transition-colors">
                {p.title}
              </div>
              <div className="text-[11px] text-obsidian-400 line-clamp-1 mt-0.5">
                {p.roleSubtitle}
              </div>
            </button>
          );
        })}
      </div>

      {/* Dynamic Active Persona Showcase */}
      <GlassCard className="p-6 md:p-10 border-white/[0.12] bg-obsidian-900/90" glow="amber">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          {/* Left Context & Persona Details */}
          <div className="lg:col-span-6 flex flex-col justify-between">
            <div>
              <div className="flex items-center gap-2 mb-3">
                <span
                  className="text-xs font-mono uppercase tracking-wider px-2.5 py-1 rounded-md border"
                  style={{
                    backgroundColor: `${activePersona.hexColor}10`,
                    borderColor: `${activePersona.hexColor}30`,
                    color: activePersona.hexColor,
                  }}
                >
                  Active Persona: {activePersona.title}
                </span>
                <span className="text-xs text-obsidian-400 font-mono">Dynamic Card Ranking</span>
              </div>

              <h3 className="text-2xl sm:text-3xl font-normal text-white mb-3">
                {activePersona.tagline}
              </h3>

              <div className="flex flex-wrap gap-2 my-4">
                {activePersona.reasonCodes.map((code) => (
                  <span
                    key={code}
                    className="text-[11px] font-mono px-2 py-0.5 rounded bg-white/[0.04] border border-white/[0.08] text-obsidian-300"
                  >
                    {code}
                  </span>
                ))}
              </div>
            </div>

            {/* Metrics extracted from code logic */}
            <div className="grid grid-cols-2 gap-4 pt-6 border-t border-white/[0.08] mt-4">
              <div className="rounded-xl bg-white/[0.02] border border-white/[0.06] p-3.5">
                <div className="text-[10px] text-obsidian-400 uppercase tracking-wider mb-1">
                  {activePersona.primaryMetric.label}
                </div>
                <div className="text-lg font-semibold text-white tracking-tight tabular-nums">
                  {activePersona.primaryMetric.value}
                </div>
                <div className="text-[11px] text-obsidian-400 mt-0.5">
                  {activePersona.primaryMetric.support}
                </div>
              </div>

              <div className="rounded-xl bg-white/[0.02] border border-white/[0.06] p-3.5">
                <div className="text-[10px] text-obsidian-400 uppercase tracking-wider mb-1">
                  {activePersona.secondaryMetric.label}
                </div>
                <div className="text-lg font-semibold text-white tracking-tight tabular-nums">
                  {activePersona.secondaryMetric.value}
                </div>
                <div className="text-[11px] text-obsidian-400 mt-0.5">
                  {activePersona.secondaryMetric.support}
                </div>
              </div>
            </div>
          </div>

          {/* Right: Live Card Rendered Exactly As in Mobile App Feed */}
          <div className="lg:col-span-6">
            <div className="text-xs font-mono text-obsidian-400 mb-3 flex items-center justify-between">
              <span>GENERATED CARD FEED OUTPUT</span>
              <span className="flex items-center gap-1 text-emerald-400">
                <Check size={12} /> ML Reranker Score: 4.9
              </span>
            </div>

            {/* Actual Card layout from personalized_context_card.dart */}
            <div className="rounded-2xl bg-obsidian-800/90 border border-white/[0.12] p-5 shadow-xl relative overflow-hidden">
              <div className="flex items-center justify-between mb-3">
                <span className="text-[11px] font-semibold text-obsidian-400 uppercase tracking-wider">
                  {activePersona.sampleCard.category} ADVISORY
                </span>
                <span
                  className="w-2.5 h-2.5 rounded-full"
                  style={{ backgroundColor: activePersona.hexColor }}
                />
              </div>

              <div className="text-base font-semibold text-white mb-1">
                {activePersona.sampleCard.title}
              </div>

              <div className="text-xs text-obsidian-300 font-medium mb-3">
                {activePersona.sampleCard.subtitle}
              </div>

              <p className="text-xs text-obsidian-300 leading-relaxed bg-white/[0.02] border border-white/[0.05] p-3 rounded-xl">
                {activePersona.sampleCard.advice}
              </p>

              <div className="mt-4 pt-3 border-t border-white/[0.06] flex items-center justify-between text-[11px] text-obsidian-400">
                <span>Deterministic rules + ML Gated</span>
                <span className="text-white hover:underline cursor-pointer flex items-center gap-1 font-medium">
                  Detailed Advice &rarr;
                </span>
              </div>
            </div>
          </div>
        </div>
      </GlassCard>
    </section>
  );
};
