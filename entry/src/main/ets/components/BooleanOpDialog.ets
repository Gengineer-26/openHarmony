import { Colors, Texts } from '../common/Constants';
import { BooleanOpType } from '../model/Types';

@CustomDialog
export struct BooleanOpDialog {
  controller?: CustomDialogController;
  onApply?: (opType: BooleanOpType) => void;

  build() {
    Column({ space: 12 }) {
      Text(Texts.BOOL_TITLE)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ bottom: 2 })

      Text('请先选择两个物体（点击选中），然后选择操作类型')
        .fontSize(12)
        .fontColor(Colors.TEXT_HINT)
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ bottom: 6 })

      this.opButton(Texts.BOOL_UNION + ' (Union)', BooleanOpType.UNION, Colors.PLAY)
      this.opButton(Texts.BOOL_SUBTRACT + ' (A-B)', BooleanOpType.SUBTRACT, Colors.PAUSE)
      this.opButton(Texts.BOOL_INTERSECT + ' (∩)', BooleanOpType.INTERSECT, Colors.PRIMARY)

      Divider()
        .strokeWidth(0.5)
        .color(Colors.BORDER)

      Button('取消')
        .width('100%')
        .height(42)
        .fontSize(14)
        .backgroundColor(Colors.BORDER)
        .fontColor(Colors.TEXT_SECONDARY)
        .borderRadius(12)
        .onClick(() => this.controller?.close())
    }
    .width(290)
    .padding(24)
    .backgroundBlurStyle(BlurStyle.Thick)
    .backgroundColor(Colors.GLASS_BG_THICK)
    .borderRadius(20)
    .shadow({ radius: 30, color: Colors.DIALOG_SHADOW, offsetY: 8 })
    .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0.9, y: 0.9 } })
  }

  @Builder
  opButton(label: string, opType: BooleanOpType, btnColor: string) {
    Button(label)
      .width('100%')
      .height(46)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .backgroundColor(btnColor)
      .fontColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 6, color: 'rgba(0,0,0,0.15)', offsetY: 3 })
      .onClick(() => {
        this.onApply?.(opType);
        this.controller?.close();
      })
      .animation({ duration: 150, curve: Curve.FastOutSlowIn })
  }
}
