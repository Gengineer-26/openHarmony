import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { registerUser, checkUsernameExists } from '../utils/DatabaseUtil';
import { validateUsername, validatePassword, validateNickname } from '../utils/AuthUtil';
import { Colors, Texts } from '../common/Constants';

@Entry
@Component
struct Register {
  @StorageLink('appContext') context: common.Context = {} as common.Context;
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  validateAll(): string {
    const userErr: string = validateUsername(this.username);
    if (userErr !== '') return userErr;
    const passErr: string = validatePassword(this.password);
    if (passErr !== '') return passErr;
    if (this.password !== this.confirmPassword) return Texts.ERR_PASSWORD_MISMATCH;
    const nickErr: string = validateNickname(this.nickname);
    if (nickErr !== '') return nickErr;
    return '';
  }

  async handleRegister(): Promise<void> {
    this.errorMessage = '';
    const validationError: string = this.validateAll();
    if (validationError !== '') { this.errorMessage = validationError; return; }
    this.isLoading = true;
    try {
      const exists: boolean = await checkUsernameExists(this.context, this.username);
      if (exists) { this.errorMessage = Texts.ERR_USERNAME_EXISTS; this.isLoading = false; return; }
      const rowId: number = await registerUser(this.context, this.username, this.password, this.nickname);
      if (rowId > -1) {
        promptAction.openToast({ message: Texts.SUCCESS_REGISTER, duration: 2000 });
        router.back();
      } else { this.errorMessage = '注册失败 (rowId=' + rowId.toString() + ')'; }
    } catch (e) { this.errorMessage = '未知错误: ' + JSON.stringify(e); }
    finally { this.isLoading = false; }
  }

  build() {
    Column() {
      Column().width('100%').height(140)
        .linearGradient({ direction: GradientDirection.Bottom, colors: [['#667eea', 0.0], ['rgba(102,126,234,0)', 1.0]] })
        .borderRadius({ bottomLeft: 40, bottomRight: 40 })

      Column({ space: 2 }) {
        Text(Texts.REGISTER_TITLE).fontSize(28).fontWeight(FontWeight.Bold).fontColor(Color.White)
        Text(Texts.REGISTER_SUBTITLE).fontSize(13).fontColor('rgba(255,255,255,0.85)')
      }.alignItems(HorizontalAlign.Center).margin({ top: -90, bottom: 30 })

      Column({ space: 10 }) {
        TextInput({ placeholder: Texts.LABEL_USERNAME }).fontSize(14).height(46).width('100%')
          .borderRadius(12).backgroundColor(Colors.CANVAS_BG).padding({ left: 14, right: 14 })
          .border({ width: 1, color: Colors.BORDER })
          .onChange((v: string) => { this.username = v; this.errorMessage = ''; })
        TextInput({ placeholder: Texts.LABEL_PASSWORD }).type(InputType.Password).fontSize(14).height(46).width('100%')
          .borderRadius(12).backgroundColor(Colors.CANVAS_BG).padding({ left: 14, right: 14 })
          .border({ width: 1, color: Colors.BORDER })
          .onChange((v: string) => { this.password = v; this.errorMessage = ''; })
        TextInput({ placeholder: Texts.LABEL_CONFIRM_PWD }).type(InputType.Password).fontSize(14).height(46).width('100%')
          .borderRadius(12).backgroundColor(Colors.CANVAS_BG).padding({ left: 14, right: 14 })
          .border({ width: 1, color: Colors.BORDER })
          .onChange((v: string) => { this.confirmPassword = v; this.errorMessage = ''; })
        TextInput({ placeholder: Texts.LABEL_NICKNAME }).fontSize(14).height(46).width('100%')
          .borderRadius(12).backgroundColor(Colors.CANVAS_BG).padding({ left: 14, right: 14 })
          .border({ width: 1, color: Colors.BORDER })
          .onChange((v: string) => { this.nickname = v; this.errorMessage = ''; })

        if (this.errorMessage !== '') {
          Text(this.errorMessage).fontSize(13).fontColor(Colors.RESET).padding({ top: 4 })
        }

        Button(this.isLoading ? '注册中...' : Texts.BTN_REGISTER)
          .width('100%').height(50).fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor(Color.White).borderRadius(25)
          .linearGradient({ direction: GradientDirection.Right, colors: [['#667eea', 0.0], ['#764ba2', 1.0]] })
          .enabled(!this.isLoading)
          .shadow({ radius: 12, color: 'rgba(102,126,234,0.35)', offsetY: 4 })
          .onClick(() => { this.handleRegister(); })

        Text(Texts.LINK_TO_LOGIN).fontSize(14).fontColor(Colors.PRIMARY)
          .onClick(() => { router.back(); })
      }
      .width('85%').padding(26)
      .backgroundColor(Colors.SURFACE).borderRadius(24)
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.06)', offsetY: 6 })

      Blank()
    }
    .width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }
}
