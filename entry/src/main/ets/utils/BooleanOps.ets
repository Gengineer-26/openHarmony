import { Point } from '../model/Types';

/**
 * 2D多边形布尔运算工具类
 * - Sutherland-Hodgman: 求交/基础裁剪
 * - Bounding-box分解: 挖洞减法
 * - Andrew's Monotone Chain: 凸包
 * - Ear Clipping: 三角剖分
 */
export class BooleanOps {

  // ====== 求交 ======
  static intersect(subject: Point[], clip: Point[]): Point[] {
    return BooleanOps.sutherlandHodgman(subject, clip, true);
  }

  // ====== 减法 A-B ======
  static subtract(subject: Point[], clip: Point[]): Point[][] {
    // 先检测clip是否完全在subject内部（挖洞情况）
    const clipInSubject: boolean = BooleanOps.isPolygonInsideOther(clip, subject);

    if (clipInSubject) {
      // 挖洞：clip完全在subject内部，用包围盒分解
      return BooleanOps.decomposeDonut(subject, clip);
    }

    // 检测subject是否完全在clip内部（全删）
    const subjectInClip: boolean = BooleanOps.isPolygonInsideOther(subject, clip);
    if (subjectInClip) {
      return [];
    }

    // 部分重叠：使用Sutherland-Hodgman
    const result: Point[] = BooleanOps.sutherlandHodgman(subject, clip, false);
    if (result.length < 3) {
      // S-H结果为空或无重叠 → 返回原subject
      if (BooleanOps.intersect(subject, clip).length < 3) {
        return [subject];
      }
      return [];
    }
    return BooleanOps.decomposeToConvex(result);
  }

  // ====== 并集 ======
  static union(A: Point[], B: Point[]): Point[][] {
    const intersectResult: Point[] = BooleanOps.intersect(A, B);
    if (intersectResult.length < 3) {
      return [A, B];
    }
    const allVerts: Point[] = [];
    for (const v of A) {
      const pt: Point = { x: v.x, y: v.y };
      allVerts.push(pt);
    }
    for (const v of B) {
      const pt: Point = { x: v.x, y: v.y };
      allVerts.push(pt);
    }
    const hull: Point[] = BooleanOps.convexHull(allVerts);
    if (hull.length <= 8) {
      return [hull];
    }
    return BooleanOps.decomposeToConvex(hull);
  }

  // ====== 检查poly是否在container内部 ======
  private static isPolygonInsideOther(inner: Point[], outer: Point[]): boolean {
    for (const p of inner) {
      if (!BooleanOps.isPointInConvexPolygon(p, outer)) {
        return false;
      }
    }
    return true;
  }

  // ====== 点在凸多边形内 ======
  private static isPointInConvexPolygon(p: Point, poly: Point[]): boolean {
    const n: number = poly.length;
    for (let i: number = 0; i < n; i++) {
      const edgeStart: Point = poly[i];
      const edgeEnd: Point = poly[(i + 1) % n];
      const cross: number = (edgeEnd.x - edgeStart.x) * (p.y - edgeStart.y) -
        (edgeEnd.y - edgeStart.y) * (p.x - edgeStart.x);
      if (cross < -0.0001) {
        return false;
      }
    }
    return true;
  }

