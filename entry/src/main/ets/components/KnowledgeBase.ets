import { Colors } from '../common/Constants';
import { NetworkUtil, PhysicsFact } from '../utils/NetworkUtil';

// 物理知识点
interface KnowledgeCard {
  title: string;
  formula: string;
  content: string;
}

interface KnowledgeCategory {
  name: string;
  icon: string;
  color: string;
  cards: KnowledgeCard[];
}

@Component
export struct KnowledgeBase {
  @State currentCat: number = 0;
  @State dailyFact: string = '';
  @State factSource: string = '';

  private categories: KnowledgeCategory[] = [
    {
      name: '力学', icon: '⚡', color: '#4DB6AC',
      cards: [
        { title: '牛顿第一定律（惯性定律）', formula: 'F=0 ⇔ v=常量', content: '不受外力作用的物体将保持静止或匀速直线运动状态。惯性是物体抵抗运动状态改变的性质，质量越大惯性越大。' },
        { title: '牛顿第二定律', formula: 'F=ma', content: '物体的加速度与所受合力成正比，与质量成反比，方向与合力方向相同。这是经典力学的核心方程。' },
        { title: '牛顿第三定律', formula: 'F₁₂=-F₂₁', content: '作用力与反作用力大小相等、方向相反，作用在不同物体上。注意它们不能抵消！' },
        { title: '胡克定律', formula: 'F=-k·Δx', content: '弹簧的弹力与形变量成正比，方向与形变方向相反。k 为劲度系数，单位 N/m。弹簧串联：1/k=1/k₁+1/k₂，并联：k=k₁+k₂。' },
        { title: '万有引力定律', formula: 'F=Gm₁m₂/r²', content: '任何两个物体之间都存在引力。G=6.67×10⁻¹¹ N·m²/kg²。重力加速度 g≈9.8m/s² 是地球引力的表现。' },
        { title: '动量守恒', formula: 'm₁v₁+m₂v₂=C', content: '系统不受外力或外力为零时总动量保持不变。碰撞、爆炸等过程遵循动量守恒。' },
        { title: '动能定理', formula: 'W=½mv²-½mv₀²', content: '合外力做功等于动能的变化量。功是能量转化的量度，单位：焦耳(J)。' },
        { title: '机械能守恒', formula: '½mv²+mgh=C', content: '只有重力或弹力做功时，动能与势能之和不变。这是能量守恒定律在力学中的体现。' }
      ]
    },
    {
      name: '电磁学', icon: '🧲', color: '#EF7060',
      cards: [
        { title: '库仑定律', formula: 'F=kq₁q₂/r²', content: '两个点电荷间的作用力与电荷量乘积成正比，与距离平方成反比。k=9×10⁹ N·m²/C²。' },
        { title: '电场强度', formula: 'E=F/q', content: '单位正电荷在电场中受到的力。点电荷电场：E=kQ/r²。匀强电场中 E=U/d。' },
        { title: '欧姆定律', formula: 'I=U/R', content: '导体中电流与电压成正比，与电阻成反比。电阻 R=ρL/S，与材料、长度、截面积有关。' },
        { title: '电功率', formula: 'P=UI=I²R', content: '电流做功的快慢。纯电阻电路：P=UI=I²R=U²/R。单位：瓦特(W)。' },
        { title: '焦耳定律', formula: 'Q=I²Rt', content: '电流通过导体产生的热量与电流平方、电阻和时间成正比。这是电流热效应的定量表达。' },
        { title: '左手定则', formula: 'F=BILsinθ', content: '磁场对通电导线的作用力方向：伸开左手，磁感线穿手心，四指指电流，拇指指安培力方向。' },
        { title: '法拉第电磁感应', formula: 'E=nΔΦ/Δt', content: '闭合电路中感应电动势与磁通量变化率成正比。这是发电机的原理，由法拉第于1831年发现。' }
      ]
    },
    {
      name: '热学', icon: '🔥', color: '#FFA726',
      cards: [
        { title: '热力学第一定律', formula: 'ΔU=Q-W', content: '系统内能变化 = 吸收热量 - 对外做功。这是能量守恒在热学中的表达。' },
        { title: '理想气体状态方程', formula: 'PV=nRT', content: '一定质量理想气体的压强、体积、温度满足 PV=nRT。R=8.31 J/(mol·K) 为普适气体常数。' },
        { title: '热机效率', formula: 'η=W/Q₁', content: '热机效率 = 输出功 / 吸收热量。卡诺热机最大效率 η=1-T₂/T₁（T 为热力学温度）。' },
        { title: '比热容', formula: 'Q=cmΔT', content: '物体吸收或放出的热量与质量、比热容、温度变化成正比。水的比热容 c=4.2×10³ J/(kg·℃)。' }
      ]
    },
    {
      name: '光学', icon: '💡', color: '#AB47BC',
      cards: [
        { title: '折射定律', formula: 'n₁sinθ₁=n₂sinθ₂', content: '光从一种介质进入另一种介质时，入射角与折射角满足斯涅尔定律。n 为折射率。' },
        { title: '全反射条件', formula: 'sinC=1/n', content: '光从光密介质射向光疏介质，入射角大于临界角 C 时发生全反射。光纤通信利用此原理。' },
        { title: '透镜公式', formula: '1/f=1/u+1/v', content: '薄透镜成像公式。u 为物距，v 为像距，f 为焦距。实像 v>0，虚像 v<0。' },
        { title: '光电效应方程', formula: 'hν=W+½mv²', content: '光子能量 = 逸出功 + 电子最大初动能。爱因斯坦因此获诺贝尔奖，证明了光的粒子性。' }
      ]
    },
    {
      name: '近代物理', icon: '⚛️', color: '#42A5F5',
      cards: [
        { title: '质能方程', formula: 'E=mc²', content: '物体的能量等于质量乘以光速的平方。c=3×10⁸ m/s。核反应中质量亏损转化为巨大能量。' },
        { title: '德布罗意波', formula: 'λ=h/p', content: '任何物质粒子都具有波动性。波长与动量成反比。h=6.63×10⁻³⁴ J·s 为普朗克常数。' },
        { title: '不确定原理', formula: 'Δx·Δp≥h/4π', content: '不能同时精确测定粒子的位置和动量。这是量子力学的基石，反映了微观世界的本质。' },
        { title: '玻尔模型', formula: 'Eₙ=-13.6/n² eV', content: '氢原子能级公式。电子在特定轨道上运动不辐射能量，跃迁时吸收或发射光子。' }
      ]
    }
  ];

