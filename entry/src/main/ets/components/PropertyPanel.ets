import { Colors, Texts } from '../common/Constants';
import { BodyInfo } from '../model/Types';
import { AnimationDurations } from '../common/Theme';

// ====== 紧凑型滑块行（用于两列布局） ======
@Component
struct SliderPropRow {
  @Link value: number;
  @Prop min: number = 0;
  @Prop max: number = 100;
  @Prop propKey: string = '';
  @Prop unitLabel: string = '';
  onPropertyChange?: (key: string, value: Object) => void;

  @State isEditing: boolean = false;
  @State editText: string = '';

  private formatDisplay(): string {
    const v: number = this.value;
    if (this.unitLabel !== '') {
      return v.toFixed(2) + ' ' + this.unitLabel;
    }
    return v.toFixed(2);
  }

  build() {
    Column({ space: 4 }) {
      // 数值显示/编辑
      Row() {
        if (this.isEditing) {
          TextInput({ text: this.editText, placeholder: this.value.toFixed(2) })
            .fontSize(13)
            .fontColor(Colors.PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .height(30)
            .backgroundColor(Colors.CANVAS_BG)
            .borderRadius(8)
            .border({ width: 2, color: Colors.PRIMARY })
            .type(InputType.Normal)
            .onChange((v: string) => {
              let filtered: string = '';
              let hasDot: boolean = false;
              for (let i: number = 0; i < v.length; i++) {
                const ch: string = v.charAt(i);
                if (ch >= '0' && ch <= '9') { filtered += ch; }
                else if (ch === '.' && !hasDot) { filtered += ch; hasDot = true; }
              }
              this.editText = filtered;
            })
            .onSubmit(() => {
              const parsed: number = parseFloat(this.editText);
              if (!isNaN(parsed)) {
                this.value = Math.max(this.min, Math.min(this.max, parsed));
                this.onPropertyChange?.(this.propKey, this.value);
              }
              this.isEditing = false;
              this.editText = '';
            })
            .onBlur(() => {
              const parsed: number = parseFloat(this.editText);
              if (!isNaN(parsed)) {
                this.value = Math.max(this.min, Math.min(this.max, parsed));
                this.onPropertyChange?.(this.propKey, this.value);
              }
              this.isEditing = false;
              this.editText = '';
            })
        } else {
          Text(this.formatDisplay())
            .fontSize(13)
            .fontColor(Colors.PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .height(28)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F5F7FA')
            .borderRadius(8)
            .border({ width: 1, color: Colors.BORDER })
            .onClick(() => { this.isEditing = true; this.editText = this.value.toFixed(2); })
        }
      }
      .width('100%')

      Slider({
        value: this.value,
        min: this.min,
        max: this.max,
        step: (this.max - this.min) / 100,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .blockColor(Colors.PRIMARY)
        .trackColor(Colors.BORDER)
        .blockSize({ width: 12, height: 12 })
        .onChange((v: number) => {
          this.value = v;
          this.onPropertyChange?.(this.propKey, v);
        })
    }
    .width('100%')
  }
}

// ====== 属性面板主组件（两列布局，减少滚动高度） ======
@Component
export struct PropertyPanel {
  @Prop @Watch('onBodyInfoChange') bodyInfo: BodyInfo | null = null;
  onPropertyChange?: (key: string, value: Object) => void;
  onColorChange?: (color: string) => void;
  onDelete?: () => void;

  @State localName: string = '';
  @State localMass: number = 1;
  @State localVelAngle: number = 0;
  @State localVelMag: number = 0;
  @State localFriction: number = 0;
  @State localRestitution: number = 0;
  @State localIsFixed: boolean = false;
  @State localColor: string = '#4DB6AC';
  @State localShapeType: string = '';
  @State localWidth: number = 0;
  @State localHeight: number = 0;
  @State localRadius: number = 0;
  @State localId: string = '';

  // 拨盘输入
  @State editingField: string = '';
  @State editText: string = '';

  private dialSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private dialCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.dialSettings);
  private dialCX: number = 60;
  private dialCY: number = 60;
  private dialRadius: number = 50;
  private snapAngles: number[] = [0, 45, 90, 135, 180, 225, 270, 315];
  private snapThreshold: number = 7;

  private colorOptions: string[] = [
    '#4DB6AC', '#EF7060', '#42A5F5', '#AB47BC',
    '#FFA726', '#66BB6A', '#78909C', '#8D6E63',
    '#EC407A', '#26C6DA', '#FFEE58', '#BDBDBD'
  ];

  onBodyInfoChange(): void {
    if (this.bodyInfo !== null) {
      if (this.localName !== this.bodyInfo.name) this.localName = this.bodyInfo.name;
      if (this.localMass !== this.bodyInfo.mass) this.localMass = this.bodyInfo.mass;
      if (this.localVelAngle !== this.bodyInfo.velocityAngle) this.localVelAngle = this.bodyInfo.velocityAngle;
      if (this.localVelMag !== this.bodyInfo.velocityMagnitude) this.localVelMag = this.bodyInfo.velocityMagnitude;
      if (this.localFriction !== this.bodyInfo.friction) this.localFriction = this.bodyInfo.friction;
      if (this.localRestitution !== this.bodyInfo.restitution) this.localRestitution = this.bodyInfo.restitution;
      if (this.localIsFixed !== this.bodyInfo.isFixed) this.localIsFixed = this.bodyInfo.isFixed;
      if (this.localColor !== this.bodyInfo.color) this.localColor = this.bodyInfo.color;
      if (this.localShapeType !== this.bodyInfo.shapeType) this.localShapeType = this.bodyInfo.shapeType;
      if (this.localWidth !== this.bodyInfo.width) this.localWidth = this.bodyInfo.width;
      if (this.localHeight !== this.bodyInfo.height) this.localHeight = this.bodyInfo.height;
      if (this.localRadius !== this.bodyInfo.radius) this.localRadius = this.bodyInfo.radius;
      if (this.localId !== this.bodyInfo.id) this.localId = this.bodyInfo.id;
      this.redrawDial();
    }
  }

  private snapAngle(angleDeg: number): number {
    let normalized: number = angleDeg % 360;
    if (normalized < 0) normalized += 360;
    for (const snap of this.snapAngles) {
      if (Math.abs(normalized - snap) <= this.snapThreshold) return snap;
    }
    return Math.round(normalized);
  }

  private redrawDial(): void {
    const ctx: CanvasRenderingContext2D = this.dialCtx;
    const cx: number = this.dialCX;
    const cy: number = this.dialCY;
    const r: number = this.dialRadius;

    ctx.clearRect(0, 0, 120, 120);

    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.fillStyle = '#E8E9EB';
    ctx.fill();
    ctx.strokeStyle = '#BDBDBD';
    ctx.lineWidth = 1.5;
    ctx.stroke();

    for (const snap of this.snapAngles) {
      const rad: number = snap * Math.PI / 180;
      const outerX: number = cx + Math.cos(rad) * (r - 4);
      const outerY: number = cy + Math.sin(rad) * (r - 4);
      const innerX: number = cx + Math.cos(rad) * (r - 10);
      const innerY: number = cy + Math.sin(rad) * (r - 10);
      ctx.beginPath();
      ctx.moveTo(innerX, innerY);
      ctx.lineTo(outerX, outerY);
      ctx.strokeStyle = snap % 90 === 0 ? '#616161' : '#BDBDBD';
      ctx.lineWidth = snap % 90 === 0 ? 2 : 1.2;
      ctx.lineCap = 'round';
      ctx.stroke();
    }

    const angleRad: number = this.localVelAngle * Math.PI / 180;
    const arrowLen: number = r - 20;

    ctx.beginPath();
    ctx.moveTo(cx, cy);
    const tipX: number = cx + Math.cos(angleRad) * arrowLen;
    const tipY: number = cy + Math.sin(angleRad) * arrowLen;
    ctx.lineTo(tipX, tipY);
    ctx.strokeStyle = Colors.PRIMARY;
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.stroke();
    ctx.lineCap = 'butt';

    const arrowSize: number = 10;
    ctx.beginPath();
    ctx.moveTo(tipX, tipY);
    ctx.lineTo(tipX - Math.cos(angleRad - 0.5) * arrowSize, tipY - Math.sin(angleRad - 0.5) * arrowSize);
    ctx.lineTo(tipX - Math.cos(angleRad + 0.5) * arrowSize, tipY - Math.sin(angleRad + 0.5) * arrowSize);
    ctx.closePath();
    ctx.fillStyle = Colors.PRIMARY;
    ctx.fill();

    ctx.beginPath();
    ctx.arc(cx, cy, 6, 0, Math.PI * 2);
    ctx.fillStyle = Colors.PRIMARY;
    ctx.fill();
    ctx.beginPath();
    ctx.arc(cx, cy, 3, 0, Math.PI * 2);
    ctx.fillStyle = '#FFFFFF';
    ctx.fill();
  }

  private handleDialTouch(event: TouchEvent): void {
    if (event.touches.length === 0) return;
    const tx: number = event.touches[0].x;
    const ty: number = event.touches[0].y;
    const dx: number = tx - this.dialCX;
    const dy: number = ty - this.dialCY;
    const dist: number = Math.sqrt(dx * dx + dy * dy);
    if (dist < 10 || dist > this.dialRadius + 6) return;

    const rawAngle: number = Math.atan2(dy, dx) * 180 / Math.PI;
    const deg: number = ((rawAngle % 360) + 360) % 360;
    const snapped: number = this.snapAngle(deg);
    this.localVelAngle = snapped;
    this.redrawDial();
    this.onPropertyChange?.('velocityAngle', snapped);
    if (this.editingField === 'velocityAngle') { this.editingField = ''; this.editText = ''; }
  }

  private getShapeLabel(shapeType: string): string {
    if (shapeType === 'circle') return '圆形';
    if (shapeType === 'triangle') return '三角';
    if (shapeType === 'polygon') return '多边形';
    return '矩形';
  }

  build() {
    Column() {
      if (this.bodyInfo === null) {
        Column({ space: 12 }) {
          Text('📐').fontSize(36)
          Text('点击画布中的物体进行选择')
            .fontSize(13).fontColor(Colors.TEXT_HINT).textAlign(TextAlign.Center).width('100%')
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            // ===== Row 1: 名称 + 类型/ID =====
            Row({ space: 8 }) {
              TextInput({ text: this.localName, placeholder: '名称' })
                .fontSize(12).height(32).layoutWeight(1)
                .backgroundColor(Colors.CANVAS_BG).borderRadius(8)
                .onChange((v: string) => { this.localName = v; this.onPropertyChange?.('name', v); })
              Text(this.getShapeLabel(this.localShapeType) + ' | ' + this.localId)
                .fontSize(10).fontColor(Colors.TEXT_HINT).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')

            // ===== Row 2: 两列布局 =====
            Row({ space: 8 }) {
              // ---- 左列 ----
              Column({ space: 6 }) {
                this.sectionLabel('⚖️ 质量 (kg)')
                SliderPropRow({
                  value: $localMass, min: 0.1, max: 20,
                  propKey: 'mass', unitLabel: 'kg',
                  onPropertyChange: this.onPropertyChange
                })

                this.sectionLabel('🛞 摩擦')
                SliderPropRow({
                  value: $localFriction, min: 0, max: 1,
                  propKey: 'friction', unitLabel: '',
                  onPropertyChange: this.onPropertyChange
                })

                this.sectionLabel('🏀 弹性')
                SliderPropRow({
                  value: $localRestitution, min: 0, max: 1,
                  propKey: 'restitution', unitLabel: '',
                  onPropertyChange: this.onPropertyChange
                })

                // 固定开关
                Row() {
                  Text('📌 固定').fontSize(10).fontColor(Colors.TEXT_SECONDARY).layoutWeight(1)
                  Toggle({ type: ToggleType.Switch, isOn: this.localIsFixed })
                    .width(36)
                    .selectedColor(Colors.BODY_STATIC)
                    .onChange((v: boolean) => {
                      this.localIsFixed = v;
                      this.onPropertyChange?.('isFixed', v);
                    })
                }
                .width('100%').height(30)
              }
              .layoutWeight(1)

              // ---- 右列 ----
              Column({ space: 6 }) {
                // 角度拨盘（紧凑版）
                this.sectionLabel('🧭 方向')
                Column({ space: 4 }) {
                  Row() {
                    Text('角度').fontSize(10).fontColor(Colors.TEXT_HINT)
                    Blank()
                    if (this.editingField === 'velocityAngle') {
                      TextInput({ text: this.editText, placeholder: this.localVelAngle.toFixed(0) })
                        .fontSize(12).fontColor(Colors.PRIMARY).fontWeight(FontWeight.Bold)
                        .width(50).height(26).backgroundColor(Colors.CANVAS_BG).borderRadius(6)
                        .type(InputType.Normal)
                        .onChange((v: string) => {
                          let filtered: string = ''; let hasDot: boolean = false;
                          for (let i: number = 0; i < v.length; i++) {
                            const ch: string = v.charAt(i);
                            if (ch >= '0' && ch <= '9') { filtered += ch; }
                            else if (ch === '.' && !hasDot) { filtered += ch; hasDot = true; }
                          }
                          this.editText = filtered;
                        })
                        .onSubmit(() => {
                          const parsed: number = parseFloat(this.editText);
                          if (!isNaN(parsed)) {
                            this.localVelAngle = this.snapAngle(parsed);
                            this.redrawDial();
                            this.onPropertyChange?.('velocityAngle', this.localVelAngle);
                          }
                          this.editingField = ''; this.editText = '';
                        })
                        .onBlur(() => {
                          const parsed: number = parseFloat(this.editText);
                          if (!isNaN(parsed)) {
                            this.localVelAngle = this.snapAngle(parsed);
                            this.redrawDial();
                            this.onPropertyChange?.('velocityAngle', this.localVelAngle);
                          }
                          this.editingField = ''; this.editText = '';
                        })
                    } else {
                      Text(this.localVelAngle.toFixed(0) + '°')
                        .fontSize(12).fontColor(Colors.PRIMARY).fontWeight(FontWeight.Bold)
                        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                        .borderRadius(4).border({ width: 1, color: Colors.BORDER, style: BorderStyle.Dashed })
                        .onClick(() => { this.editingField = 'velocityAngle'; this.editText = this.localVelAngle.toFixed(0); })
                    }
                  }
                  .width('100%')

                  Canvas(this.dialCtx)
                    .width(120).height(120)
                    .backgroundColor(Colors.CANVAS_BG).borderRadius(60)
                    .onReady(() => { this.redrawDial(); })
                    .onTouch((event: TouchEvent) => this.handleDialTouch(event))
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)

                this.sectionLabel('⚡ 速度 (m/s)')
                SliderPropRow({
                  value: $localVelMag, min: 0, max: 50,
                  propKey: 'velocityMagnitude', unitLabel: 'm/s',
                  onPropertyChange: this.onPropertyChange
                })
              }
              .layoutWeight(1)
            }
            .width('100%')

            // ===== Row 3: 颜色选择 =====
            Text(Texts.LBL_COLOR)
              .fontSize(11).fontColor(Colors.TEXT_SECONDARY).fontWeight(FontWeight.Medium)
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.colorOptions, (c: string) => {
                Row()
                  .width(22).height(22).borderRadius(11).backgroundColor(c)
                  .border({
                    width: this.localColor === c ? 2.5 : 1,
                    color: this.localColor === c ? Colors.TEXT_PRIMARY : Colors.BORDER
                  })
                  .onClick(() => { this.localColor = c; this.onColorChange?.(c); })
                  .margin({ right: 3, bottom: 3 })
              })
            }
            .width('100%')

            // ===== Row 4: 尺寸信息 =====
            Row({ space: 8 }) {
              if (this.localShapeType === 'circle') {
                Text('半径: ' + this.localRadius.toFixed(1) + ' m')
                  .fontSize(10).fontColor(Colors.TEXT_HINT)
              } else {
                Text('宽: ' + this.localWidth.toFixed(1) + ' m')
                  .fontSize(10).fontColor(Colors.TEXT_HINT)
                Text('高: ' + this.localHeight.toFixed(1) + ' m')
                  .fontSize(10).fontColor(Colors.TEXT_HINT)
              }
              Blank()
            }
            .width('100%')

            // ===== Row 5: 删除按钮 =====
            Button('🗑 删除物体')
              .width('100%').height(38)
              .fontSize(13).fontWeight(FontWeight.Medium)
              .backgroundColor(Colors.RESET).fontColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 4, color: 'rgba(229,57,53,0.25)', offsetY: 2 })
              .margin({ top: 4 })
              .onClick(() => this.onDelete?.())
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%')
    .padding(10)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255,255,255,0.82)')
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.1)', offsetX: -4 })
    .border({ width: { left: 0.5 }, color: 'rgba(0,0,0,0.06)' })
  }

  @Builder
  sectionLabel(label: string) {
    Text(label)
      .fontSize(10).fontColor(Colors.TEXT_SECONDARY).fontWeight(FontWeight.Medium)
      .width('100%').padding({ top: 2, bottom: 1 })
  }
}
