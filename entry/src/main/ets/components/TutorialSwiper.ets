import { Colors } from '../common/Constants';

interface TutorialPage {
  title: string;
  icon: string;
  color: string;
  steps: string[];
}

@Component
export struct TutorialSwiper {
  @State currentIndex: number = 0;
  private swiperController: SwiperController = new SwiperController();

  private tutorialPages: TutorialPage[] = [
    {
      title: '创建物体',
      icon: '🔷',
      color: '#4DB6AC',
      steps: [
        '点击左侧工具栏选择形状类型',
        '在画布上拖拽创建物体',
        '圆形 / 矩形 / 三角形 三种基础形状',
        '点击选中物体后可拖动移动位置'
      ]
    },
    {
      title: '调整属性',
      icon: '🎛️',
      color: '#42A5F5',
      steps: [
        '选中物体后右侧出现属性面板',
        '调整质量、摩擦力、弹性系数',
        '设置初始速度的大小和方向',
        '切换固定/动态模式、修改名称和颜色'
      ]
    },
    {
      title: '连接与约束',
      icon: '⛓️',
      color: '#FF9800',
      steps: [
        '使用弹簧工具连接两个物体',
        '胡克定律：F = -k·Δx',
        '使用绳索工具创建柔性约束',
        '锚点可将物体固定在画布上'
      ]
    },
    {
      title: '场景管理',
      icon: '💾',
      color: '#AB47BC',
      steps: [
        '保存场景到本地或云端',
        '在场景管理页浏览所有已保存场景',
        '支持多选批量删除',
        '分享场景JSON给其他人导入'
      ]
    }
  ];

  build() {
    Column() {
      Text('📖 使用教程').fontSize(20).fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY).padding({ left: 16, top: 12 })
        .width('100%')

      Swiper(this.swiperController) {
        ForEach(this.tutorialPages, (page: TutorialPage, index: number) => {
          Column({ space: 0 }) {
            // 彩色头部
            Column({ space: 4 }) {
              Text(page.icon).fontSize(48)
              Text(page.title).fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.White)
            }
            .width('100%').height(140)
            .backgroundColor(page.color).borderRadius({ topLeft: 20, topRight: 20 })
            .justifyContent(FlexAlign.Center)
            .margin({ left: 16, right: 16, top: 12 })

            // 步骤卡片
            Column({ space: 0 }) {
              ForEach(page.steps, (step: string, si: number) => {
                Row({ space: 10 }) {
                  Text((si + 1).toString())
                    .fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Bold)
                    .width(20).height(20).borderRadius(10)
                    .backgroundColor(page.color).textAlign(TextAlign.Center)
                  Text(step).fontSize(14).fontColor(Colors.TEXT_PRIMARY)
                    .layoutWeight(1).lineHeight(20)
                }
                .width('100%').padding({ top: 8, bottom: 8 })
                .border({ width: { bottom: si < page.steps.length - 1 ? 0.5 : 0 }, color: Colors.BORDER })
              })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 20 })
            .backgroundColor(Colors.SURFACE)
            .borderRadius({ bottomLeft: 20, bottomRight: 20 })
            .margin({ left: 16, right: 16 })
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 })
          }
          .width('100%')
        }, (_page: TutorialPage, index: number) => index.toString())
      }
      .index(this.currentIndex)
      .autoPlay(true).interval(4000).loop(true)
      .indicator(Indicator.dot()
        .itemWidth(6).itemHeight(6).selectedItemWidth(18).selectedItemHeight(6)
        .color(Colors.BORDER).selectedColor(Colors.PRIMARY))
      .onChange((index: number) => { this.currentIndex = index; })
      .width('100%')
      .height(360)

      // 底部助手
      Text('👆 左右滑动浏览教程   |   📂 场景页可加载/导入')
        .fontSize(11).fontColor(Colors.TEXT_HINT).margin({ top: 8 })
    }
    .width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }
}
