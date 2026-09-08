export interface AppConfig {
  APP_NAME: string;
  TAGLINE: string;
  SUBTITLE: string;
  APK_URL: string;
  GITHUB_URL: string;
  DOCS_URL: string;
  RELEASES_URL: string;
  REPO_AUTHOR: string;
  VERSION: string;
}

export const CONFIG: AppConfig = {
  APP_NAME: "Mausam PersonalAI",
  TAGLINE: "Your weather, personalized for how you live",
  SUBTITLE: "Next-generation meteorological intelligence and adaptive context engine. Grounded in real-time sensor data, localized AQI, and deep persona routines.",
  APK_URL: "/mausam-release.apk",
  GITHUB_URL: "https://github.com/TukitoZenx/mausam-personalai",
  DOCS_URL: "https://github.com/TukitoZenx/mausam-personalai#readme",
  RELEASES_URL: "https://github.com/TukitoZenx/mausam-personalai/releases",
  REPO_AUTHOR: "TukitoZenx",
  VERSION: "1.0.0",
};
