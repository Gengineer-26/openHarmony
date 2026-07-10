import { Point } from '../model/Types';
import { PhysicsConfig } from '../physics/PhysicsConfig';

export class CanvasUtils {
  // 像素坐标 → 世界坐标(米)
  static toWorld(screenX: number, screenY: number): Point {
    const result: Point = {
      x: screenX / PhysicsConfig.PIXELS_PER_METER,
      y: screenY / PhysicsConfig.PIXELS_PER_METER
    };
    return result;
  }

  // 世界坐标(米) → 像素坐标
  static toScreen(worldX: number, worldY: number): Point {
    const result: Point = {
      x: worldX * PhysicsConfig.PIXELS_PER_METER,
      y: worldY * PhysicsConfig.PIXELS_PER_METER
    };
    return result;
  }

  // 吸附世界坐标到网格交叉点（1格=1米）
  static snapToGridWorld(worldValue: number): number {
    return Math.round(worldValue);
  }

  // 吸附世界点坐标到网格交叉点
  static snapPointToGrid(worldPoint: Point): Point {
    return {
      x: Math.round(worldPoint.x),
      y: Math.round(worldPoint.y)
    };
  }

  // 吸附到最近的0.5增量（用于圆半径等）
  static snapToHalf(value: number): number {
    return Math.round(value * 2) / 2;
  }

  // 简化手绘路径
  static simplifyPath(points: Point[], tolerance: number): Point[] {
    if (points.length <= 2) {
      const copy: Point[] = [];
      for (const p of points) {
        const pt: Point = { x: p.x, y: p.y };
        copy.push(pt);
      }
      return copy;
    }
    const result: Point[] = [];
    const first: Point = { x: points[0].x, y: points[0].y };
    result.push(first);
    let last: Point = first;
    for (let i = 1; i < points.length; i++) {
      const dx: number = points[i].x - last.x;
      const dy: number = points[i].y - last.y;
      if (Math.sqrt(dx * dx + dy * dy) > tolerance) {
        const pt: Point = { x: points[i].x, y: points[i].y };
        result.push(pt);
        last = pt;
      }
    }
    return result;
  }
}