  // ====== 挖洞分解：把A切成环绕B的多块，每块用S-H减掉B ======
  private static decomposeDonut(subject: Point[], clip: Point[]): Point[][] {
    // 计算包围盒，clip盒向内收缩到90%（确保strip有面积）
    const subBox: BoundingBox = BooleanOps.getBoundingBox(subject);
    const rawClipBox: BoundingBox = BooleanOps.getBoundingBox(clip);
    const cx: number = (rawClipBox.minX + rawClipBox.maxX) / 2;
    const cy: number = (rawClipBox.minY + rawClipBox.maxY) / 2;
    const hw: number = (rawClipBox.maxX - rawClipBox.minX) / 2 * 0.85;
    const hh: number = (rawClipBox.maxY - rawClipBox.minY) / 2 * 0.85;
    const inner: BoundingBox = {
      minX: cx - hw, maxX: cx + hw,
      minY: cy - hh, maxY: cy + hh
    };

    // 构建4个strip矩形
    const strips: Point[][] = [];

    // 顶条
    if (subBox.maxY > inner.minY) {
      const y0: number = Math.max(subBox.minY, inner.minY);
      if (subBox.maxY > y0 + 0.01) {
        const s: Point[] = [];
        const p0: Point = { x: subBox.minX, y: y0 };
        const p1: Point = { x: subBox.maxX, y: y0 };
        const p2: Point = { x: subBox.maxX, y: subBox.maxY };
        const p3: Point = { x: subBox.minX, y: subBox.maxY };
        s.push(p0); s.push(p1); s.push(p2); s.push(p3);
        strips.push(s);
      }
    }

    // 底条
    if (subBox.minY < inner.maxY) {
      const y1: number = Math.min(subBox.maxY, inner.maxY);
      if (y1 > subBox.minY + 0.01) {
        const s: Point[] = [];
        const p0: Point = { x: subBox.minX, y: subBox.minY };
        const p1: Point = { x: subBox.maxX, y: subBox.minY };
        const p2: Point = { x: subBox.maxX, y: y1 };
        const p3: Point = { x: subBox.minX, y: y1 };
        s.push(p0); s.push(p1); s.push(p2); s.push(p3);
        strips.push(s);
      }
    }

    // 左条（中间段）
    if (subBox.minX < inner.minX) {
      const y0: number = Math.max(subBox.minY, inner.minY);
      const y1: number = Math.min(subBox.maxY, inner.maxY);
      if (y1 > y0 + 0.01 && inner.minX > subBox.minX + 0.01) {
        const s: Point[] = [];
        const p0: Point = { x: subBox.minX, y: y0 };
        const p1: Point = { x: inner.minX, y: y0 };
        const p2: Point = { x: inner.minX, y: y1 };
        const p3: Point = { x: subBox.minX, y: y1 };
        s.push(p0); s.push(p1); s.push(p2); s.push(p3);
        strips.push(s);
      }
    }

    // 右条（中间段）
    if (subBox.maxX > inner.maxX) {
      const y0: number = Math.max(subBox.minY, inner.minY);
      const y1: number = Math.min(subBox.maxY, inner.maxY);
      if (y1 > y0 + 0.01 && subBox.maxX > inner.maxX + 0.01) {
        const s: Point[] = [];
        const p0: Point = { x: inner.maxX, y: y0 };
        const p1: Point = { x: subBox.maxX, y: y0 };
        const p2: Point = { x: subBox.maxX, y: y1 };
        const p3: Point = { x: inner.maxX, y: y1 };
        s.push(p0); s.push(p1); s.push(p2); s.push(p3);
        strips.push(s);
      }
    }

    // 对每条strip：先与subject求交，再减去clip
    const result: Point[][] = [];
    for (const strip of strips) {
      // 限制在subject范围内
      const inSubject: Point[] = BooleanOps.sutherlandHodgman(strip, subject, true);
      if (inSubject.length < 3) continue;
      // 减去clip（strip与clip是部分重叠，S-H可正确处理）
      const minusClip: Point[] = BooleanOps.sutherlandHodgman(inSubject, clip, false);
      if (minusClip.length >= 3) {
        const convexParts: Point[][] = BooleanOps.decomposeToConvex(minusClip);
        for (const cp of convexParts) {
          result.push(cp);
        }
      }
    }

    // 如果strips方案没有得到结果，回退到全部S-H
    if (result.length === 0) {
      const fallback: Point[] = BooleanOps.sutherlandHodgman(subject, clip, false);
      if (fallback.length >= 3) {
        return BooleanOps.decomposeToConvex(fallback);
      }
    }

    return result;
  }

  // ====== 用凸多边形裁剪多边形（求交） ======
  private static clipPolyByConvex(poly: Point[], convexClip: Point[]): Point[] {
    return BooleanOps.sutherlandHodgman(poly, convexClip, true);
  }

  // ====== 包围盒 ======
  private static getBoundingBox(poly: Point[]): BoundingBox {
    let minX: number = poly[0].x;
    let maxX: number = poly[0].x;
    let minY: number = poly[0].y;
    let maxY: number = poly[0].y;
    for (const p of poly) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    const box: BoundingBox = { minX: minX, maxX: maxX, minY: minY, maxY: maxY };
    return box;
  }

