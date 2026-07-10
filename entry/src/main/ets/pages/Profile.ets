import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { getUserById, updateNickname, updatePassword, UserRecord } from '../utils/DatabaseUtil';
import { SessionUtil } from '../utils/SessionUtil';
import { validateNickname, validatePassword } from '../utils/AuthUtil';
import { Colors, Texts } from '../common/Constants';
import { AnimationDurations } from '../common/Theme';

@Entry
@Component
struct Profile {
  @StorageLink('appContext') context: common.Context = {} as common.Context;
  @StorageLink('currentUserId') userId: number = 0;
  @StorageLink('currentUsername') username: string = '';
  @StorageLink('currentNickname') nickname: string = '';
  @StorageLink('currentAvatar') avatarPath: string = '';

  @State localNickname: string = '';
  @State userName: string = '';

  private nicknameDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: NicknameEditDialog({
      currentNickname: '',
      onConfirm: (newName: string) => { this.doUpdateNickname(newName); }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  private passwordDialogCtrl: CustomDialogController = new CustomDialogController({
    builder: PasswordEditDialog({
      onConfirm: (oldPwd: string, newPwd: string) => { this.doUpdatePassword(oldPwd, newPwd); }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.localNickname = this.nickname;
    this.userName = this.username;
    this.refreshUserData();
  }

  async refreshUserData(): Promise<void> {
    if (this.userId <= 0) return;
    try {
      const user: UserRecord | null = await getUserById(this.context, this.userId);
      if (user !== null) {
        this.localNickname = user.nickname;
        this.userName = user.username;
        AppStorage.setOrCreate('currentNickname', user.nickname);
      }
    } catch (e) { console.error('Refresh user data failed'); }
  }

  async doUpdateNickname(newName: string): Promise<void> {
    const err: string = validateNickname(newName);
    if (err !== '') { promptAction.openToast({ message: err, duration: 2000 }); return; }
    try {
      await updateNickname(this.context, this.userId, newName);
      this.localNickname = newName;
      AppStorage.setOrCreate('currentNickname', newName);
      promptAction.openToast({ message: Texts.SUCCESS_UPDATE, duration: 2000 });
    } catch (e) { promptAction.openToast({ message: '修改失败', duration: 2000 }); }
  }

  async doUpdatePassword(oldPwd: string, newPwd: string): Promise<void> {
    const err: string = validatePassword(newPwd);
    if (err !== '') { promptAction.openToast({ message: err, duration: 2000 }); return; }
    const ok: boolean = await updatePassword(this.context, this.userId, oldPwd, newPwd);
    if (ok) {
      promptAction.openToast({ message: '密码修改成功', duration: 2000 });
    } else {
      promptAction.openToast({ message: '旧密码错误', duration: 2000 });
    }
  }

  async doLogout(): Promise<void> {
    AppStorage.setOrCreate('isLoggedIn', false);
    AppStorage.setOrCreate('currentUserId', 0);
    AppStorage.setOrCreate('currentUsername', '');
    AppStorage.setOrCreate('currentNickname', '');
    AppStorage.setOrCreate('currentAvatar', '');
    await SessionUtil.clearLoginState(this.context);
    try { router.replaceUrl({ url: 'pages/Login' }); } catch (_e) { }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('← 返回').fontSize(14).height(36)
          .backgroundColor(Colors.BORDER).borderRadius(18)
          .onClick(() => { router.back(); })
        Text(Texts.PROFILE_TITLE).fontSize(20).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Row().width(60)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 头像
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image('https://picsum.photos/seed/user' + this.userId.toString() + '/200/200')
          .width(90).height(90).borderRadius(45).objectFit(ImageFit.Cover)
          .border({ width: 3, color: Colors.PROFILE_PRIMARY })
          .shadow({ radius: 14, color: 'rgba(102,126,234,0.35)', offsetY: 5 })
          .onComplete(() => { })
          .onError(() => { })
        Row().width(30).height(30).borderRadius(15)
          .backgroundColor(Colors.PRIMARY).border({ width: 2.5, color: Color.White })
          .justifyContent(FlexAlign.Center)
        Text('✏️').fontSize(13).fontColor(Color.White)
      }
      .margin({ top: 24 })

      // 用户信息
      Text(this.localNickname).fontSize(22).fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY).margin({ top: 20 })
      Text('@' + this.userName).fontSize(14).fontColor(Colors.TEXT_SECONDARY).margin({ top: 4 })

      // 功能菜单
      Column({ space: 0 }) {
        this.menuItem('✏️', Texts.PROFILE_EDIT_NICKNAME, () => { this.nicknameDialogCtrl.open(); })
        Divider().strokeWidth(0.5).color(Colors.BORDER).margin({ left: 16, right: 16 })
        this.menuItem('🔒', '修改密码', () => { this.passwordDialogCtrl.open(); })
      }
      .width('85%').backgroundColor(Colors.SURFACE).borderRadius(16)
      .shadow({ radius: 8, color: Colors.CARD_SHADOW }).margin({ top: 30 })

      Blank()

      Button(Texts.BTN_LOGOUT)
        .width('85%').height(48).fontSize(16)
        .fontColor(Color.White).backgroundColor(Colors.RESET).borderRadius(24)
        .onClick(() => { this.doLogout(); }).margin({ bottom: 30 })

      Text(Texts.APP_VERSION).fontSize(12).fontColor(Colors.TEXT_HINT).margin({ bottom: 20 })
    }
    .width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }

  @Builder
  menuItem(icon: string, label: string, action: () => void) {
    Row({ space: 12 }) {
      Text(icon).fontSize(20)
      Text(label).fontSize(15).fontColor(Colors.TEXT_PRIMARY)
      Blank()
      Text('›').fontSize(18).fontColor(Colors.TEXT_HINT)
    }
    .width('100%').height(52).padding({ left: 16, right: 16 })
    .onClick(() => { action(); })
  }
}

// ====== 修改昵称弹窗 ======
@CustomDialog
struct NicknameEditDialog {
  controller?: CustomDialogController;
  currentNickname: string = '';
  onConfirm?: (newName: string) => void;
  @State inputValue: string = '';

  aboutToAppear(): void { this.inputValue = this.currentNickname; }

  build() {
    Column({ space: 16 }) {
      Text('修改昵称').fontSize(18).fontWeight(FontWeight.Bold)
      TextInput({ text: this.inputValue, placeholder: '请输入新昵称' })
        .fontSize(15).height(44).width('100%').borderRadius(12)
        .backgroundColor(Colors.CANVAS_BG).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.inputValue = v; })
      Row({ space: 12 }) {
        Button(Texts.BTN_CANCEL).layoutWeight(1).height(44).fontSize(15)
          .backgroundColor(Colors.BORDER).borderRadius(12)
          .onClick(() => { this.controller?.close(); })
        Button(Texts.BTN_SAVE_CHANGE).layoutWeight(1).height(44).fontSize(15)
          .backgroundColor(Colors.PRIMARY).fontColor(Color.White).borderRadius(12)
          .onClick(() => { this.onConfirm?.(this.inputValue); this.controller?.close(); })
      }.width('100%')
    }
    .width(280).padding(24).borderRadius(20).backgroundColor(Color.White)
  }
}

