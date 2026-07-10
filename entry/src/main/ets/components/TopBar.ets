import router from '@ohos.router';
import { Colors } from '../common/Constants';

@Component
export struct TopBar {
  onProfileClick?: () => void;

  build() {
    Row() {
      Text('物理沙盒').fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY)
        .shadow({ radius: 4, color: 'rgba(79,110,247,0.15)', offsetY: 1 })

      Blank()

      Button() { Text('👤').fontSize(18) }
      .width(36).height(36).borderRadius(18)
      .backgroundColor('rgba(79,110,247,0.08)')
      .onClick(() => {
        if (this.onProfileClick) {
          this.onProfileClick();
        } else {
          const isLoggedIn: boolean = AppStorage.get<boolean>('isLoggedIn') ?? false;
          if (isLoggedIn) { router.pushUrl({ url: 'pages/Profile' }); }
          else { router.pushUrl({ url: 'pages/Login' }); }
        }
      })
    }
    .width('100%').height(44).padding({ left: 16, right: 12 })
    .backgroundBlurStyle(BlurStyle.Regular)
    .backgroundColor('rgba(255,255,255,0.72)')
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.04)', offsetY: 1 })
    .border({ width: { bottom: 0.5 }, color: 'rgba(0,0,0,0.05)' })
  }
}
