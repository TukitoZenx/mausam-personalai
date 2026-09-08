import React from 'react';
import { GlassCard } from './ui/GlassCard';
import { UserCheck, Eye, Compass } from 'lucide-react';

export const HowItWorks: React.FC = () => {
  const steps = [
    {
      step: '01',
      title: 'Choose Your Context',
      subtitle: 'Persona & Sensitivity Selection',
      description:
        'Select your lifestyle archetype—Fitness, Health, Traveler, Commuter, Family, Garden, or Events—or calibrate personal environmental sensitivities (Dust, Pollen, AQI, Heat).',
      icon: UserCheck,
      details: [
        '7 extensible persona profiles',
        'Fine-grained trigger thresholds',
        'diurnal rhythm customization',
      ],
    },
    {
      step: '02',
      title: 'Understand Weather',
      subtitle: 'Hyperlocal Sensor Telemetry',
      description:
        'Mausam synthesizes atmospheric pressure, wind gusts, UV index, humidity, and real-time AQI particulates through high-speed Open-Meteo & Redis caching pipelines.',
      icon: Eye,
      details: [
        '10-minute fresh telemetry cache',
        'Hourly precipitation probability',
        'Sun & Golden Hour countdown',
      ],
    },
    {
      step: '03',
      title: 'Act With Insights',
      subtitle: 'Dynamic Decision Feed',
      description:
        'Instead of deciphering raw numbers, receive actionable guidance: running windows, wet-road transit statuses, packing essentials, or sensitive respiratory cautions.',
      icon: Compass,
      details: [
        'Deterministic rule prioritization',
        'Gated scikit-learn ML reranking',
        'Conversational Weather AI advice',
      ],
    },
  ];

  return (
    <section id="how-it-works" className="py-24 px-4 max-w-6xl mx-auto relative z-10">
      <div className="text-center max-w-2xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/[0.04] border border-white/[0.08] text-xs font-medium text-obsidian-300 mb-4">
          <span>The Three-Stage Engine</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-normal tracking-tight text-white mb-4">
          From raw forecast to <span className="font-serif italic text-obsidian-200">actionable context</span>.
        </h2>
        <p className="text-obsidian-300 text-sm sm:text-base leading-relaxed font-light">
          Mausam closes the gap between generic meteorological readings and what you actually need to do today.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 relative">
        {steps.map((item) => {
          const Icon = item.icon;
          return (
            <GlassCard key={item.step} hoverEffect className="p-7 flex flex-col justify-between relative group">
              <div>
                {/* Step number */}
                <div className="flex items-center justify-between mb-6">
                  <span className="text-3xl font-serif italic text-white/30 group-hover:text-white/60 transition-colors">
                    {item.step}
                  </span>
                  <div className="w-10 h-10 rounded-xl bg-white/[0.05] border border-white/[0.08] flex items-center justify-center text-white">
                    <Icon size={18} />
                  </div>
                </div>

                <div className="text-xs font-mono text-obsidian-400 uppercase tracking-wider mb-1">
                  {item.subtitle}
                </div>
                <h3 className="text-lg font-semibold text-white mb-3 tracking-tight">
                  {item.title}
                </h3>
                <p className="text-xs text-obsidian-300 leading-relaxed font-light mb-6">
                  {item.description}
                </p>
              </div>

              {/* Bullet details */}
              <div className="pt-4 border-t border-white/[0.06] flex flex-col gap-2">
                {item.details.map((detail) => (
                  <div key={detail} className="flex items-center gap-2 text-xs text-obsidian-400">
                    <span className="w-1 h-1 rounded-full bg-white/40" />
                    <span>{detail}</span>
                  </div>
                ))}
              </div>
            </GlassCard>
          );
        })}
      </div>
    </section>
  );
};
