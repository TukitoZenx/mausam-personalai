import React from 'react';
import { GlassCard } from './ui/GlassCard';
import {
  Smartphone,
  Server,
  Cpu,
  ShieldCheck,
  CheckCircle2,
  Terminal,
} from 'lucide-react';

export const ArchitectureGrid: React.FC = () => {
  const stackItems = [
    {
      icon: Smartphone,
      title: 'Flutter 3.22+ Mobile Client',
      category: 'CLIENT ARCHITECTURE',
      description:
        'Engineered with Riverpod, custom CustomPainters with pre-allocated paint instances, isolated RepaintBoundaries, and a phased startup sequence reaching First Contentful Paint in <210ms.',
      bullets: [
        'Riverpod reactive state management',
        'Tabular figures typography matching Apple Weather',
        'Zero-config team Google Sign-In keystore',
      ],
      badge: 'Dart 3.4',
    },
    {
      icon: Server,
      title: 'FastAPI Context & Personalization Engine',
      category: 'BACKEND SERVICES',
      description:
        'High-performance async Python backend utilizing Pydantic v2 schemas, Open-Meteo and OpenWeatherMap adapters, and Redis caching (10m TTL for current, 30m for forecast).',
      bullets: [
        'Stale-cache fallback during provider outages',
        'PostgreSQL & PostGIS geocoding store',
        'Async connection pooling with asyncpg',
      ],
      badge: 'Python 3.11',
    },
    {
      icon: Cpu,
      title: 'Scikit-Learn ML Reranker',
      category: 'ADAPTIVE INTELLIGENCE',
      description:
        'Gated GradientBoostingClassifier model that re-ranks card priority based on historical interaction patterns (N ≥ 20 interaction threshold) with deterministic rules fallback.',
      bullets: [
        '10-card catalog integrity preserved',
        'Confidence margin threshold (≥ 0.08)',
        'Zero server-error fallback guarantee',
      ],
      badge: 'scikit-learn',
    },
    {
      icon: ShieldCheck,
      title: 'Privacy-First Architecture',
      category: 'DATA ETHICS',
      description:
        'Mausam was designed as an authentic utility without advertisement networks, social trackers, or data broker integrations. Your preferences live on your device.',
      bullets: [
        'Zero commercial tracker SDKs',
        'Minimal geographic precision retention',
        'Strict on-device routine configuration',
      ],
      badge: 'Clean Privacy',
    },
  ];

  return (
    <section id="architecture" className="py-24 px-4 max-w-6xl mx-auto relative z-10">
      <div className="text-center max-w-2xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/[0.04] border border-white/[0.08] text-xs font-medium text-obsidian-300 mb-4">
          <Terminal size={12} className="text-emerald-400" />
          <span>Production Stack</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-normal tracking-tight text-white mb-4">
          Modern engineering.{' '}
          <span className="font-serif italic text-obsidian-200">Zero bloat</span>.
        </h2>
        <p className="text-obsidian-300 text-sm sm:text-base leading-relaxed font-light">
          Inspecting the actual code reveals a disciplined architecture combining high-frame-rate mobile UI with containerized Python microservices.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {stackItems.map((item) => {
          const Icon = item.icon;
          return (
            <GlassCard key={item.title} hoverEffect className="p-7 flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="w-10 h-10 rounded-xl bg-white/[0.05] border border-white/[0.08] flex items-center justify-center text-white">
                    <Icon size={18} />
                  </div>
                  <span className="text-[10px] font-mono px-2.5 py-1 rounded-md bg-white/[0.04] border border-white/[0.08] text-obsidian-300">
                    {item.badge}
                  </span>
                </div>

                <div className="text-[10px] font-mono text-obsidian-400 uppercase tracking-widest mb-1">
                  {item.category}
                </div>
                <h3 className="text-lg font-semibold text-white mb-2 tracking-tight">
                  {item.title}
                </h3>
                <p className="text-xs text-obsidian-300 leading-relaxed font-light mb-6">
                  {item.description}
                </p>
              </div>

              <div className="pt-4 border-t border-white/[0.06] flex flex-col gap-2">
                {item.bullets.map((b) => (
                  <div key={b} className="flex items-center gap-2 text-xs text-obsidian-300">
                    <CheckCircle2 size={13} className="text-emerald-400 shrink-0" />
                    <span>{b}</span>
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
