import { Colors, Texts } from '../common/Constants';
import { EditorTool, ToolItem } from '../model/Types';
import { AnimationDurations } from '../common/Theme';

@Component
export struct ToolBar {
  @Prop selectedTool: number = EditorTool.CIRCLE;
  @Prop isVertical: boolean = false;
  onToolSelect?: (tool: EditorTool) => void;

  private tools: ToolItem[] = [];

  aboutToAppear(): void {
    this.buildToolList();
  }

  private buildToolList(): void {
    const list: ToolItem[] = [];
    const t0: ToolItem = { id: EditorTool.SELECT, label: Texts.TOOL_SELECT, icon: '☝', color: '#1976D2' };
    const t1: ToolItem = { id: EditorTool.CIRCLE, label: Texts.TOOL_CIRCLE, icon: '●', color: Colors.BODY_CIRCLE };
    const t2: ToolItem = { id: EditorTool.RECTANGLE, label: Texts.TOOL_RECT, icon: '■', color: Colors.BODY_RECTANGLE };
    const t3: ToolItem = { id: EditorTool.TRIANGLE, label: Texts.TOOL_TRIANGLE, icon: '▽', color: Colors.BODY_TRIANGLE };
    const t4: ToolItem = { id: EditorTool.SPRING, label: Texts.TOOL_SPRING, icon: '⚡', color: Colors.SPRING };
    const t5: ToolItem = { id: EditorTool.ROPE, label: Texts.TOOL_ROPE, icon: '⛓', color: Colors.ROPE };
    const t6: ToolItem = { id: EditorTool.ANCHOR, label: Texts.TOOL_ANCHOR, icon: '⚓', color: Colors.BODY_STATIC };
    const t7: ToolItem = { id: EditorTool.ERASER, label: Texts.TOOL_ERASER, icon: '✕', color: '#9E9E9E' };
    list.push(t0, t1, t2, t3, t4, t5, t6, t7);
    this.tools = list;
  }

  build() {
    if (this.isVertical) {
      Column({ space: 4 }) {
        ForEach(this.tools, (item: ToolItem) => {
          this.toolBtn(item)
        })
      }
      .width(60)
      .height('100%')
      .padding({ top: 10, bottom: 10 })
      .backgroundBlurStyle(BlurStyle.Thin)
      .backgroundColor('rgba(255,255,255,0.7)')
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetX: 2 })
      .border({ width: { right: 0.5 }, color: 'rgba(0,0,0,0.05)' })
    } else {
      Scroll() {
        Row({ space: 4 }) {
          ForEach(this.tools, (item: ToolItem) => {
            this.toolBtn(item)
          })
        }
        .padding({ left: 6, right: 6 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(56)
      .backgroundBlurStyle(BlurStyle.Thin)
      .backgroundColor('rgba(255,255,255,0.7)')
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetY: 2 })
      .border({ width: { top: 0.5 }, color: 'rgba(0,0,0,0.05)' })
    }
  }

  @Builder
  toolBtn(item: ToolItem) {
    Column({ space: 2 }) {
      Text(item.icon)
        .fontSize(this.isVertical ? 18 : 20)
        .fontColor(this.selectedTool === item.id ? item.color : Colors.TEXT_HINT)

      Text(item.label)
        .fontSize(10)
        .fontColor(this.selectedTool === item.id ? item.color : Colors.TEXT_HINT)
        .maxLines(1)
    }
    .width(this.isVertical ? 54 : 52)
    .height(this.isVertical ? 50 : 52)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.selectedTool === item.id ? Colors.TOOL_ACTIVE : Color.Transparent)
    .borderRadius(10)
    .onClick(() => { this.onToolSelect?.(item.id); })
    .animation({ duration: AnimationDurations.FAST, curve: Curve.FastOutSlowIn })
    .scale({ x: this.selectedTool === item.id ? 1.05 : 1.0, y: this.selectedTool === item.id ? 1.05 : 1.0 })
  }
}
