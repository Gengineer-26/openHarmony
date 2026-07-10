import { Colors } from '../common/Constants';
import { AnimationDurations } from '../common/Theme';

@CustomDialog
export struct ContextMenu {
  controller?: CustomDialogController;
  onCopy?: () => void;
  onPaste?: () => void;
  onDelete?: () => void;
  onLock?: () => void;
  isLocked: boolean = false;

  build() {
    Column({ space: 0 }) {
      this.menuItem('删除', Colors.RESET, () => {
        this.onDelete?.();
        this.controller?.close();
      })

      Divider().strokeWidth(0.5).color(Colors.BORDER).margin({ left: 12, right: 12 })

      this.menuItem(this.isLocked ? '解锁' : '锁定', Colors.PAUSE, () => {
        this.onLock?.();
        this.controller?.close();
      })

      Divider().strokeWidth(0.5).color(Colors.BORDER).margin({ left: 12, right: 12 })

      this.menuItem('复制', Colors.PRIMARY, () => {
        this.onCopy?.();
        this.controller?.close();
      })

      Divider().strokeWidth(0.5).color(Colors.BORDER).margin({ left: 12, right: 12 })

      this.menuItem('粘贴', Colors.ACCENT, () => {
        this.onPaste?.();
        this.controller?.close();
      })

      Divider().strokeWidth(0.5).color(Colors.BORDER).margin({ left: 12, right: 12 })

      this.menuItem('取消', Colors.TEXT_HINT, () => {
        this.controller?.close();
      })
    }
    .width(170)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor(Colors.GLASS_BG)
    .borderRadius(14)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 4 })
    .padding({ top: 6, bottom: 6 })
    .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0.85, y: 0.85 } })
  }

  @Builder
  menuItem(label: string, color: string, action: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(color)
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(44)
    .borderRadius(8)
    .onClick(() => action())
    .animation({ duration: AnimationDurations.FAST, curve: Curve.FastOutSlowIn })
  }
}