  // ====== Sutherland-Hodgman ======
  private static sutherlandHodgman(subject: Point[], clip: Point[], keepInside: boolean): Point[] {
    let output: Point[] = [];
    for (const p of subject) {
      const pt: Point = { x: p.x, y: p.y };
      output.push(pt);
    }
    for (let i: number = 0; i < clip.length; i++) {
      const edgeStart: Point = clip[i];
      const edgeEnd: Point = clip[(i + 1) % clip.length];
      const input: Point[] = output;
      output = [];
      if (input.length === 0) break;

      for (let j: number = 0; j < input.length; j++) {
        const current: Point = input[j];
        const previous: Point = input[(j + input.length - 1) % input.length];
        const currInside: boolean = BooleanOps.isInside(current, edgeStart, edgeEnd, keepInside);
        const prevInside: boolean = BooleanOps.isInside(previous, edgeStart, edgeEnd, keepInside);

        if (currInside) {
          if (!prevInside) {
            const pt: Point = BooleanOps.lineIntersect(previous, current, edgeStart, edgeEnd);
            output.push(pt);
          }
          output.push(current);
        } else if (prevInside) {
          const pt: Point = BooleanOps.lineIntersect(previous, current, edgeStart, edgeEnd);
          output.push(pt);
        }
      }
    }
    return output;
  }

  private static isInside(p: Point, edgeStart: Point, edgeEnd: Point, keepInside: boolean): boolean {
    const cross: number = (edgeEnd.x - edgeStart.x) * (p.y - edgeStart.y) -
      (edgeEnd.y - edgeStart.y) * (p.x - edgeStart.x);
    return keepInside ? (cross >= -0.0001) : (cross <= 0.0001);
  }

  private static lineIntersect(p1: Point, p2: Point, p3: Point, p4: Point): Point {
    const d1x: number = p2.x - p1.x;
    const d1y: number = p2.y - p1.y;
    const d2x: number = p4.x - p3.x;
    const d2y: number = p4.y - p3.y;
    const denom: number = d1x * d2y - d1y * d2x;
    if (Math.abs(denom) < 0.00001) {
      const result: Point = { x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2 };
      return result;
    }
    const t: number = ((p3.x - p1.x) * d2y - (p3.y - p1.y) * d2x) / denom;
    const result: Point = { x: p1.x + t * d1x, y: p1.y + t * d1y };
    return result;
  }

  // ====== 凸包(Andrew's Monotone Chain) ======
  static convexHull(points: Point[]): Point[] {
    if (points.length <= 3) {
      const result: Point[] = [];
      for (const p of points) {
        const pt: Point = { x: p.x, y: p.y };
        result.push(pt);
      }
      return result;
    }
    const sorted: Point[] = [...points].sort((a, b) => {
      if (Math.abs(a.x - b.x) > 0.0001) return a.x - b.x;
      return a.y - b.y;
    });
    const lower: Point[] = [];
    for (const p of sorted) {
      while (lower.length >= 2) {
        const crossVal: number = BooleanOps.crossProd(lower[lower.length - 2], lower[lower.length - 1], p);
        if (crossVal > 0.0001) break;
        lower.pop();
      }
      lower.push(p);
    }
    const upper: Point[] = [];
    for (let i: number = sorted.length - 1; i >= 0; i--) {
      const p: Point = sorted[i];
      while (upper.length >= 2) {
        const crossVal: number = BooleanOps.crossProd(upper[upper.length - 2], upper[upper.length - 1], p);
        if (crossVal > 0.0001) break;
        upper.pop();
      }
      upper.push(p);
    }
    lower.pop();
    upper.pop();
    return lower.concat(upper);
  }

  private static crossProd(o: Point, a: Point, b: Point): number {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  }

  // ====== 凸分解 ======
  static decomposeToConvex(polygon: Point[]): Point[][] {
    if (polygon.length < 3) return [];
    if (polygon.length <= 8 && BooleanOps.isConvex(polygon)) {
      return [polygon];
    }
    const triangles: Point[][] = BooleanOps.earClip(polygon);
    if (triangles.length === 0) return [polygon]; // fallback
    return BooleanOps.mergeTriangles(triangles);
  }

  static isConvex(polygon: Point[]): boolean {
    if (polygon.length < 3) return false;
    let sign: number = 0;
    for (let i: number = 0; i < polygon.length; i++) {
      const p0: Point = polygon[i];
      const p1: Point = polygon[(i + 1) % polygon.length];
      const p2: Point = polygon[(i + 2) % polygon.length];
      const c: number = (p1.x - p0.x) * (p2.y - p1.y) - (p1.y - p0.y) * (p2.x - p1.x);
      if (Math.abs(c) > 0.0001) {
        const s: number = c > 0 ? 1 : -1;
        if (sign === 0) sign = s;
        else if (s !== sign) return false;
      }
    }
    return true;
  }

