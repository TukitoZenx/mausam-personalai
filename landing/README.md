# ⛅ Mausam PersonalAI — Product Launch Website

A premium, obsidian-themed product landing website engineered with **React**, **Vite**, **TypeScript**, and **Tailwind CSS**. Designed with an editorial weather-tech aesthetic (inspired by Linear & Apple Weather), glassmorphism cards, Instrument Serif + Inter typography, and authentic features extracted from the Mausam PersonalAI codebase.

---

## 🚀 Quick Start

### 1. Installation
```bash
cd landing
npm install
```

### 2. Run Local Development Server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

### 3. Production Build & Verification
```bash
npm run build
npm run preview
```

---

## ⚙️ Configuration

All external links, release artifacts, and repo metadata are controlled centrally in [`src/config.ts`](src/config.ts):

```typescript
export const CONFIG = {
  APP_NAME: "Mausam PersonalAI",
  TAGLINE: "Your weather, personalized for how you live",
  APK_URL: "", // Paste direct APK release download link here
  GITHUB_URL: "https://github.com/TukitoZenx/mausam-personalai",
  ...
};
```

- **Empty `APK_URL`**: Download buttons are automatically disabled with a sleek badge reading `"APK Coming Soon"` and a tooltip pointing to GitHub releases.
- **Populated `APK_URL`**: Buttons instantly become active direct download links.

---

## 📱 Adding Real Screenshots

Drop your high-resolution device PNGs directly into `public/screenshots/`:

| Filename | Expected Screenshot |
| :--- | :--- |
| `hero.png` | Main Dashboard with atmospheric gradient & hero temperature |
| `home.png` | Home screen with 7-day forecast & active persona card |
| `insights.png` | Insights screen with Golden Hour progress slider & commute advisories |
| `weather-ai.png` | Mausam Weather AI natural language conversation |
| `locations.png` | Multi-destination switcher & saved cities |
| `profile.png` | Persona selection & environmental sensitivity sliders |

*The landing page includes built-in obsidian vector mockups that automatically yield to real images once dropped into `public/screenshots/`.*

---

## 🚢 Deployment

The build output in `landing/dist/` is a standard static bundle deployable to any modern host:

- **Vercel**: `cd landing && npx vercel`
- **Cloudflare Pages**: Set build output directory to `landing/dist` and build command to `npm run build`.
- **Netlify**: Set publish directory to `landing/dist`.
- **GitHub Pages**: Deploy contents of `landing/dist/`.
