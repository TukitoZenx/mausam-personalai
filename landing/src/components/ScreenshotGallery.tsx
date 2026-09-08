import React from 'react';
import { ScreenshotCard } from './ScreenshotCard';
import { MausamLogo } from './ui/MausamLogo';
import {
  MapPin,
  Sparkles,
  Send,
  Heart,
  Activity,
} from 'lucide-react';

export const ScreenshotGallery: React.FC = () => {
  return (
    <section id="screenshots" className="py-24 px-4 max-w-6xl mx-auto relative z-10">
      <div className="text-center max-w-2xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/[0.04] border border-white/[0.08] text-xs font-medium text-obsidian-300 mb-4">
          <Sparkles size={12} className="text-amber-400" />
          <span>Flutter Mobile Interface</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-normal tracking-tight text-white mb-4">
          Obsidian clarity across <span className="font-serif italic text-obsidian-200">every screen</span>.
        </h2>
        <p className="text-obsidian-300 text-sm sm:text-base leading-relaxed font-light">
          Dark-mode native, high contrast, and zero distractions. Replace mock screens anytime by dropping PNGs directly into <code className="text-white font-mono text-xs">public/screenshots/</code>.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* 1. hero.png */}
        <ScreenshotCard
          filename="hero.png"
          screenCategory="SHELL & IDENTITY"
          title="Atmospheric Dashboard"
          subtitle="Dynamic hourly atmospheric gradients & primary weather readout."
          features={['Atmospheric Gradient', 'Tabular Figures', 'Open-Meteo Sync']}
          mockUiRenderer={() => (
            <div className="flex flex-col justify-between h-full text-left p-2">
              <div className="flex items-center justify-between border-b border-white/[0.08] pb-2">
                <div className="flex items-center gap-1.5">
                  <MausamLogo size={14} />
                  <span className="text-[11px] font-semibold text-white">Mausam AI</span>
                </div>
                <span className="text-[10px] text-obsidian-400">New Delhi</span>
              </div>
              <div className="my-auto py-2">
                <div className="text-4xl font-semibold text-white tabular-nums tracking-tighter">28°</div>
                <div className="text-xs text-obsidian-200 mt-1">Partly Cloudy</div>
                <div className="text-[10px] text-obsidian-400 mt-0.5">High 31° • Low 19°</div>
              </div>
              <div className="rounded-xl bg-white/[0.05] p-2 border border-white/[0.08] text-[10px] text-obsidian-300 flex items-center justify-between">
                <span>AQI 48 (Good)</span>
                <span className="text-white font-mono">UV 3.4</span>
              </div>
            </div>
          )}
        />

        {/* 2. home.png */}
        <ScreenshotCard
          filename="home.png"
          screenCategory="HOME FEED"
          title="Adaptive Home Stream"
          subtitle="Dynamic persona card ranking placed directly above the hourly projection."
          features={['Dynamic Card Ranking', 'Hourly Forecast', 'Weather Intel']}
          mockUiRenderer={() => (
            <div className="flex flex-col gap-2 h-full text-left p-2">
              <div className="rounded-xl bg-white/[0.06] border border-white/[0.1] p-2.5">
                <div className="flex items-center justify-between text-[10px] text-obsidian-400 mb-1">
                  <span className="uppercase font-semibold text-white">Outdoor Exertion</span>
                  <span className="text-emerald-400">Favorable</span>
                </div>
                <div className="text-xs font-semibold text-white">06:00 – 08:30 AM</div>
                <div className="text-[10px] text-obsidian-300 mt-0.5">Optimal morning run window before midday heat.</div>
              </div>
              <div className="rounded-xl bg-white/[0.03] border border-white/[0.06] p-2 flex-1">
                <div className="text-[10px] text-obsidian-400 mb-2">Hourly Trajectory</div>
                <div className="grid grid-cols-4 gap-1 text-center text-[10px]">
                  <div><span className="text-obsidian-500">10:00</span><br/><span className="text-white font-medium">27°</span></div>
                  <div><span className="text-obsidian-500">11:00</span><br/><span className="text-white font-medium">29°</span></div>
                  <div><span className="text-obsidian-500">12:00</span><br/><span className="text-white font-medium">31°</span></div>
                  <div><span className="text-obsidian-500">13:00</span><br/><span className="text-white font-medium">30°</span></div>
                </div>
              </div>
            </div>
          )}
        />

        {/* 3. insights.png */}
        <ScreenshotCard
          filename="insights.png"
          screenCategory="RECOMMENDATIONS"
          title="Personalized Insights"
          subtitle="Commute disruptions, Golden Hour slider, and packing lists."
          features={['Golden Hour Progress', 'Commute Disruption', 'Hydration Tips']}
          mockUiRenderer={() => (
            <div className="flex flex-col gap-2 h-full text-left p-2 justify-between">
              <div className="rounded-xl bg-amber-500/10 border border-amber-500/20 p-2.5">
                <div className="flex items-center justify-between text-[10px] text-amber-300 mb-1">
                  <span>GOLDEN HOUR</span>
                  <span className="font-mono">17:42 IST</span>
                </div>
                <div className="w-full bg-amber-500/20 h-1.5 rounded-full overflow-hidden my-1">
                  <div className="bg-amber-400 h-full w-2/3 rounded-full" />
                </div>
                <div className="text-[10px] text-obsidian-300">Approaching golden light window.</div>
              </div>

              <div className="rounded-xl bg-white/[0.04] border border-white/[0.08] p-2.5">
                <div className="text-[10px] text-obsidian-400 uppercase font-semibold">Commute Warning</div>
                <div className="text-xs font-medium text-white mt-0.5">Route Condition: CLEAR</div>
                <div className="text-[10px] text-obsidian-300 mt-0.5">Roads dry; wind velocity stable at 14 km/h.</div>
              </div>
            </div>
          )}
        />

        {/* 4. weather-ai.png */}
        <ScreenshotCard
          filename="weather-ai.png"
          screenCategory="INTELLIGENCE"
          title="Mausam Weather AI"
          subtitle="Centerpiece natural language conversational weather interpreter."
          features={['Contextual Answers', 'Diurnal Reasoning', 'Zero Fluff']}
          mockUiRenderer={() => (
            <div className="flex flex-col justify-between h-full text-left p-2">
              <div className="flex flex-col gap-2">
                <div className="bg-white/[0.08] text-white text-[10px] p-2 rounded-xl rounded-tr-sm self-end max-w-[85%]">
                  Can I run outside today around 7:00 PM?
                </div>
                <div className="bg-white/[0.04] border border-white/[0.08] text-obsidian-200 text-[10px] p-2 rounded-xl rounded-tl-sm self-start max-w-[90%] flex items-start gap-1.5">
                  <MausamLogo size={12} className="text-amber-400 shrink-0 mt-0.5" />
                  <span>Yes, evening conditions settle to 24°C with low humidity. UV drops to 0.0 after 18:30 IST.</span>
                </div>
              </div>
              <div className="rounded-lg bg-black/60 border border-white/10 p-1.5 flex items-center justify-between text-[10px] text-obsidian-500">
                <span>Ask Mausam AI...</span>
                <Send size={10} className="text-obsidian-400" />
              </div>
            </div>
          )}
        />

        {/* 5. locations.png */}
        <ScreenshotCard
          filename="locations.png"
          screenCategory="GEOLOCATION"
          title="Multi-Destination Switcher"
          subtitle="Instant global city switching with auto GPS & local caching."
          features={['GPS Auto-Fetch', 'Saved Favorites', 'Offline Cache']}
          mockUiRenderer={() => (
            <div className="flex flex-col gap-2 h-full text-left p-2">
              <div className="rounded-lg bg-white/[0.05] p-2 border border-white/[0.08] text-[10px] text-obsidian-400">
                Search destination or airport...
              </div>
              <div className="flex flex-col gap-1.5">
                <div className="p-2 rounded-xl bg-white/[0.06] border border-white/15 flex items-center justify-between">
                  <div>
                    <div className="text-xs font-semibold text-white flex items-center gap-1">
                      <MapPin size={10} className="text-emerald-400" /> New Delhi
                    </div>
                    <div className="text-[10px] text-obsidian-400">Current Location</div>
                  </div>
                  <div className="text-sm font-semibold text-white">28°</div>
                </div>
                <div className="p-2 rounded-xl bg-white/[0.02] border border-white/[0.06] flex items-center justify-between">
                  <div>
                    <div className="text-xs font-medium text-obsidian-200">Mumbai</div>
                    <div className="text-[10px] text-obsidian-500">Humid • Rain 20%</div>
                  </div>
                  <div className="text-sm font-medium text-obsidian-300">31°</div>
                </div>
              </div>
            </div>
          )}
        />

        {/* 6. profile.png */}
        <ScreenshotCard
          filename="profile.png"
          screenCategory="SETTINGS"
          title="Persona & Sensitivities"
          subtitle="Switch between 7 archetypes and configure sensitivity triggers."
          features={['7 Persona Profiles', 'Sensitivity Sliders', 'Custom Units']}
          mockUiRenderer={() => (
            <div className="flex flex-col gap-2 h-full text-left p-2 justify-between">
              <div>
                <div className="text-[10px] font-semibold text-obsidian-400 uppercase tracking-wider mb-1.5">
                  Select Routine Persona
                </div>
                <div className="grid grid-cols-2 gap-1.5">
                  <div className="p-1.5 rounded-lg bg-white/10 border border-white/20 text-[10px] text-white font-medium flex items-center gap-1">
                    <Activity size={10} /> Fitness (Active)
                  </div>
                  <div className="p-1.5 rounded-lg bg-white/[0.03] border border-white/[0.06] text-[10px] text-obsidian-400 flex items-center gap-1">
                    <Heart size={10} /> Health Focus
                  </div>
                </div>
              </div>

              <div className="pt-2 border-t border-white/[0.06]">
                <div className="text-[10px] font-semibold text-obsidian-400 mb-1">Weather Triggers</div>
                <div className="flex flex-wrap gap-1 text-[9px] text-obsidian-300">
                  <span className="px-1.5 py-0.5 rounded bg-white/[0.04] border border-white/10">Dust High</span>
                  <span className="px-1.5 py-0.5 rounded bg-white/[0.04] border border-white/10">AQI &gt; 100</span>
                  <span className="px-1.5 py-0.5 rounded bg-white/[0.04] border border-white/10">Heat &gt; 33°</span>
                </div>
              </div>
            </div>
          )}
        />
      </div>
    </section>
  );
};
