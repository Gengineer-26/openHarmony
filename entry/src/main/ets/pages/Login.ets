import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { getUserByUsername } from '../utils/DatabaseUtil';
import { SessionUtil } from '../utils/SessionUtil';
import { Colors, Texts } from '../common/Constants';

@Entry
@Component
struct Login {
  @StorageLink('appContext') context: common.Context = {} as common.Context;
  @State username: string = '';
  @State password: string = '';
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  aboutToAppear(): void {
    AppStorage.setOrCreate('isLoggedIn', false);
    AppStorage.setOrCreate('currentUserId', 0);
  }

  async handleLogin(): Promise<void> {
    this.errorMessage = '';
    if (this.username.trim() === '') { this.errorMessage = '请输入用户名'; return; }
    if (this.password.trim() === '') { this.errorMessage = '请输入密码'; return; }
    this.isLoading = true;
    try {
      const userRecord = await getUserByUsername(this.context, this.username);
      if (userRecord !== null && userRecord.password === this.password) {
        AppStorage.setOrCreate('isLoggedIn', true);
        AppStorage.setOrCreate('currentUserId', userRecord.id);
        AppStorage.setOrCreate('currentNickname', userRecord.nickname);
        AppStorage.setOrCreate('currentUsername', userRecord.username);
        AppStorage.setOrCreate('currentAvatar', userRecord.avatar_path);
        SessionUtil.setLoginState(this.context, userRecord.id, userRecord.username, userRecord.nickname);
        router.replaceUrl({ url: 'pages/Index' });
        this.isLoading = false;
        return;
      }
      this.errorMessage = Texts.ERR_LOGIN_FAILED;
    } catch (e) { this.errorMessage = Texts.ERR_LOGIN_FAILED; }
    finally { this.isLoading = false; }
  }

  build() {
    Column() {
      // 顶部装饰渐变
      Column().width('100%').height(180)
        .linearGradient({ direction: GradientDirection.Bottom, colors: [['#667eea', 0.0], ['rgba(102,126,234,0)', 1.0]] })
        .borderRadius({ bottomLeft: 40, bottomRight: 40 })

      // 标题
      Column({ space: 4 }) {
        Text(Texts.APP_NAME).fontSize(32).fontWeight(FontWeight.Bold).fontColor(Color.White)
        Text(Texts.LOGIN_WELCOME).fontSize(14).fontColor('rgba(255,255,255,0.85)')
      }.alignItems(HorizontalAlign.Center).margin({ top: -120, bottom: 40 })

      // 卡片
      Column({ space: 14 }) {
        TextInput({ placeholder: Texts.LABEL_USERNAME, text: this.username })
          .fontSize(15).height(50).width('100%').borderRadius(14)
          .backgroundColor(Colors.CANVAS_BG).padding({ left: 16, right: 16 })
          .border({ width: 1, color: Colors.BORDER })
          .onChange((v: string) => { this.username = v; this.errorMessage = ''; })

        TextInput({ placeholder: Texts.LABEL_PASSWORD, text: this.password })
          .type(InputType.Password).fontSize(15).height(50).width('100%').borderRadius(14)
          .backgroundColor(Colors.CANVAS_BG).padding({ left: 16, right: 16 })
          .border({ width: 1, color: Colors.BORDER })
          .onChange((v: string) => { this.password = v; this.errorMessage = ''; })
          .onSubmit(() => { this.handleLogin(); })

        if (this.errorMessage !== '') {
          Text(this.errorMessage).fontSize(13).fontColor(Colors.RESET).padding({ top: 4, bottom: 2 })
        }

        Button(this.isLoading ? '登录中...' : Texts.BTN_LOGIN)
          .width('100%').height(52).fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor(Color.White).borderRadius(26)
          .linearGradient({ direction: GradientDirection.Right, colors: [['#667eea', 0.0], ['#764ba2', 1.0]] })
          .enabled(!this.isLoading)
          .shadow({ radius: 12, color: 'rgba(102,126,234,0.35)', offsetY: 4 })
          .onClick(() => { this.handleLogin(); })

        Text(Texts.LINK_TO_REGISTER).fontSize(14).fontColor(Colors.PRIMARY)
          .onClick(() => { router.pushUrl({ url: 'pages/Register' }); })
      }
      .width('85%').padding(28)
      .backgroundColor(Colors.SURFACE).borderRadius(24)
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.06)', offsetY: 6 })

      Blank()
    }
    .width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }
}
