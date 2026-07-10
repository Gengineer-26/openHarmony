import http from '@ohos.net.http';
import { promptAction } from '@kit.ArkUI';

// ====== 网络数据模型 ======
export interface PhysicsFact {
  text: string;
  source: string;
}

// ====== 每日物理知识列表（本地备用数据） ======
const LOCAL_PHYSICS_FACTS: string[] = [
  '牛顿第一定律（惯性定律）：不受外力作用的物体将保持静止或匀速直线运动状态。',
  '牛顿第二定律：F = ma，物体的加速度与所受合力成正比，与质量成反比。',
  '牛顿第三定律：作用力与反作用力大小相等、方向相反，作用在不同物体上。',
  '胡克定律：F = -kx，弹簧的弹力与形变量成正比，方向与形变方向相反。',
  '万有引力定律：F = Gm₁m₂/r²，任何两个物体之间都存在相互吸引力。',
  '动量守恒：在没有外力作用的系统中，总动量保持不变。',
  '能量守恒：能量既不会凭空产生，也不会凭空消失，只能从一种形式转化为另一种形式。',
  '阿基米德原理：浸在液体中的物体受到向上的浮力，浮力等于物体排开液体的重力。',
  '帕斯卡原理：加在密闭液体上的压强，能够大小不变地由液体向各个方向传递。',
  '伯努利原理：流体流速大的地方压强小，流速小的地方压强大。',
  '库仑定律：F = kq₁q₂/r²，两个点电荷之间的作用力与电荷量乘积成正比。',
  '质能方程：E = mc²，物体的能量等于其质量乘以光速的平方。',
  '开普勒第一定律：行星绕太阳运行的轨道是椭圆，太阳位于椭圆的一个焦点上。',
  '热力学第一定律：ΔU = Q - W，系统内能的变化等于吸收的热量减去对外做的功。',
  '简谐运动：物体受到的回复力与位移成正比且方向相反时，物体做简谐运动。'
];

export class NetworkUtil {
  // ====== 从网络获取每日物理知识（高级功能） ======
  static async fetchPhysicsFact(): Promise<PhysicsFact> {
    const httpRequest = http.createHttp();
    try {
      // 使用一个免费的文字API获取随机名言
      const response = await httpRequest.request(
        'https://api.quotable.io/random?tags=science|technology',
        {
          method: http.RequestMethod.GET,
          connectTimeout: 5000,
          readTimeout: 5000,
          header: {
            'Content-Type': 'application/json'
          }
        }
      );

      if (response.responseCode === 200) {
        const result: string = response.result as string;
        const data = JSON.parse(result) as Record<string, Object>;
        const content: string = (data['content'] as string) || '';
        const author: string = (data['author'] as string) || '未知';
        return {
          text: '💡 ' + content,
          source: '—— ' + author
        };
      }
    } catch (err) {
      console.error('[NetworkUtil] HTTP request failed: ' + JSON.stringify(err));
    } finally {
      httpRequest.destroy();
    }

    // 网络失败时返回本地备用数据
    return NetworkUtil.getLocalFallbackFact();
  }

  // ====== 获取备用本地物理知识 ======
  static getLocalFallbackFact(): PhysicsFact {
    const idx: number = Math.floor(Math.random() * LOCAL_PHYSICS_FACTS.length);
    return {
      text: '💡 ' + LOCAL_PHYSICS_FACTS[idx],
      source: '—— 物理小知识'
    };
  }

  // ====== 获取随机本地物理知识（不依赖网络） ======
  static getRandomLocalFact(): PhysicsFact {
    return NetworkUtil.getLocalFallbackFact();
  }
}
