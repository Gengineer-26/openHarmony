export class AnimationDurations {
  static readonly FAST: number = 180;
  static readonly NORMAL: number = 280;
  static readonly SLOW: number = 450;
}

// 沉浸光感阴影预设
export class ShadowPresets {
  static readonly CARD: ShadowParam = { radius: 12, color: 'rgba(79,110,247,0.08)', offsetY: 3 };
  static readonly CARD_HOVER: ShadowParam = { radius: 18, color: 'rgba(79,110,247,0.14)', offsetY: 5 };
  static readonly PANEL: ShadowParam = { radius: 20, color: 'rgba(0,0,0,0.08)', offsetX: -2, offsetY: 2 };
  static readonly DIALOG: ShadowParam = { radius: 32, color: 'rgba(0,0,0,0.18)', offsetY: 8 };
  static readonly BUTTON: ShadowParam = { radius: 8, color: 'rgba(79,110,247,0.25)', offsetY: 3 };
  static readonly BUTTON_PLAY: ShadowParam = { radius: 8, color: 'rgba(34,197,94,0.3)', offsetY: 3 };
  static readonly BUTTON_DANGER: ShadowParam = { radius: 8, color: 'rgba(239,68,68,0.25)', offsetY: 3 };
  static readonly TAB_BAR: ShadowParam = { radius: 14, color: 'rgba(0,0,0,0.06)', offsetY: -3 };
}

interface ShadowParam {
  radius: number;
  color: string;
  offsetX?: number;
  offsetY?: number;
}

// 渐变色预设
export class GradientPresets {
  static readonly APP_BG: [string, number][] = [['#EEF0F6', 0.0], ['#E3E8F0', 1.0]];
  static readonly CANVAS_BG: [string, number][] = [['#EDEFF5', 0.0], ['#E4E7EF', 1.0]];
  static readonly TAB_BAR: [string, number][] = [['rgba(255,255,255,0.92)', 0.0], ['rgba(248,249,252,0.95)', 1.0]];
  static readonly AUTH: [string, number][] = [['#667eea', 0.0], ['#764ba2', 1.0]];
  static readonly PRIMARY: [string, number][] = [['#4F6EF7', 0.0], ['#6C5CE7', 1.0]];
  static readonly ACCENT: [string, number][] = [['#00B8A9', 0.0], ['#009688', 1.0]];
}
