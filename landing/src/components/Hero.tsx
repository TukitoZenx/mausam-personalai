import React from 'react';
import { CONFIG } from '../config';
import { MausamLogo } from './ui/MausamLogo';
import { GlassCard } from './ui/GlassCard';
import {
  Download,
  Github,
  ArrowRight,
  Sun,
  Wind,
  Droplets,
  Activity,
  Zap,
  CheckCircle2,
} from 'lucide-react';

export const Hero: React.FC = () => {
  const hasApk = Boolean(CONFIG.APK_URL && CONFIG.APK_URL.trim().length > 0);

  return (
    <section className="relative pt-32 pb-20 md:pt-44 md:pb-32 px-4 overflow-hidden">
      {/* Ambient background glows */}
      <div className="pointer-events-none absolute top-12 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-gradient-to-b from-sky-500/10 via-amber-500/5 to-transparent blur-3xl opacity-60 rounded-full" />
      <div className="pointer-events-none absolute top-36 -left-32 w-96 h-96 bg-amber-500/5 blur-3xl rounded-full" />
      <div className="pointer-events-none absolute top-48 -right-32 w-96 h-96 bg-sky-500/5 blur-3xl rounded-full" />

      <div className="max-w-6xl mx-auto flex flex-col items-center text-center relative z-10">
        {/* Subtle pill badge */}
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white/[0.04] border border-white/[0.08] text-xs font-medium text-obsidian-200 mb-8 animate-fade-up">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
          <span>v{CONFIG.VERSION} • Flutter & FastAPI Context Architecture</span>
          <span className="text-obsidian-500">|</span>
          <span className="text-obsidian-400">Open-Meteo & ML Reranked</span>
        </div>

        {/* Hero Title with Instrument Serif + Inter */}
        <h1 className="text-4xl sm:text-6xl md:text-7xl lg:text-8xl font-normal tracking-tight max-w-4xl text-obsidian-100 mb-6 leading-[1.05]">
          Your weather,{' '}
          <span className="font-serif italic font-normal text-white">personalized</span>{' '}
          for how you live.
        </h1>

        {/* Value Prop Subtitle */}
        <p className="text-base sm:text-lg md:text-xl text-obsidian-300 max-w-2xl font-light mb-10 leading-relaxed">
          Generic forecasts report the sky. <strong className="font-medium text-white">Mausam PersonalAI</strong> interprets it for your routine—evaluating workout windows, AQI sensitivity, commute disruptions, and travel essentials in real time.
        </p>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center gap-4 mb-16 w-full sm:w-auto">
          {hasApk ? (
            <a
              href={CONFIG.APK_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto flex items-center justify-center gap-2 text-sm font-semibold text-obsidian-950 bg-white hover:bg-obsidian-200 px-7 py-3.5 rounded-2xl shadow-[0_4px_24px_rgba(255,255,255,0.2)] transition-all duration-200 hover:scale-[1.02]"
            >
              <Download size={16} />
              <span>Download Android APK</span>
            </a>
          ) : (
            <div className="relative group w-full sm:w-auto">
              <button
                disabled
                className="w-full sm:w-auto flex items-center justify-center gap-2 text-sm font-medium text-obsidian-400 bg-white/[0.05] border border-white/[0.1] px-7 py-3.5 rounded-2xl cursor-not-allowed opacity-90"
              >
                <Download size={16} className="opacity-40" />
                <span>APK Coming Soon</span>
              </button>
              <div className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 hidden group-hover:block w-64 bg-obsidian-900 border border-white/10 text-xs text-obsidian-300 p-2.5 rounded-xl shadow-2xl text-center pointer-events-none">
                Release pipeline active. You can clone the repo and launch with Flutter immediately.
              </div>
            </div>
          )}

          <a
            href={CONFIG.GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto flex items-center justify-center gap-2 text-sm font-medium text-obsidian-200 hover:text-white bg-white/[0.03] hover:bg-white/[0.08] border border-white/[0.09] hover:border-white/20 px-7 py-3.5 rounded-2xl transition-all duration-200"
          >
            <Github size={16} />
            <span>Explore Codebase</span>
            <ArrowRight size={14} className="opacity-60" />
          </a>
        </div>

        {/* Hero Interactive App Device Representation (Obsidian Flutter Mockup) */}
        <div className="w-full max-w-4xl relative">
          {/* Subtle perimeter border glow */}
          <div className="absolute -inset-1 rounded-[32px] bg-gradient-to-b from-white/10 via-white/[0.02] to-transparent blur-sm -z-10" />

          <GlassCard className="p-6 md:p-8 text-left border-white/[0.1] bg-obsidian-900/90 shadow-2xl">
            {/* Top Device Bar */}
            <div className="flex items-center justify-between border-b border-white/[0.06] pb-4 mb-6">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-white/[0.06] border border-white/[0.1] flex items-center justify-center">
                  <MausamLogo size={16} />
                </div>
                <div>
                  <div className="text-xs font-semibold text-white tracking-wide">Mausam PersonalAI Shell</div>
                  <div className="text-[11px] text-obsidian-400">Obsidian Monochrome • Active City: New Delhi</div>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-[11px] font-medium text-emerald-300">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                  Live Sync
                </span>
                <span className="text-xs text-obsidian-400 font-mono hidden sm:inline">Open-Meteo & Redis</span>
              </div>
            </div>

            {/* Hero App Grid Simulation */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-5">
              {/* Main Weather Card */}
              <div className="md:col-span-7 rounded-2xl bg-white/[0.03] border border-white/[0.08] p-5 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between text-xs text-obsidian-400 font-medium mb-1">
                    <span className="uppercase tracking-wider">Current Forecast</span>
                    <span className="text-obsidian-300">18:45 IST</span>
                  </div>
                  <div className="flex items-baseline gap-3 my-2">
                    <span className="text-5xl md:text-6xl font-semibold tracking-tighter text-white tabular-nums">26°</span>
                    <div className="flex flex-col">
                      <span className="text-base font-medium text-obsidian-100">Partly Cloudy</span>
                      <span className="text-xs text-obsidian-400">Feels like 27° • Dew 16°</span>
                    </div>
                  </div>
                </div>

                {/* 4-Stat Micro Strip */}
                <div className="grid grid-cols-4 gap-2 pt-4 border-t border-white/[0.06] mt-4">
                  <div>
                    <div className="text-[10px] text-obsidian-400 uppercase tracking-wider flex items-center gap-1">
                      <Sun size={11} className="text-amber-400/80" /> UV
                    </div>
                    <div className="text-xs font-semibold text-obsidian-200 mt-0.5">3.2 Mod</div>
                  </div>
                  <div>
                    <div className="text-[10px] text-obsidian-400 uppercase tracking-wider flex items-center gap-1">
                      <Wind size={11} className="text-sky-400/80" /> Wind
                    </div>
                    <div className="text-xs font-semibold text-obsidian-200 mt-0.5">14 km/h</div>
                  </div>
                  <div>
                    <div className="text-[10px] text-obsidian-400 uppercase tracking-wider flex items-center gap-1">
                      <Droplets size={11} className="text-blue-400/80" /> Humidity
                    </div>
                    <div className="text-xs font-semibold text-obsidian-200 mt-0.5">58%</div>
                  </div>
                  <div>
                    <div className="text-[10px] text-obsidian-400 uppercase tracking-wider flex items-center gap-1">
                      <Activity size={11} className="text-emerald-400/80" /> AQI
                    </div>
                    <div className="text-xs font-semibold text-obsidian-200 mt-0.5">48 Good</div>
                  </div>
                </div>
              </div>

              {/* Persona Context Card Simulation */}
              <div className="md:col-span-5 flex flex-col gap-3">
                {/* Active Persona Badge */}
                <div className="rounded-2xl bg-white/[0.04] border border-white/[0.1] p-4 flex flex-col justify-between flex-1">
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-[11px] font-semibold tracking-wider text-obsidian-400 uppercase">
                        Active Persona Engine
                      </span>
                      <span className="text-[10px] bg-white/10 text-white px-2 py-0.5 rounded-full font-medium">
                        Fitness
                      </span>
                    </div>
                    <div className="text-sm font-semibold text-white mb-1">Optimal Workout Window</div>
                    <p className="text-xs text-obsidian-300 leading-relaxed">
                      Safe run window: <strong className="text-white font-medium">06:00 – 08:30 AM</strong>. AQI 48 and UV under 2.0 offer peak exertion conditions before temperature rises.
                    </p>
                  </div>

                  <div className="mt-3 pt-2.5 border-t border-white/[0.06] flex items-center justify-between text-[11px]">
                    <span className="text-obsidian-400">ML Confidence: 94.2%</span>
                    <span className="text-emerald-400 flex items-center gap-1 font-medium">
                      <CheckCircle2 size={12} /> Favorable
                    </span>
                  </div>
                </div>

                {/* Commute / Advisory Quick Banner */}
                <div className="rounded-2xl bg-white/[0.02] border border-white/[0.06] p-3 flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2 text-obsidian-300">
                    <Zap size={13} className="text-amber-400" />
                    <span>Commute status: <strong className="text-obsidian-100">CLEAR</strong> (Dry roads)</span>
                  </div>
                  <span className="text-[11px] text-obsidian-500 font-mono">18:00</span>
                </div>
              </div>
            </div>

            {/* Bottom 3-Destination Dock Representation matching App Shell */}
            <div className="mt-6 pt-4 border-t border-white/[0.06] flex items-center justify-center">
              <div className="w-full max-w-xs flex items-center justify-between px-6 py-2 rounded-2xl bg-black/80 border border-white/[0.08]">
                <div className="text-xs text-white font-medium flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-white" />
                  <span>Home</span>
                </div>
                {/* Center raised Weather AI button */}
                <div className="w-8 h-8 rounded-full bg-white/[0.12] border border-white/20 flex items-center justify-center text-white shadow-[0_0_12px_rgba(255,255,255,0.2)]">
                  <MausamLogo size={14} />
                </div>
                <div className="text-xs text-obsidian-400 flex items-center gap-1.5">
                  <span>Settings</span>
                </div>
              </div>
            </div>
          </GlassCard>
        </div>

        {/* Feature Highlights Strip */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8 mt-16 max-w-4xl w-full text-left">
          <div className="flex flex-col gap-1 border-l border-white/[0.08] pl-4">
            <span className="text-xl font-semibold text-white tracking-tight">8 Personas</span>
            <span className="text-xs text-obsidian-400">Tailored from code routines</span>
          </div>
          <div className="flex flex-col gap-1 border-l border-white/[0.08] pl-4">
            <span className="text-xl font-semibold text-white tracking-tight">&lt; 210ms FCP</span>
            <span className="text-xs text-obsidian-400">Phased Flutter cold start</span>
          </div>
          <div className="flex flex-col gap-1 border-l border-white/[0.08] pl-4">
            <span className="text-xl font-semibold text-white tracking-tight">Zero Trackers</span>
            <span className="text-xs text-obsidian-400">On-device privacy first</span>
          </div>
          <div className="flex flex-col gap-1 border-l border-white/[0.08] pl-4">
            <span className="text-xl font-semibold text-white tracking-tight">Open-Meteo</span>
            <span className="text-xs text-obsidian-400">Cached with Redis TTL</span>
          </div>
        </div>
      </div>
    </section>
  );
};
