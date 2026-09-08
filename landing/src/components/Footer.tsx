import React from 'react';
import { CONFIG } from '../config';
import { MausamLogo } from './ui/MausamLogo';
import { Github, ArrowUpRight } from 'lucide-react';

export const Footer: React.FC = () => {
  return (
    <footer className="border-t border-white/[0.08] bg-obsidian-950/80 backdrop-blur-xl py-12 px-4 relative z-10">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-white/[0.06] border border-white/[0.1] flex items-center justify-center text-white">
            <MausamLogo size={18} />
          </div>
          <div className="text-left">
            <div className="text-xs font-semibold text-white tracking-wide">
              {CONFIG.APP_NAME}
            </div>
            <div className="text-[11px] text-obsidian-400">
              {CONFIG.TAGLINE}
            </div>
          </div>
        </div>

        {/* Links */}
        <div className="flex flex-wrap items-center justify-center gap-6 text-xs text-obsidian-300">
          <a href="#personas" className="hover:text-white transition-colors">
            Personas
          </a>
          <a href="#features" className="hover:text-white transition-colors">
            Intelligence
          </a>
          <a href="#how-it-works" className="hover:text-white transition-colors">
            Workflow
          </a>
          <a href="#screenshots" className="hover:text-white transition-colors">
            Screenshots
          </a>
          <a href="#architecture" className="hover:text-white transition-colors">
            Architecture
          </a>
          <a
            href={CONFIG.GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 hover:text-white transition-colors"
          >
            <Github size={13} />
            <span>GitHub</span>
            <ArrowUpRight size={11} className="opacity-60" />
          </a>
        </div>

        {/* Copyright */}
        <div className="text-xs text-obsidian-500 font-mono text-center md:text-right">
          MIT Licensed • Built for live atmospheric routines
        </div>
      </div>
    </footer>
  );
};
