import React from 'react';
import { CONFIG } from '../config';
import { GlassCard } from './ui/GlassCard';
import { MausamLogo } from './ui/MausamLogo';
import { Download, Github, ArrowUpRight } from 'lucide-react';

export const FinalCTA: React.FC = () => {
  const hasApk = Boolean(CONFIG.APK_URL && CONFIG.APK_URL.trim().length > 0);

  return (
    <section className="py-24 px-4 max-w-6xl mx-auto relative z-10">
      <GlassCard className="p-8 md:p-16 text-center relative overflow-hidden border-white/[0.12]" glow="blue">
        <div className="max-w-2xl mx-auto flex flex-col items-center">
          {/* Logo badge */}
          <div className="w-14 h-14 rounded-2xl bg-white/[0.08] border border-white/[0.14] flex items-center justify-center text-white mb-6 shadow-2xl">
            <MausamLogo size={28} />
          </div>

          <h2 className="text-3xl sm:text-5xl font-normal tracking-tight text-white mb-4 leading-tight">
            Ready for a weather app that{' '}
            <span className="font-serif italic text-obsidian-200">adapts to you</span>?
          </h2>

          <p className="text-obsidian-300 text-sm sm:text-base font-light mb-8 max-w-lg leading-relaxed">
            Experience obsidian aesthetics, hyper-personalized activity windows, and real-time environmental context.
          </p>

          <div className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto">
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
                  className="w-full sm:w-auto flex items-center justify-center gap-2 text-sm font-medium text-obsidian-400 bg-white/[0.05] border border-white/[0.1] px-7 py-3.5 rounded-2xl cursor-not-allowed"
                >
                  <Download size={16} className="opacity-40" />
                  <span>APK Coming Soon</span>
                </button>
                <div className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 hidden group-hover:block w-64 bg-obsidian-900 border border-white/10 text-xs text-obsidian-300 p-2 rounded-xl shadow-2xl text-center pointer-events-none">
                  Set APK_URL in <code className="text-white font-mono">src/config.ts</code>
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
              <span>Clone & Run Locally</span>
              <ArrowUpRight size={14} className="opacity-60" />
            </a>
          </div>

          <div className="mt-8 text-xs text-obsidian-400 font-mono">
            Requires Flutter 3.22+ SDK & Python 3.11+ Backend
          </div>
        </div>
      </GlassCard>
    </section>
  );
};
