import React from 'react';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { WhatIsMausam } from './components/WhatIsMausam';
import { CoreFeatures } from './components/CoreFeatures';
import { HowItWorks } from './components/HowItWorks';
import { ScreenshotGallery } from './components/ScreenshotGallery';
import { ArchitectureGrid } from './components/ArchitectureGrid';
import { FinalCTA } from './components/FinalCTA';
import { Footer } from './components/Footer';

export const App: React.FC = () => {
  return (
    <div className="relative min-h-screen bg-obsidian-950 text-obsidian-100 font-sans selection:bg-white/20 selection:text-white">
      {/* Subtle atmospheric gradient mesh */}
      <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
        <div className="absolute -top-[200px] left-1/2 -translate-x-1/2 w-[1000px] h-[700px] bg-gradient-to-b from-sky-500/5 via-amber-500/5 to-transparent blur-[120px] rounded-full" />
        <div className="absolute top-[35%] -left-[300px] w-[600px] h-[600px] bg-amber-500/[0.03] blur-[140px] rounded-full" />
        <div className="absolute top-[65%] -right-[300px] w-[600px] h-[600px] bg-sky-500/[0.03] blur-[140px] rounded-full" />
      </div>

      {/* Navigation */}
      <Navbar />

      {/* Main Content */}
      <main id="main-content" className="relative z-10">
        <Hero />
        <WhatIsMausam />
        <CoreFeatures />
        <HowItWorks />
        <ScreenshotGallery />
        <ArchitectureGrid />
        <FinalCTA />
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
};

export default App;
