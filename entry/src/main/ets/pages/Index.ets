import { PhysicsCanvas } from '../components/PhysicsCanvas';
import { ToolBar } from '../components/ToolBar';
import { TopBar } from '../components/TopBar';
import { ControlBar } from '../components/ControlBar';
import { PropertyPanel } from '../components/PropertyPanel';
import { BooleanOpDialog } from '../components/BooleanOpDialog';
import { SceneGallery } from '../components/SceneGallery';
import { TutorialSwiper } from '../components/TutorialSwiper';
import { KnowledgeBase } from '../components/KnowledgeBase';
import { NetworkUtil, PhysicsFact } from '../utils/NetworkUtil';
import { SessionUtil } from '../utils/SessionUtil';
import { EditorTool, BodyInfo, PropertyChange, BooleanOpType, BooleanOpRequest, BodyDef, JointDef, SceneImportData } from '../model/Types';
import { SceneModel } from '../model/SceneModel';
import { Colors, Defaults } from '../common/Constants';
import { AnimationDurations, GradientPresets } from '../common/Theme';
import { StorageUtil } from '../utils/StorageUtil';
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  // ====== 画布状态 ======
  @State isRunning: boolean = false;
  @State gravityX: number = Defaults.GRAVITY_X;
  @State gravityY: number = Defaults.GRAVITY_Y;
  @State simulationSpeed: number = Defaults.SIMULATION_SPEED;
  @State showTrajectory: boolean = true;
  @State bodyCount: number = 0;
  @State selectedBodyId: string = '';
  @State currentTool: number = EditorTool.CIRCLE;
  @State showGrid: boolean = true;
  @State snapToGrid: boolean = true;
  @State showPropertyPanel: boolean = false;
  @State bodyInfo: BodyInfo | null = null;
  @State clearTrigger: number = 0;
  @State pendingProperty: PropertyChange | null = null;
  @State booleanOpRequest: BooleanOpRequest | null = null;
  @State sceneExportTrigger: number = 0;
  @State sceneImportData: SceneImportData | null = null;

  // ====== Tab 状态 ======
  @State currentTabIndex: number = 0;
  private tabController: TabsController = new TabsController();

  // ====== 网络数据 ======
  @State physicsFact: string = '加载中...';
  @State physicsFactSource: string = '';

  // ====== 场景保存 ======
  @StorageLink('appContext') appContext: common.Context = {} as common.Context;
  private pendingSaveName: string = '';
  private isSharingScene: boolean = false;

  private sceneLoadController: CustomDialogController = new CustomDialogController({
    builder: SceneLoadDialog({
      onSceneSelected: (scene: SceneModel) => { this.loadSceneToCanvas(scene); }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  private booleanOpController: CustomDialogController = new CustomDialogController({
    builder: BooleanOpDialog({
      onApply: (opType: BooleanOpType) => {
        if (this.booleanOpIdA !== '' && this.booleanOpIdB !== '') {
          const req: BooleanOpRequest = {
            opType: opType,
            idA: this.booleanOpIdA,
            idB: this.booleanOpIdB
          };
          this.booleanOpRequest = req;
          this.booleanOpIdA = '';
          this.booleanOpIdB = '';
          this.showPropertyPanel = false;
        }
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  private booleanOpIdA: string = '';
  private booleanOpIdB: string = '';

  aboutToAppear(): void {
    // 检查登录状态：先查内存，再查持久化存储
    this.checkLoginAndRedirect();
    this.loadDailyPhysicsFact();
    this.checkPendingSceneImport();
  }

  async checkLoginAndRedirect(): Promise<void> {
    // 先检查内存中的登录状态
    const memLoggedIn: boolean = AppStorage.get<boolean>('isLoggedIn') ?? false;
    if (memLoggedIn) return;

    // 持久化存储中检查（关掉后台再打开也能保持登录）
    const state = await SessionUtil.getLoginState(this.appContext);
    if (state.isLoggedIn) {
      AppStorage.setOrCreate('isLoggedIn', true);
      AppStorage.setOrCreate('currentUserId', state.userId);
      AppStorage.setOrCreate('currentUsername', state.username);
      AppStorage.setOrCreate('currentNickname', state.nickname);
      return;
    }

    // 未登录 → 跳转登录页
    setTimeout(() => { router.replaceUrl({ url: 'pages/Login' }); }, 50);
  }

  async loadDailyPhysicsFact(): Promise<void> {
    try {
      const fact: PhysicsFact = await NetworkUtil.fetchPhysicsFact();
      this.physicsFact = fact.text;
      this.physicsFactSource = fact.source;
    } catch (e) {
      const fallback: PhysicsFact = NetworkUtil.getRandomLocalFact();
      this.physicsFact = fallback.text;
      this.physicsFactSource = fallback.source;
    }
  }

  // ====== 画布回调 ======
  onToolSelect = (tool: EditorTool): void => {
    animateTo({ duration: AnimationDurations.FAST, curve: Curve.EaseInOut }, () => { this.currentTool = tool; });
  };
  onRequestToolSwitch = (tool: number): void => { this.currentTool = tool; };
  onStartPause = (): void => {
    animateTo({ duration: AnimationDurations.NORMAL, curve: Curve.EaseInOut }, () => { this.isRunning = !this.isRunning; });
  };
  onClear = (): void => {
    this.isRunning = false;
    this.clearTrigger += 1;
    this.selectedBodyId = '';
    this.bodyInfo = null;
    this.showPropertyPanel = false;
    this.bodyCount = 0;
  };
  onBodySelected = (id: string): void => { this.selectedBodyId = id; };
  onBodyDeselected = (): void => {
    this.selectedBodyId = '';
    this.showPropertyPanel = false;
    this.bodyInfo = null;
  };
  onBodyInfoReady = (info: BodyInfo): void => {
    this.bodyInfo = info;
    animateTo({ duration: AnimationDurations.NORMAL, curve: Curve.EaseInOut }, () => { this.showPropertyPanel = true; });
  };
  onTwoBodiesSelected = (idA: string, idB: string): void => {
    this.booleanOpIdA = idA;
    this.booleanOpIdB = idB;
    this.booleanOpController.open();
  };
  onPropertyChange = (key: string, value: Object): void => {
    if (this.bodyInfo !== null) {
      const v: number = typeof value === 'number' ? value as number : 0;
      const s: string = typeof value === 'string' ? value as string : '';
      const b: boolean = typeof value === 'boolean' ? value as boolean : false;
      if (key === 'mass') this.bodyInfo.mass = v;
      else if (key === 'velocityAngle') this.bodyInfo.velocityAngle = v;
      else if (key === 'velocityMagnitude') this.bodyInfo.velocityMagnitude = v;
      else if (key === 'friction') this.bodyInfo.friction = v;
      else if (key === 'restitution') this.bodyInfo.restitution = v;
      else if (key === 'name') this.bodyInfo.name = s;
      else if (key === 'isFixed') this.bodyInfo.isFixed = b;
    }
    if (this.selectedBodyId !== '') {
      this.pendingProperty = { id: this.selectedBodyId, key: key, value: value };
    }
  };
  onColorChange = (color: string): void => {
    this.onPropertyChange('color', color);
    if (this.bodyInfo !== null) this.bodyInfo.color = color;
  };
  deleteSelected = (): void => {
    if (this.selectedBodyId !== '') {
      this.pendingProperty = { id: this.selectedBodyId, key: '_delete', value: true };
    }
    this.selectedBodyId = '';
    this.bodyInfo = null;
    this.showPropertyPanel = false;
  };

  // ====== 场景保存（通过 export trigger 获取画布上的所有物体） ======
  onExportSceneData = async (bodyDefs: BodyDef[], jointDefs: JointDef[]): Promise<void> => {
    const scene: SceneModel = new SceneModel();
    scene.name = this.pendingSaveName || ('场景_' + new Date().toLocaleString());
    scene.timestamp = Date.now();
    scene.gravityX = this.gravityX;
    scene.gravityY = this.gravityY;
    scene.simulationSpeed = this.simulationSpeed;
    scene.bodies = bodyDefs;
    scene.joints = jointDefs;
    try {
      if (this.isSharingScene) {
        // 分享模式：不保存，直接分享 JSON
        this.isSharingScene = false;
        this.pendingSaveName = '';
        await this.doShareScene(scene);
      } else {
        await StorageUtil.saveScene(this.appContext, scene);
        this.pendingSaveName = '';
      }
    } catch (e) {
      console.error('Save/Share scene failed: ' + JSON.stringify(e));
    }
  };

  saveCurrentScene(): void {
    this.pendingSaveName = '场景_' + new Date().toLocaleString();
    this.sceneExportTrigger += 1;
  }

  shareCurrentScene(): void {
    this.pendingSaveName = '场景_' + new Date().toLocaleString();
    this.isSharingScene = true;
    this.sceneExportTrigger += 1;
  }

  // 检查是否有外部传入的场景数据需要自动导入
  async checkPendingSceneImport(): Promise<void> {
    // 方式A：Deep Link 传入时间戳 → 从分布式 KVStore 读取场景
    const ts: string = AppStorage.get<string>('pendingSceneTs') ?? '';
    if (ts !== '') {
      AppStorage.setOrCreate('pendingSceneTs', '');
      try {
        const json: string = await StorageUtil.exportSceneJson(this.appContext, parseInt(ts));
        if (json !== '') {
          const scene: SceneModel | null = await StorageUtil.importSceneJson(this.appContext, json);
          if (scene !== null) {
            this.loadSceneToCanvas(scene);
            return;
          }
        }
      } catch (_e) {
        // 跨账号分享时 KVStore 中可能没有此场景，回退到手动导入
      }
    }

    // 方式B：完整 JSON 数据（流转 / 粘贴导入）
    const json: string = AppStorage.get<string>('pendingSceneImport') ?? '';
    if (json !== '') {
      AppStorage.setOrCreate('pendingSceneImport', '');
      const scene: SceneModel | null = await StorageUtil.importSceneJson(this.appContext, json);
      if (scene !== null) {
        this.loadSceneToCanvas(scene);
      }
    }
  }

  async doShareScene(scene: SceneModel): Promise<void> {
    const json: string = JSON.stringify(scene);
    AppStorage.setOrCreate('shareSceneData', json);
    try {
      const appCtx: common.UIAbilityContext | undefined =
        AppStorage.get<common.UIAbilityContext>('appContext');
      if (!appCtx) return;

      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: 'general.plain-text',
        title: '物理沙盒场景: ' + scene.name,
        content: json
      });
      const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      await controller.show(appCtx, {} as systemShare.ShareControllerOptions);
    } catch (e) {
      console.error('[SHARE] 分享失败: ' + JSON.stringify(e));
    }
  }

  loadSceneToCanvas(scene: SceneModel): void {
    try {
      this.gravityX = scene.gravityX;
      this.gravityY = scene.gravityY;
      this.simulationSpeed = scene.simulationSpeed;
      this.isRunning = false;
      // 传递物体和关节数据给 PhysicsCanvas 重新创建
      this.sceneImportData = {
        bodies: scene.bodies,
        joints: scene.joints
      };
      this.currentTabIndex = 0;
      this.tabController.changeIndex(0);
    } catch (e) {
      console.error('Load scene failed: ' + JSON.stringify(e));
    }
  }

  onNavigateToProfile = (): void => {
    const isLoggedIn: boolean = AppStorage.get<boolean>('isLoggedIn') ?? false;
    if (isLoggedIn) {
      router.pushUrl({ url: 'pages/Profile' });
    } else {
      router.pushUrl({ url: 'pages/Login' });
    }
  };

  build() {
    Column() {
      TopBar({ onProfileClick: this.onNavigateToProfile })

      // ====== 底部 Tab 导航（3个标签） ======
      Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
        // ====== Tab 1: 物理画布 ======
        TabContent() {
          Column() {
            // 每日物理知识横幅
            Row() {
              Text(this.physicsFact)
                .fontSize(10).fontColor(Colors.TEXT_SECONDARY)
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              Text(this.physicsFactSource)
                .fontSize(9).fontColor(Colors.TEXT_HINT).margin({ left: 4 })
            }
            .width('100%').height(28)
            .padding({ left: 12, right: 12 })
            .backgroundColor('rgba(102,126,234,0.05)')
            .border({ width: { bottom: 0.5 }, color: 'rgba(0,0,0,0.04)' })
            .onClick(() => { this.loadDailyPhysicsFact(); })

            Row() {
              ToolBar({
                selectedTool: this.currentTool,
                isVertical: true,
                onToolSelect: this.onToolSelect
              })
              .width(60)

              PhysicsCanvas({
                isRunning: $isRunning,
                gravityX: $gravityX,
                gravityY: $gravityY,
                simulationSpeed: $simulationSpeed,
                showTrajectory: $showTrajectory,
                showGrid: $showGrid,
                bodyCount: $bodyCount,
                selectedBodyId: $selectedBodyId,
                currentTool: this.currentTool,
                clearTrigger: this.clearTrigger,
                pendingProperty: this.pendingProperty,
                booleanOpRequest: this.booleanOpRequest,
                sceneExportTrigger: this.sceneExportTrigger,
                sceneImportData: this.sceneImportData,
                onBodySelected: this.onBodySelected,
                onBodyDeselected: this.onBodyDeselected,
                onBodyInfoReady: this.onBodyInfoReady,
                onTwoBodiesSelected: this.onTwoBodiesSelected,
                onRequestToolSwitch: this.onRequestToolSwitch,
                onExportSceneData: this.onExportSceneData
              })
              .layoutWeight(1)

              if (this.showPropertyPanel && this.bodyInfo !== null) {
                PropertyPanel({
                  bodyInfo: this.bodyInfo,
                  onPropertyChange: this.onPropertyChange,
                  onColorChange: this.onColorChange,
                  onDelete: this.deleteSelected
                })
                .width(220)
                .transition({ type: TransitionType.Insert, translate: { x: 50 }, opacity: 0 })
                .animation({ duration: AnimationDurations.NORMAL, curve: Curve.EaseInOut })
              }
            }
            .layoutWeight(1)

            // 底部控制栏
            ControlBar({
              isRunning: $isRunning,
              gravityY: $gravityY,
              simulationSpeed: $simulationSpeed,
              showTrajectory: $showTrajectory,
              bodyCount: this.bodyCount,
              onStartPause: this.onStartPause,
              onClear: this.onClear
            })

            // 场景快捷操作
            Row({ space: 6 }) {
              Button('💾 保存')
                .fontSize(11).height(30).layoutWeight(1)
                .backgroundColor(Colors.PRIMARY).fontColor(Color.White).borderRadius(10)
                .onClick(() => { this.saveCurrentScene(); })
              Button('📂 加载')
                .fontSize(11).height(30).layoutWeight(1)
                .backgroundColor(Colors.ACCENT).fontColor(Color.White).borderRadius(10)
                .onClick(() => { this.sceneLoadController.open(); })
              Button('📤 分享')
                .fontSize(11).height(30).layoutWeight(1)
                .backgroundColor('#FF9800').fontColor(Color.White).borderRadius(10)
                .onClick(() => { this.shareCurrentScene(); })
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 4 })
          }
          .width('100%').height('100%')
        }
        .tabBar(this.tabBarBuilder('🎨', '画布', 0))

        // ====== Tab 2: 场景管理 ======
        TabContent() {
          SceneGallery({
            onLoadScene: (scene: SceneModel) => { this.loadSceneToCanvas(scene); },
            onDeleteScene: (_scene: SceneModel) => {}
          })
        }
        .tabBar(this.tabBarBuilder('📂', '场景', 1))

        // ====== Tab 3: 使用教程 ======
        TabContent() {
          TutorialSwiper()
        }
        .tabBar(this.tabBarBuilder('📖', '教程', 2))

        // ====== Tab 4: 物理知识库 ======
        TabContent() {
          KnowledgeBase()
        }
        .tabBar(this.tabBarBuilder('📚', '知识库', 3))
      }
      .layoutWeight(1)
      .scrollable(false)
      .onChange((index: number) => {
        this.currentTabIndex = index;
        if (index !== 0) this.showPropertyPanel = false;
      })
      .barHeight(52)
      .animationDuration(AnimationDurations.FAST)
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: GradientPresets.APP_BG
    })
  }

  @Builder
  tabBarBuilder(icon: string, label: string, index: number) {
    Column({ space: 2 }) {
      Text(icon).fontSize(20)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTabIndex === index ? Colors.PRIMARY : Colors.TEXT_HINT)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center).padding({ top: 4 })
  }
}

// ====== 场景加载弹窗 ======
@CustomDialog
struct SceneLoadDialog {
  controller?: CustomDialogController;
  @State scenes: SceneModel[] = [];
  onSceneSelected?: (scene: SceneModel) => void;

  aboutToAppear(): void { this.loadScenes(); }

  async loadScenes(): Promise<void> {
    const ctx: common.Context | undefined = AppStorage.get<common.Context>('appContext');
    if (ctx === undefined) return;
    try { this.scenes = await StorageUtil.loadAllScenes(ctx); }
    catch (e) { console.error('Load scenes failed'); }
  }

  build() {
    Column({ space: 12 }) {
      Text('📂 加载场景').fontSize(20).fontWeight(FontWeight.Bold).fontColor(Colors.TEXT_PRIMARY).width('100%')

      if (this.scenes.length === 0) {
        Text('暂无保存的场景').fontSize(14).fontColor(Colors.TEXT_HINT).padding({ top: 16, bottom: 16 })
      } else {
        List({ space: 8 }) {
          ForEach(this.scenes, (scene: SceneModel, index: number) => {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(scene.name).fontSize(14).fontColor(Colors.TEXT_PRIMARY).fontWeight(FontWeight.Medium)
                  Row({ space: 4 }) {
                    Text('物体: ' + scene.bodies.length.toString()).fontSize(10).fontColor(Colors.PRIMARY)
                    Text(scene.joints.length > 0 ? '连接: ' + scene.joints.length.toString() : '')
                      .fontSize(10).fontColor(Colors.ACCENT)
                    Blank()
                    Text(new Date(scene.timestamp).toLocaleString()).fontSize(10).fontColor(Colors.TEXT_HINT)
                  }
                  .width('100%')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)

                Button('加载')
                  .fontSize(11).height(30).backgroundColor(Colors.PLAY).fontColor(Color.White).borderRadius(8)
                  .padding({ left: 10, right: 10 })
                  .onClick(() => { this.onSceneSelected?.(scene); this.controller?.close(); })

                Button('删')
                  .fontSize(11).height(30).backgroundColor(Colors.RESET).fontColor(Color.White).borderRadius(8)
                  .margin({ left: 6 }).padding({ left: 10, right: 10 })
                  .onClick(async () => {
                    const ctx1: common.Context | undefined = AppStorage.get<common.Context>('appContext');
                    if (ctx1 !== undefined) {
                      await StorageUtil.deleteScene(ctx1, scene.timestamp);
                      await this.loadScenes();
                    }
                  })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8, left: 12, right: 12 })
              .backgroundColor(Colors.CANVAS_BG).borderRadius(12)
            }
          }, (_scene: SceneModel, index: number) => index.toString())
        }
        .height(260).scrollBar(BarState.Off).divider({ strokeWidth: 0 })
      }

      Button('关闭')
        .width('100%').height(42).fontSize(14)
        .backgroundColor(Colors.BORDER).fontColor(Colors.TEXT_SECONDARY).fontWeight(FontWeight.Medium)
        .borderRadius(12)
        .onClick(() => this.controller?.close())
    }
    .width('82%').padding(22)
    .backgroundBlurStyle(BlurStyle.Thick)
    .backgroundColor('rgba(255,255,255,0.92)')
    .borderRadius(22)
    .shadow({ radius: 30, color: 'rgba(0,0,0,0.2)', offsetY: 8 })
  }
}
