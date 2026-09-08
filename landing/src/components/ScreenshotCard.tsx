import React, { useState } from 'react';
import { GlassCard } from './ui/GlassCard';
import { Image as ImageIcon } from 'lucide-react';

export interface ScreenshotCardProps {
  filename: string;
  title: string;
  subtitle: string;
  screenCategory: string;
  features: string[];
  mockUiRenderer: () => React.ReactNode;
}

export const ScreenshotCard: React.FC<ScreenshotCardProps> = ({
  filename,
  title,
  subtitle,
  screenCategory,
  features,
  mockUiRenderer,
}) => {
  const [imageValid, setImageValid] = useState(false);

  // Check if image is a real user screenshot (larger than 1x1 placeholder)
  const handleImageLoad = (e: React.SyntheticEvent<HTMLImageElement>) => {
    const img = e.currentTarget;
    if (img.naturalWidth > 10 && img.naturalHeight > 10) {
      setImageValid(true);
    }
  };

  return (
    <GlassCard hoverEffect className="p-6 flex flex-col justify-between border-white/[0.09] bg-obsidian-900/90 group">
      <div>
        {/* Card Header */}
        <div className="flex items-center justify-between mb-4">
          <span className="text-[11px] font-mono uppercase tracking-wider text-obsidian-400 bg-white/[0.04] px-2.5 py-1 rounded-md border border-white/[0.06]">
            {screenCategory}
          </span>
          <span className="text-[11px] text-obsidian-500 font-mono">
            public/screenshots/{filename}
          </span>
        </div>

        <h3 className="text-base font-semibold text-white mb-1 tracking-tight">
          {title}
        </h3>
        <p className="text-xs text-obsidian-300 font-light mb-4">
          {subtitle}
        </p>

        {/* Device Screen Mockup Container */}
        <div className="w-full h-80 rounded-2xl bg-black border border-white/[0.12] overflow-hidden relative shadow-inner flex flex-col my-3">
          {/* Phone Status Bar */}
          <div className="h-6 w-full bg-obsidian-950/80 px-4 flex items-center justify-between text-[10px] text-obsidian-400 border-b border-white/[0.05] z-10 shrink-0">
            <span>09:41</span>
            <div className="w-16 h-3 rounded-full bg-black/80 border border-white/10" />
            <span className="flex items-center gap-1">5G 100%</span>
          </div>

          {/* Real screenshot or Fallback SVG UI representation */}
          <div className="relative flex-1 overflow-hidden bg-obsidian-950 flex flex-col justify-between p-3">
            {/* Hidden image element to detect if real PNG is provided */}
            <img
              src={`/screenshots/${filename}`}
              alt={title}
              onLoad={handleImageLoad}
              onError={() => setImageValid(false)}
              className={
                imageValid
                  ? 'absolute inset-0 w-full h-full object-cover z-20'
                  : 'hidden'
              }
            />

            {/* Fallback Obsidian UI Component */}
            {!imageValid && mockUiRenderer()}
          </div>

          {/* Screenshot replacement banner */}
          <div className="absolute bottom-2 right-2 z-30 opacity-0 group-hover:opacity-100 transition-opacity">
            <span className="text-[10px] font-mono bg-obsidian-950/90 text-obsidian-300 px-2 py-1 rounded-md border border-white/20 shadow-lg flex items-center gap-1">
              <ImageIcon size={10} /> Drop {filename} to replace
            </span>
          </div>
        </div>
      </div>

      {/* Feature Pills */}
      <div className="mt-4 pt-3 border-t border-white/[0.06] flex flex-wrap gap-1.5">
        {features.map((feat) => (
          <span
            key={feat}
            className="text-[10px] font-medium text-obsidian-300 bg-white/[0.03] px-2 py-0.5 rounded border border-white/[0.05]"
          >
            {feat}
          </span>
        ))}
      </div>
    </GlassCard>
  );
};