  // ====== Ear Clipping ======
  private static earClip(polygon: Point[]): Point[][] {
    const verts: Point[] = [];
    for (const v of polygon) {
      const pt: Point = { x: v.x, y: v.y };
      verts.push(pt);
    }
    const triangles: Point[][] = [];
    let index: number = 0;
    const maxIter: number = verts.length * 3;
    for (let iter: number = 0; iter < maxIter && verts.length >= 3; iter++) {
      const n: number = verts.length;
      const i0: number = index % n;
      const i1: number = (i0 + 1) % n;
      const i2: number = (i0 + 2) % n;
      const a: Point = verts[i0];
      const b: Point = verts[i1];
      const c: Point = verts[i2];
      if (BooleanOps.isEar(verts, i0, i1, i2)) {
        const t: Point[] = [];
        const ta: Point = { x: a.x, y: a.y };
        const tb: Point = { x: b.x, y: b.y };
        const tc: Point = { x: c.x, y: c.y };
        t.push(ta); t.push(tb); t.push(tc);
        triangles.push(t);
        verts.splice(i1, 1);
        index = 0;
      } else {
        index++;
        if (index >= n) break;
      }
    }
    return triangles;
  }

  private static isEar(verts: Point[], i0: number, i1: number, i2: number): boolean {
    const a: Point = verts[i0];
    const b: Point = verts[i1];
    const c: Point = verts[i2];
    if (BooleanOps.crossProd(a, b, c) <= 0.0001) return false;
    for (let i: number = 0; i < verts.length; i++) {
      if (i === i0 || i === i1 || i === i2) continue;
      if (BooleanOps.pointInTriangle(verts[i], a, b, c)) return false;
    }
    return true;
  }

  private static pointInTriangle(p: Point, a: Point, b: Point, c: Point): boolean {
    const d1: number = BooleanOps.sign(p, a, b);
    const d2: number = BooleanOps.sign(p, b, c);
    const d3: number = BooleanOps.sign(p, c, a);
    const hasNeg: boolean = (d1 < 0) || (d2 < 0) || (d3 < 0);
    const hasPos: boolean = (d1 > 0) || (d2 > 0) || (d3 > 0);
    return !(hasNeg && hasPos);
  }

  private static sign(p1: Point, p2: Point, p3: Point): number {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
  }

  // ====== 合并三角形 ======
  private static mergeTriangles(triangles: Point[][]): Point[][] {
    if (triangles.length === 0) return [];
    if (triangles.length === 1) return [triangles[0]];
    const parts: Point[][] = [triangles[0]];
    for (let i: number = 1; i < triangles.length; i++) {
      const last: Point[] = parts[parts.length - 1];
      const merged: Point[] | null = BooleanOps.tryMerge(last, triangles[i]);
      if (merged !== null && merged.length <= 8) {
        parts[parts.length - 1] = merged;
      } else {
        parts.push(triangles[i]);
      }
    }
    const result: Point[][] = [];
    for (const part of parts) {
      if (part.length > 8) {
        const sub: Point[][] = BooleanOps.splitPolygon(part);
        for (const s of sub) result.push(s);
      } else {
        result.push(part);
      }
    }
    return result;
  }

  private static tryMerge(a: Point[], b: Point[]): Point[] | null {
    const all: Point[] = [];
    for (const v of a) {
      const pt: Point = { x: v.x, y: v.y };
      all.push(pt);
    }
    for (const v of b) {
      const pt: Point = { x: v.x, y: v.y };
      all.push(pt);
    }
    const hull: Point[] = BooleanOps.convexHull(all);
    if (hull.length <= 8 && BooleanOps.isConvex(hull)) return hull;
    return null;
  }

  private static splitPolygon(polygon: Point[]): Point[][] {
    const mid: number = Math.floor(polygon.length / 2);
    const part1: Point[] = polygon.slice(0, mid + 1);
    const part2: Point[] = [];
    const first: Point = { x: polygon[0].x, y: polygon[0].y };
    part2.push(first);
    const rest: Point[] = polygon.slice(mid);
    for (const v of rest) {
      const pt: Point = { x: v.x, y: v.y };
      part2.push(pt);
    }
    const result: Point[][] = [];
    if (part1.length >= 3 && part1.length <= 8) result.push(part1);
    else if (part1.length > 8) {
      const sub: Point[][] = BooleanOps.splitPolygon(part1);
      for (const s of sub) result.push(s);
    }
    if (part2.length >= 3 && part2.length <= 8) result.push(part2);
    else if (part2.length > 8) {
      const sub: Point[][] = BooleanOps.splitPolygon(part2);
      for (const s of sub) result.push(s);
    }
    return result;
  }
}

// 包围盒
interface BoundingBox {
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
}
