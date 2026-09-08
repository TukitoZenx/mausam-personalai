import React from 'react';

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
  hoverEffect?: boolean;
  glow?: 'none' | 'amber' | 'blue';
}

export const GlassCard: React.FC<GlassCardProps> = ({
  children,
  className = '',
  hoverEffect = false,
  glow = 'none',
}) => {
  return (
    <div
      className={`relative rounded-[24px] bg-white/[0.04] backdrop-blur-[24px] border border-white/[0.08] shadow-[0_8px_32px_rgba(0,0,0,0.5)] overflow-hidden ${
        hoverEffect ? 'glass-card-hover' : ''
      } ${className}`}
    >
      {glow === 'amber' && (
        <div className="pointer-events-none absolute -top-24 -right-24 h-56 w-56 rounded-full bg-amber-500/10 blur-3xl" />
      )}
      {glow === 'blue' && (
        <div className="pointer-events-none absolute -top-24 -right-24 h-56 w-56 rounded-full bg-sky-500/10 blur-3xl" />
      )}
      {children}
    </div>
  );
};