// ====== 修改密码弹窗 ======
@CustomDialog
struct PasswordEditDialog {
  controller?: CustomDialogController;
  onConfirm?: (oldPwd: string, newPwd: string) => void;
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';

  build() {
    Column({ space: 12 }) {
      Text('修改密码').fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 4 })

      TextInput({ text: this.oldPassword, placeholder: '请输入旧密码' })
        .type(InputType.Password).fontSize(15).height(44).width('100%')
        .borderRadius(12).backgroundColor(Colors.CANVAS_BG).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.oldPassword = v; })

      TextInput({ text: this.newPassword, placeholder: '请输入新密码（至少6位）' })
        .type(InputType.Password).fontSize(15).height(44).width('100%')
        .borderRadius(12).backgroundColor(Colors.CANVAS_BG).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.newPassword = v; })

      TextInput({ text: this.confirmPassword, placeholder: '请确认新密码' })
        .type(InputType.Password).fontSize(15).height(44).width('100%')
        .borderRadius(12).backgroundColor(Colors.CANVAS_BG).padding({ left: 12, right: 12 })
        .onChange((v: string) => { this.confirmPassword = v; })

      Row({ space: 12 }) {
        Button(Texts.BTN_CANCEL).layoutWeight(1).height(44).fontSize(15)
          .backgroundColor(Colors.BORDER).borderRadius(12)
          .onClick(() => { this.controller?.close(); })
        Button('确认修改').layoutWeight(1).height(44).fontSize(15)
          .backgroundColor(Colors.PRIMARY).fontColor(Color.White).borderRadius(12)
          .onClick(() => {
            if (this.newPassword !== this.confirmPassword) {
              promptAction.openToast({ message: '两次密码不一致', duration: 2000 }); return;
            }
            this.onConfirm?.(this.oldPassword, this.newPassword);
            this.controller?.close();
          })
      }.width('100%')
    }
    .width(300).padding(24).borderRadius(20).backgroundColor(Color.White)
  }
}
