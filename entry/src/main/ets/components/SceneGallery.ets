import { Colors } from '../common/Constants';
import { AnimationDurations } from '../common/Theme';
import { SceneModel } from '../model/SceneModel';
import { StorageUtil } from '../utils/StorageUtil';
import { common } from '@kit.AbilityKit';

// ====== 场景卡片数据（用于 Grid 展示）======
interface SceneCardData {
  scene: SceneModel;
  bodyCount: number;
  timeStr: string;
}

@Component
export struct SceneGallery {
  @StorageLink('appContext') context: common.Context = {} as common.Context;
  @State scenes: SceneCardData[] = [];
  @State isLoading: boolean = true;
  @State selectedScene: SceneModel | null = null;
  @State isSelectMode: boolean = false;
  @State selectedTimestamps: Set<number> = new Set();
  onLoadScene?: (scene: SceneModel) => void;
  onDeleteScene?: (scene: SceneModel) => void;

  private importController: CustomDialogController = new CustomDialogController({
    builder: SceneImportDialog({
      context: this.context,
      onImported: () => { this.loadScenes(); }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  aboutToAppear(): void {
    this.loadScenes();
  }

  async loadScenes(): Promise<void> {
    this.isLoading = true;
    try {
      const sceneList: SceneModel[] = await StorageUtil.loadAllScenes(this.context);
      const cards: SceneCardData[] = [];
      for (const s of sceneList) {
        const card: SceneCardData = {
          scene: s,
          bodyCount: s.bodies.length,
          timeStr: new Date(s.timestamp).toLocaleString()
        };
        cards.push(card);
      }
      this.scenes = cards;
    } catch (e) {
      console.error('SceneGallery loadScenes error: ' + JSON.stringify(e));
    } finally {
      this.isLoading = false;
    }
  }

  private getScenePreviewColor(hasBodies: boolean): string {
    if (!hasBodies) return '#E0E0E0';
    const colors: string[] = ['#4DB6AC', '#EF7060', '#AB47BC', '#42A5F5', '#FFA726'];
    return colors[Math.floor(hasBodies ? 1 : 0) % colors.length];
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('📂 场景管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)

        Blank()

        Button(this.isSelectMode ? '✕ 取消' : '☑ 选择')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.isSelectMode ? Colors.RESET : Colors.TEXT_HINT)
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => {
            this.isSelectMode = !this.isSelectMode;
            if (!this.isSelectMode) this.selectedTimestamps.clear();
          })

        if (this.isSelectMode && this.selectedTimestamps.size > 0) {
          Button('🗑 删除(' + this.selectedTimestamps.size.toString() + ')')
            .fontSize(12)
            .height(32)
            .backgroundColor(Colors.RESET)
            .fontColor(Color.White)
            .borderRadius(10)
            .margin({ left: 6 })
            .onClick(async () => {
              const timestamps: number[] = [];
              this.selectedTimestamps.forEach((ts: number) => { timestamps.push(ts); });
              for (const ts of timestamps) {
                await StorageUtil.deleteScene(this.context, ts);
              }
              this.selectedTimestamps.clear();
              this.isSelectMode = false;
              this.onDeleteScene?.(new SceneModel());
              await this.loadScenes();
            })
        }

        Button('🔄 刷新')
          .fontSize(12)
          .height(32)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Color.White)
          .borderRadius(10)
          .margin({ left: 6 })
          .onClick(() => this.loadScenes())

        Button('📥 导入')
          .fontSize(12)
          .height(32)
          .backgroundColor('#FF9800')
          .fontColor(Color.White)
          .borderRadius(10)
          .margin({ left: 6 })
          .onClick(() => { this.importController.open(); })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.isLoading) {
        Column({ space: 12 }) {
          // 使用 Image 组件展示加载提示（演示 Image 组件）
          Text('🔄')
            .fontSize(40)
            .opacity(0.6)

          Text('加载中...')
            .fontSize(14)
            .fontColor(Colors.TEXT_HINT)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.scenes.length === 0) {
        Column({ space: 12 }) {
          Text('📭')
            .fontSize(48)

          Text('暂无保存的场景')
            .fontSize(15)
            .fontColor(Colors.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)

          Text('在画布中创建物理场景后，\n使用保存功能将场景保存到这里')
            .fontSize(12)
            .fontColor(Colors.TEXT_HINT)
            .textAlign(TextAlign.Center)
            .width('80%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // ====== Grid 网格布局展示场景卡片 ======
        Scroll() {
          Grid() {
            ForEach(this.scenes, (card: SceneCardData, index: number) => {
              GridItem() {
                this.sceneCard(card, index)
              }
            }, (_card: SceneCardData, index: number) => index.toString())
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .padding({ left: 16, right: 16, top: 8, bottom: 16 })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  @Builder
  sceneCard(card: SceneCardData, index: number) {
    Column({ space: 8 }) {
      // 选择模式下的勾选标记
      if (this.isSelectMode) {
        Row() {
          Blank()
          Text(this.selectedTimestamps.has(card.scene.timestamp) ? '✅' : '⬜')
            .fontSize(20)
        }
        .width('100%')
        .padding({ right: 8, top: 4 })
        .position({ x: 0, y: 0 })
      }
      // 场景预览图区域 —— 使用 Image 组件
      Row() {
        if (card.scene.bodies.length > 0) {
          // 使用 Image 展示场景预览（演示 Image 网络加载 + 属性）
          Image('https://picsum.photos/seed/scene' + index.toString() + '/200/120')
            .width('100%')
            .height(100)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: 12, topRight: 12 })
        } else {
          // 空场景显示占位
          Column({ space: 4 }) {
            Text('🎬')
              .fontSize(28)
              .opacity(0.4)
            Text('空场景')
              .fontSize(10)
              .fontColor(Colors.TEXT_HINT)
              .opacity(0.6)
          }
          .width('100%')
          .height(100)
          .backgroundColor('#F5F5F5')
          .borderRadius({ topLeft: 12, topRight: 12 })
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height(100)
      .clip(true)

      // 场景信息
      Column({ space: 4 }) {
        Text(card.scene.name || '未命名场景')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(card.timeStr)
          .fontSize(10)
          .fontColor(Colors.TEXT_HINT)

        Row({ space: 6 }) {
          Text('物体: ' + card.bodyCount.toString())
            .fontSize(10)
            .fontColor(Colors.PRIMARY)
            .fontWeight(FontWeight.Medium)

          Blank()

          // 加载按钮（选择模式下隐藏）
          if (!this.isSelectMode) {
            Button('加载')
              .fontSize(10)
              .height(26)
              .backgroundColor(Colors.PLAY)
              .fontColor(Color.White)
              .borderRadius(8)
              .padding({ left: 10, right: 10 })
              .onClick(() => {
                this.onLoadScene?.(card.scene);
              })

            // 删除按钮
            Button('删')
              .fontSize(10)
              .height(26)
              .backgroundColor(Colors.RESET)
              .fontColor(Color.White)
              .borderRadius(8)
              .padding({ left: 10, right: 10 })
              .onClick(async () => {
                await StorageUtil.deleteScene(this.context, card.scene.timestamp);
                this.onDeleteScene?.(card.scene);
                await this.loadScenes();
              })
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 6, bottom: 10 })
    }
    .width('100%')
    .backgroundColor(this.selectedTimestamps.has(card.scene.timestamp) ? 'rgba(25,118,210,0.08)' : Colors.SURFACE)
    .borderRadius(12)
    .border(this.selectedTimestamps.has(card.scene.timestamp) ? { width: 2, color: Colors.PRIMARY } : { width: 0 })
    .shadow({ radius: 6, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
    .animation({ duration: AnimationDurations.FAST, curve: Curve.FastOutSlowIn })
    .onClick(() => {
      if (this.isSelectMode) {
        if (this.selectedTimestamps.has(card.scene.timestamp)) {
          this.selectedTimestamps.delete(card.scene.timestamp);
        } else {
          this.selectedTimestamps.add(card.scene.timestamp);
        }
        this.selectedTimestamps = new Set(this.selectedTimestamps);
      }
    })
  }
}

// ====== 场景导入弹窗（粘贴 JSON） ======
@CustomDialog
struct SceneImportDialog {
  controller?: CustomDialogController;
  context: common.Context | null = null;
  onImported?: () => void;
  @State inputJson: string = '';
  @State statusMsg: string = '';

  build() {
    Column({ space: 12 }) {
      Text('📥 导入场景')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .width('100%')

      Text('粘贴从其他设备分享的场景 JSON 数据')
        .fontSize(12)
        .fontColor('#9E9E9E')
        .width('100%')

      TextInput({ text: this.inputJson, placeholder: '在此粘贴 JSON 场景数据...' })
        .fontSize(13)
        .height(120)
        .width('100%')
        .backgroundColor('#F0F1F3')
        .borderRadius(12)
        .padding(10)
        .maxLength(50000)
        .type(InputType.Normal)
        .onChange((v: string) => { this.inputJson = v; this.statusMsg = ''; })

      if (this.statusMsg !== '') {
        Text(this.statusMsg)
          .fontSize(12)
          .fontColor(this.statusMsg.startsWith('✅') ? '#4CAF50' : '#E53935')
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Row({ space: 10 }) {
        Button('取消')
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .backgroundColor('#E0E0E0')
          .fontColor('#616161')
          .borderRadius(12)
          .onClick(() => this.controller?.close())

        Button('导入')
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .backgroundColor('#FF9800')
          .fontColor(Color.White)
          .borderRadius(12)
          .onClick(async () => {
            if (this.inputJson.trim() === '') {
              this.statusMsg = '❌ 请先粘贴 JSON 数据';
              return;
            }
            if (this.context === null) {
              this.statusMsg = '❌ 上下文错误';
              return;
            }
            const scene: SceneModel | null = await StorageUtil.importSceneJson(this.context, this.inputJson);
            if (scene !== null) {
              this.statusMsg = '✅ 导入成功！刷新即可看到';
              this.onImported?.();
            } else {
              this.statusMsg = '❌ JSON 格式不正确';
            }
          })
      }
      .width('100%')
    }
    .width('85%')
    .padding(22)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({ radius: 30, color: 'rgba(0,0,0,0.2)', offsetY: 8 })
  }
}
