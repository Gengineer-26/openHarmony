import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('EntryAbility onCreate');
    AppStorage.setOrCreate('appContext', this.context);

    // 检查是否通过 Deep Link / 流转方式启动
    this.checkIncomingSceneData(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('EntryAbility onNewWant');
    this.checkIncomingSceneData(want);
  }

  // ====== 解析 Deep Link / Want 参数中的场景数据 ======
  private checkIncomingSceneData(want: Want): void {
    try {
      const params: Record<string, Object> | undefined = want.parameters as Record<string, Object> | undefined;
      const uri: string = (want.uri as string) || '';

      // 方式1：physsandbox://import?ts=<timestamp> Deep Link
      if (uri !== '' && uri.startsWith('physsandbox://import')) {
        const ts: string = this.getUriParam(uri, 'ts');
        if (ts !== '') {
          AppStorage.setOrCreate('pendingSceneTs', ts);
          return;
        }
      }

      // 方式2：跨设备流转传来的场景 JSON
      if (params !== undefined) {
        const sceneJson: string = (params['sceneData'] as string) || '';
        if (sceneJson !== '') {
          AppStorage.setOrCreate('pendingSceneImport', sceneJson);
          return;
        }
      }

      // 方式3：系统分享传来的文本（备用）
      if (params !== undefined) {
        const sharedText: string = (params['ability.params.stream'] as string) || '';
        if (sharedText !== '' && sharedText.includes('"bodies"') && sharedText.includes('"joints"')) {
          AppStorage.setOrCreate('pendingSceneImport', sharedText);
        }
      }
    } catch (e) {
      console.error('checkIncomingSceneData error: ' + JSON.stringify(e));
    }
  }

  // 从 URI 中提取参数值
  private getUriParam(uri: string, key: string): string {
    try {
      const search: string = uri.includes('?') ? uri.split('?')[1] : '';
      if (search === '') return '';
      const parts: string[] = search.split('&');
      for (const part of parts) {
        const pair: string[] = part.split('=');
        if (pair.length >= 2 && pair[0] === key) {
          return decodeURI(pair[1]);
        }
      }
    } catch (_e) {
      // ignore
    }
    return '';
  }

  onDestroy(): void {
    console.info('EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 支持横竖屏自动旋转
    windowStage.getMainWindow().then((win: window.Window) => {
      win.setPreferredOrientation(window.Orientation.AUTO_ROTATION);
    });
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      console.info('Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy(): void {
    console.info('EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('EntryAbility onForeground');
  }

  onBackground(): void {
    console.info('EntryAbility onBackground');
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    // 流转时保存场景数据到 Want 参数中
    const sceneJson: string = AppStorage.get<string>('shareSceneData') ?? '';
    if (sceneJson !== '') {
      wantParam['sceneData'] = sceneJson;
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }
}
