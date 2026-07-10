import { Colors } from '../common/Constants';
import { SceneModel } from '../model/SceneModel';
import { StorageUtil } from '../utils/StorageUtil';
import { common } from '@kit.AbilityKit';
import { AnimationDurations } from '../common/Theme';

@CustomDialog
export struct SceneDialog {
  controller?: CustomDialogController;
  context: common.Context | null = null;
  scenes: SceneModel[] = [];
  onLoadScene?: (scene: SceneModel) => void;
  mode: string = 'load'; // 'load' | 'save'
  sceneName: string = '';

  aboutToAppear(): void {
    if (this.mode === 'load' && this.context !== null) {
      this.loadSceneList();
    }
  }

  async loadSceneList(): Promise<void> {
    if (this.context === null) return;
    this.scenes = await StorageUtil.loadAllScenes(this.context);
  }

  build() {
    Column({ space: 12 }) {
      // 标题行（带角标）
      Row({ space: 8 }) {
        Text(this.mode === 'load' ? '加载场景' : '保存场景')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)

        if (this.mode === 'load' && this.scenes.length > 0) {
          Text('(' + this.scenes.length.toString() + ')')
            .fontSize(13)
            .fontColor(Colors.PRIMARY)
            .fontWeight(FontWeight.Medium)
        }

        Blank()
      }
      .width('100%')

      if (this.mode === 'save') {
        TextInput({ text: this.sceneName, placeholder: '输入场景名称' })
          .width('100%')
          .height(44)
          .borderRadius(12)
          .backgroundColor(Colors.CANVAS_BG)
          .padding({ left: 12, right: 12 })
          .fontSize(14)
          .onChange((v: string) => { this.sceneName = v; })

        Button('确认保存')
          .width('100%')
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(Colors.PLAY)
          .fontColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 6, color: 'rgba(76,175,80,0.25)', offsetY: 3 })
          .onClick(() => this.controller?.close())
      }

      if (this.mode === 'load') {
        if (this.scenes.length === 0) {
          Column({ space: 8 }) {
            Text('📂')
              .fontSize(40)
            Text('暂无保存的场景')
              .fontSize(14)
              .fontColor(Colors.TEXT_HINT)
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
          .alignItems(HorizontalAlign.Center)
        } else {
          List({ space: 8 }) {
            ForEach(this.scenes, (scene: SceneModel, index: number) => {
              ListItem() {
                Row() {
                  Column({ space: 4 }) {
                    Text(scene.name)
                      .fontSize(15)
                      .fontColor(Colors.TEXT_PRIMARY)
                      .fontWeight(FontWeight.Medium)
                    Text(new Date(scene.timestamp).toLocaleString())
                      .fontSize(11)
                      .fontColor(Colors.TEXT_HINT)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Button('加载')
                    .fontSize(12)
                    .height(32)
                    .backgroundColor(Colors.PRIMARY)
                    .fontColor(Color.White)
                    .borderRadius(10)
                    .padding({ left: 12, right: 12 })
                    .shadow({ radius: 4, color: 'rgba(25,118,210,0.2)', offsetY: 2 })
                    .onClick(() => {
                      this.onLoadScene?.(scene);
                      this.controller?.close();
                    })

                  Button('删')
                    .fontSize(12)
                    .height(32)
                    .backgroundColor(Colors.RESET)
                    .fontColor(Color.White)
                    .borderRadius(10)
                    .margin({ left: 8 })
                    .onClick(async () => {
                      if (this.context !== null) {
                        await StorageUtil.deleteScene(this.context, scene.timestamp);
                        await this.loadSceneList();
                      }
                    })
                }
                .width('100%')
                .padding({ top: 10, bottom: 10, left: 4, right: 4 })
              }
              .borderRadius(12)
              .backgroundColor(Colors.CANVAS_BG)
              .padding({ left: 12, right: 12 })
              .animation({ duration: AnimationDurations.FAST, curve: Curve.FastOutSlowIn })
            }, (_scene: SceneModel, index: number) => index.toString())
          }
          .height(300)
          .scrollBar(BarState.Off)
          .divider({ strokeWidth: 0 })
        }
      }

      Button('关闭')
        .width('100%')
        .height(44)
        .fontSize(15)
        .backgroundColor(Colors.BORDER)
        .fontColor(Colors.TEXT_SECONDARY)
        .fontWeight(FontWeight.Medium)
        .borderRadius(12)
        .onClick(() => this.controller?.close())
    }
    .width('82%')
    .padding(22)
    .backgroundBlurStyle(BlurStyle.Thick)
    .backgroundColor(Colors.GLASS_BG_THICK)
    .borderRadius(22)
    .shadow({ radius: 30, color: Colors.DIALOG_SHADOW, offsetY: 8 })
    .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0.92, y: 0.92 } })
  }
}
