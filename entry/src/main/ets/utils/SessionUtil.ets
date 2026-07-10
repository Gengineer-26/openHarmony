import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'UserSession';

// 登录状态数据结构
interface LoginState {
  isLoggedIn: boolean;
  userId: number;
  username: string;
  nickname: string;
}

export class SessionUtil {
  // 保存登录状态到本地持久化存储
  static async setLoginState(context: common.Context, userId: number, username: string, nickname: string): Promise<void> {
    const prefs: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
    await prefs.put('isLoggedIn', true);
    await prefs.put('userId', userId);
    await prefs.put('username', username);
    await prefs.put('nickname', nickname);
    await prefs.flush();
  }

  // 读取持久化的登录状态
  static async getLoginState(context: common.Context): Promise<LoginState> {
    try {
      const prefs: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
      const isLoggedIn: boolean = await prefs.get('isLoggedIn', false) as boolean;
      const userId: number = await prefs.get('userId', 0) as number;
      const username: string = await prefs.get('username', '') as string;
      const nickname: string = await prefs.get('nickname', '') as string;
      const state: LoginState = { isLoggedIn: isLoggedIn, userId: userId, username: username, nickname: nickname };
      return state;
    } catch (_e) {
      const empty: LoginState = { isLoggedIn: false, userId: 0, username: '', nickname: '' };
      return empty;
    }
  }

  // 清除登录状态（退出登录）
  static async clearLoginState(context: common.Context): Promise<void> {
    try {
      const prefs: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
      await prefs.delete('isLoggedIn');
      await prefs.delete('userId');
      await prefs.delete('username');
      await prefs.delete('nickname');
      await prefs.flush();
    } catch (_e) {
      // ignore
    }
  }
}