  aboutToAppear(): void {
    this.loadDailyFact();
  }

  async loadDailyFact(): Promise<void> {
    try {
      const fact: PhysicsFact = await NetworkUtil.fetchPhysicsFact();
      this.dailyFact = fact.text;
      this.factSource = fact.source;
    } catch (e) {
      const fallback: PhysicsFact = NetworkUtil.getRandomLocalFact();
      this.dailyFact = fallback.text;
      this.factSource = fallback.source;
    }
  }

  build() {
    Column() {
      // 网络每日知识
      Row() {
        Text(this.dailyFact).fontSize(12).fontColor(Colors.TEXT_SECONDARY)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
        Text(this.factSource).fontSize(10).fontColor(Colors.TEXT_HINT).margin({ left: 4 })
      }
      .width('100%').padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor('rgba(102,126,234,0.06)').borderRadius(10)
      .margin({ left: 12, right: 12, top: 8, bottom: 4 })
      .onClick(() => { this.loadDailyFact(); })

      // 分类 Tab
      Scroll() {
        Row({ space: 6 }) {
          ForEach(this.categories, (cat: KnowledgeCategory, index: number) => {
            Button(cat.icon + ' ' + cat.name)
              .fontSize(12).height(30).borderRadius(15)
              .backgroundColor(this.currentCat === index ? cat.color : Colors.BORDER)
              .fontColor(this.currentCat === index ? Color.White : Colors.TEXT_SECONDARY)
              .padding({ left: 12, right: 12 })
              .onClick(() => { this.currentCat = index; })
          })
        }.padding({ left: 12, right: 12 })
      }
      .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      .width('100%').height(40).margin({ bottom: 8 })

      // 知识点卡片（用 Swiper 切换分类）
      Swiper() {
        ForEach(this.categories, (cat: KnowledgeCategory, _ci: number) => {
          Scroll() {
            Column({ space: 8 }) {
              ForEach(cat.cards, (card: KnowledgeCard) => {
                Column({ space: 6 }) {
                  Row() {
                    Text(card.title)
                      .fontSize(14).fontWeight(FontWeight.Bold).fontColor(Colors.TEXT_PRIMARY)
                      .layoutWeight(1)
                  }
                  Text(card.formula)
                    .fontSize(16).fontWeight(FontWeight.Bold).fontColor(cat.color)
                    .fontFamily('monospace')
                    .width('100%').textAlign(TextAlign.Center)
                    .padding({ top: 6, bottom: 6 })
                    .backgroundColor('rgba(0,0,0,0.02)').borderRadius(8)
                  Text(card.content)
                    .fontSize(12).fontColor(Colors.TEXT_SECONDARY).lineHeight(18)
                }
                .width('100%').padding(14)
                .backgroundColor(Colors.SURFACE).borderRadius(14)
                .border({ width: { left: 3 }, color: cat.color })
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 1 })
              })
            }.width('100%').padding({ left: 14, right: 14 })
          }
          .scrollBar(BarState.Off)
          .width('100%').height('100%')
        }, (_cat: KnowledgeCategory, index: number) => index.toString())
      }
      .index(this.currentCat)
      .onChange((index: number) => { this.currentCat = index; })
      .width('100%').layoutWeight(1)
      .indicator(Indicator.dot().color(Colors.BORDER).selectedColor(Colors.PRIMARY))
    }
    .width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }
}
