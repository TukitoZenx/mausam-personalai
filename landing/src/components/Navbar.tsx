import React, { useState, useEffect } from 'react';
import { CONFIG } from '../config';
import { MausamLogo } from './ui/MausamLogo';
import { Github, Download, Menu, X, ArrowUpRight } from 'lucide-react';

export const Navbar: React.FC = () => {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { label: 'Personas', href: '#personas' },
    { label: 'Intelligence', href: '#features' },
    { label: 'Workflow', href: '#how-it-works' },
    { label: 'Screenshots', href: '#screenshots' },
    { label: 'Architecture', href: '#architecture' },
  ];

  const hasApk = Boolean(CONFIG.APK_URL && CONFIG.APK_URL.trim().length > 0);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 flex justify-center px-4 py-4 md:py-6 transition-all duration-300">
      <nav
        aria-label="Primary Navigation"
        className={`w-full max-w-6xl flex items-center justify-between px-5 py-3 rounded-[20px] transition-all duration-300 ${
          scrolled
            ? 'bg-obsidian-950/80 backdrop-blur-2xl border border-white/[0.08] shadow-[0_12px_32px_rgba(0,0,0,0.6)]'
            : 'bg-white/[0.03] backdrop-blur-xl border border-white/[0.05]'
        }`}
      >
        {/* Brand */}
        <a
          href="#"
          className="flex items-center gap-3 group focus-visible:ring-2 focus-visible:ring-white/50 rounded-xl p-1"
          aria-label="Mausam PersonalAI Home"
        >
          <div className="w-8 h-8 rounded-lg bg-white/[0.08] border border-white/[0.12] flex items-center justify-center text-white group-hover:border-white/25 transition-colors">
            <MausamLogo size={18} />
          </div>
          <div className="flex flex-col text-left">
            <span className="font-sans font-semibold text-sm tracking-tight text-obsidian-100 flex items-center gap-1.5">
              Mausam <span className="text-obsidian-400 font-normal text-xs uppercase tracking-wider">PersonalAI</span>
            </span>
          </div>
        </a>

        {/* Desktop Links */}
        <div className="hidden md:flex items-center gap-7">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-xs tracking-wide uppercase font-medium text-obsidian-300 hover:text-white transition-colors duration-200 focus-visible:ring-2 focus-visible:ring-white/50 rounded-md py-1 px-1.5"
            >
              {link.label}
            </a>
          ))}
        </div>

        {/* Desktop CTA actions */}
        <div className="hidden md:flex items-center gap-3">
          <a
            href={CONFIG.GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 text-xs text-obsidian-300 hover:text-white px-3 py-2 rounded-xl border border-white/[0.08] hover:border-white/20 bg-white/[0.02] hover:bg-white/[0.05] transition-all duration-200"
            aria-label="View source code on GitHub"
          >
            <Github size={14} />
            <span>GitHub</span>
            <ArrowUpRight size={12} className="opacity-60" />
          </a>

          {hasApk ? (
            <a
              href={CONFIG.APK_URL}
              download="mausam-release.apk"
              className="flex items-center gap-1.5 text-xs font-semibold text-obsidian-950 bg-white hover:bg-obsidian-200 px-3.5 py-2 rounded-xl transition-all shadow-[0_2px_10px_rgba(255,255,255,0.15)]"
            >
              <Download size={14} />
              <span>Download APK (60.6 MB)</span>
            </a>
          ) : (
            <div
              className="relative group flex items-center gap-1.5 text-xs font-medium text-obsidian-400 bg-white/[0.04] border border-white/[0.08] px-3.5 py-2 rounded-xl cursor-not-allowed"
              title="Release build in progress"
            >
              <Download size={14} className="opacity-40" />
              <span>APK Coming Soon</span>
              <span className="hidden group-hover:block absolute top-full mt-2 left-1/2 -translate-x-1/2 whitespace-nowrap bg-obsidian-900 border border-white/10 text-[11px] text-obsidian-300 px-2.5 py-1 rounded-lg shadow-xl pointer-events-none">
                Clone repo & run with Flutter
              </span>
            </div>
          )}
        </div>

        {/* Mobile menu button */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="md:hidden text-obsidian-300 hover:text-white p-2 rounded-lg focus-visible:ring-2 focus-visible:ring-white/50"
          aria-label={mobileMenuOpen ? 'Close Menu' : 'Open Menu'}
          aria-expanded={mobileMenuOpen}
        >
          {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
      </nav>

      {/* Mobile Menu Dropdown */}
      {mobileMenuOpen && (
        <div className="md:hidden absolute top-full left-4 right-4 mt-2 p-5 rounded-2xl bg-obsidian-900/95 backdrop-blur-2xl border border-white/[0.1] shadow-2xl flex flex-col gap-4">
          <div className="flex flex-col gap-3">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className="text-sm font-medium text-obsidian-200 hover:text-white py-1.5 border-b border-white/[0.05]"
              >
                {link.label}
              </a>
            ))}
          </div>

          <div className="flex flex-col gap-2 pt-2">
            <a
              href={CONFIG.GITHUB_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center gap-2 text-xs font-medium text-obsidian-200 py-2.5 rounded-xl border border-white/[0.1] bg-white/[0.03]"
            >
              <Github size={14} />
              <span>View on GitHub</span>
            </a>

            {hasApk ? (
              <a
                href={CONFIG.APK_URL}
                download="mausam-release.apk"
                className="flex items-center justify-center gap-2 text-xs font-semibold text-obsidian-950 bg-white py-2.5 rounded-xl"
              >
                <Download size={14} />
                <span>Download Android APK (60.6 MB)</span>
              </a>
            ) : (
              <div className="flex items-center justify-center gap-2 text-xs font-medium text-obsidian-400 bg-white/[0.04] border border-white/[0.06] py-2.5 rounded-xl cursor-not-allowed">
                <Download size={14} className="opacity-40" />
                <span>Android APK Coming Soon</span>
              </div>
            )}
          </div>
        </div>
      )}
    </header>
  );
};
