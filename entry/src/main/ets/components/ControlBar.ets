import { Colors } from '../common/Constants';
import { AnimationDurations } from '../common/Theme';

@Component
export struct ControlBar {
  @Link isRunning: boolean;
  @Link gravityY: number;
  @Link simulationSpeed: number;
  @Link showTrajectory: boolean;
  @Prop bodyCount: number = 0;
  onStartPause?: () => void;
  onClear?: () => void;

  build() {
    Row() {
      // 运行/停止按钮
      Button(this.isRunning ? '⏸ 停止' : '▶ 运行')
        .fontSize(15)
        .height(44)
        .layoutWeight(1)
        .backgroundColor(this.isRunning ? Colors.PAUSE : Colors.PLAY)
        .fontColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.12)', offsetY: 2 })
        .onClick(() => {
          animateTo({ duration: AnimationDurations.NORMAL, curve: Curve.EaseInOut }, () => {
            this.onStartPause?.();
          });
        })
        .animation({ duration: AnimationDurations.NORMAL, curve: Curve.EaseInOut })

      // 清空按钮
      Button('✕ 清空')
        .fontSize(15)
        .height(44)
        .layoutWeight(1)
        .backgroundColor(Colors.RESET)
        .fontColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 4, color: 'rgba(229,57,53,0.2)', offsetY: 2 })
        .margin({ left: 10 })
        .onClick(() => this.onClear?.())

      // 分隔
      Text('|')
        .fontSize(16)
        .fontColor(Colors.BORDER)
        .margin({ left: 14, right: 14 })

      // 重力滑块
      Column({ space: 2 }) {
        Text('重力 ' + this.gravityY.toFixed(1))
          .fontSize(10)
          .fontColor(Colors.TEXT_SECONDARY)
        Slider({ value: this.gravityY, min: 0, max: 25, step: 0.5, style: SliderStyle.OutSet })
          .width(70)
          .blockColor(Colors.PRIMARY)
          .trackColor(Colors.BORDER)
          .blockSize({ width: 14, height: 14 })
          .onChange((v: number) => {
            this.gravityY = v;
          })
      }

      Blank()

      // 轨迹 + 计数
      Column({ space: 3 }) {
        Row({ space: 4 }) {
          Text('轨迹')
            .fontSize(10)
            .fontColor(Colors.TEXT_HINT)
          Toggle({ type: ToggleType.Switch, isOn: this.showTrajectory })
            .width(30)
            .selectedColor(Colors.TRAJECTORY)
            .onChange((isOn: boolean) => {
              this.showTrajectory = isOn;
            })
        }

        Row({ space: 4 }) {
          Text('物体')
            .fontSize(11)
            .fontColor(Colors.PRIMARY)
            .fontWeight(FontWeight.Medium)
          Text(this.bodyCount.toString())
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .backgroundColor(Colors.PRIMARY)
            .borderRadius(9)
            .width(22)
            .height(18)
            .textAlign(TextAlign.Center)
            .fontSize(10)
        }
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [['#ffffff', 0.0], ['#f5f7ff', 1.0]]
    })
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetY: -2 })
    .border({ width: { top: 0.5 }, color: 'rgba(0,0,0,0.05)' })
  }
}
