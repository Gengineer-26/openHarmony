import { PhysicsWorld, JointInfo } from '../physics/PhysicsWorld';
import { PhysicsConfig } from '../physics/PhysicsConfig';
import { Colors, Defaults } from '../common/Constants';
import { CanvasUtils } from '../utils/CanvasUtils';
import { BooleanOps } from '../utils/BooleanOps';
import {
  EditorTool, BodyDef, BodyShapeType, BodyDynamicsType,
  Point, PanOffset, BodyInfo, BodyRuntimeData, PropertyChange,
  BooleanOpType, BooleanOpRequest, JointDef, JointType, SceneImportData
} from '../model/Types';
import * as box2d from '@ohos/box2d';

interface CreateState {
  active: boolean;
  startX: number;
  startY: number;
  currentX: number;
  currentY: number;
  snappedStartWX: number;
  snappedStartWY: number;
}

interface BodyRenderItem {
  body: box2d.b2Body;
  id: string;
  area: number;
}

interface TwoPointState {
  active: boolean;
  firstId: string;
  firstX: number;
  firstY: number;
  firstIsBody: boolean;
  snappedFirstX: number;
  snappedFirstY: number;
}

@Component
export struct PhysicsCanvas {
  @Link isRunning: boolean;
  @Link gravityX: number;
  @Link gravityY: number;
  @Link simulationSpeed: number;
  @Link showTrajectory: boolean;
  @Link showGrid: boolean;
  @Link bodyCount: number;
  @Link selectedBodyId: string;
  @Prop currentTool: number = EditorTool.CIRCLE;
  @Prop @Watch('onClearTrigger') clearTrigger: number = 0;
  @Prop @Watch('onPendingProperty') pendingProperty: PropertyChange | null = null;
  @Prop @Watch('onBooleanOp') booleanOpRequest: BooleanOpRequest | null = null;
  @Prop @Watch('onSceneExportTrigger') sceneExportTrigger: number = 0;
  @Prop @Watch('onSceneImport') sceneImportData: SceneImportData | null = null;

  onBodySelected?: (id: string) => void;
  onBodyDeselected?: () => void;
  onBodyInfoReady?: (info: BodyInfo) => void;
  onTwoBodiesSelected?: (idA: string, idB: string) => void;
  onRequestToolSwitch?: (tool: number) => void;
  onExportSceneData?: (bodyDefs: BodyDef[], jointDefs: JointDef[]) => void;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private world: PhysicsWorld = new PhysicsWorld(Defaults.GRAVITY_X, Defaults.GRAVITY_Y);

  private panOffset: PanOffset = { x: 0, y: 0 };
  private canvasScale: number = 1.0;
  private canvasW: number = 800;
  private canvasH: number = 600;
  private frameTimer: number = -1;
  private trajectories: Map<string, Point[]> = new Map();
  private createState: CreateState = {
    active: false, startX: 0, startY: 0, currentX: 0, currentY: 0,
    snappedStartWX: 0, snappedStartWY: 0
  };
  private twoPoint: TwoPointState = {
    active: false, firstId: '', firstX: 0, firstY: 0, firstIsBody: false,
    snappedFirstX: 0, snappedFirstY: 0
  };
  private selectedBodyIds: string[] = [];
  private trianglePoints: Point[] = [];
  private lastMouseSX: number = 0;
  private lastMouseSY: number = 0;
  private dragMovingBody: boolean = false;
  private moveBodyStartWX: number = 0;
  private moveBodyStartWY: number = 0;

  aboutToAppear(): void { this.world.setGravity(this.gravityX, this.gravityY); }
  aboutToDisappear(): void { if (this.frameTimer !== -1) { clearInterval(this.frameTimer); this.frameTimer = -1; } }
  startLoop(): void { this.frameTimer = setInterval(() => { this.renderFrame(); }, 16); }

  onClearTrigger(): void {
    this.world.clearAll();
    this.trajectories.clear();
    this.createState.active = false;
    this.twoPoint.active = false;
    this.twoPoint.firstId = '';
    this.selectedBodyId = '';
    this.selectedBodyIds = [];
    this.trianglePoints = [];
    this.bodyCount = 0;
  }

  onPendingProperty(): void {
    if (this.pendingProperty !== null && this.pendingProperty.id !== '') {
      this.applyPropertyChange(this.pendingProperty.id, this.pendingProperty.key, this.pendingProperty.value);
    }
  }

  onBooleanOp(): void {
    if (this.booleanOpRequest !== null && this.booleanOpRequest.idA !== '' && this.booleanOpRequest.idB !== '') {
      const opType: BooleanOpType = this.booleanOpRequest.opType as BooleanOpType;
      this.performBooleanOp(opType, this.booleanOpRequest.idA, this.booleanOpRequest.idB);
    }
  }

  onSceneExportTrigger(): void {
    if (this.sceneExportTrigger > 0 && this.onExportSceneData) {
      const bodyDefs: BodyDef[] = this.world.exportAllBodyDefs();
      const jointDefs: JointDef[] = this.world.exportAllJointDefs();
      this.onExportSceneData(bodyDefs, jointDefs);
    }
  }

  onSceneImport(): void {
    if (this.sceneImportData !== null && this.sceneImportData.bodies.length > 0) {
      this.importBodiesAndJoints(this.sceneImportData.bodies, this.sceneImportData.joints);
    }
  }

  private importBodiesAndJoints(bodies: BodyDef[], joints: JointDef[]): void {
    // 清空现有物体
    this.world.clearAll();
    this.trajectories.clear();
    this.selectedBodyId = '';
    this.selectedBodyIds = [];

    // 重新创建所有物体——用 String() 转成纯字符串比较，避免 ArkTS enum 比较问题
    for (const def of bodies) {
      const st: string = (def.shapeType as string).toString();
      if (st === 'circle') {
        this.world.createCircle(def.x, def.y, def.radius, def);
      } else if (st === 'triangle') {
        this.world.createTriangle(def.x, def.y, def.width, def.height, def);
      } else {
        // rectangle / polygon 统一用 rect 重建
        this.world.createRect(def.x, def.y, def.width, def.height, def);
      }
    }

    // 重新创建所有关节
    for (const jd of joints) {
      const jt: string = (jd.type as string).toString();
      if (jt === 'spring' || jt === 'distance') {
        this.world.createDistanceJoint(jd.bodyAId, jd.bodyBId, jd.length, jd.stiffness, jd.damping);
      } else if (jt === 'rope') {
        this.world.createRopeJoint(jd.bodyAId, jd.bodyBId, jd.maxLength);
      } else if (jt === 'revolute') {
        this.world.createRevoluteJoint(jd.bodyAId, jd.bodyBId, jd.anchorX, jd.anchorY);
      } else if (jt === 'weld') {
        this.world.createWeldJoint(jd.bodyAId, jd.bodyBId);
      }
    }

    this.world.syncNextBodyId();
    this.bodyCount = this.world.getBodyCount();
  }

  performBooleanOp(opType: BooleanOpType, idA: string, idB: string): void {
    const bodyA: box2d.b2Body | undefined = this.world.getBody(idA);
    const bodyB: box2d.b2Body | undefined = this.world.getBody(idB);
    if (bodyA === undefined || bodyB === undefined) return;

    const vertsA: Point[] = this.getBodyVerticesWorld(bodyA);
    const vertsB: Point[] = this.getBodyVerticesWorld(bodyB);

    if (vertsA.length < 3 || vertsB.length < 3) return;

    let resultPolygons: Point[][];

    switch (opType) {
      case BooleanOpType.INTERSECT: {
        const result: Point[] = BooleanOps.intersect(vertsA, vertsB);
        resultPolygons = BooleanOps.decomposeToConvex(result);
        break;
      }
      case BooleanOpType.SUBTRACT: {
        resultPolygons = BooleanOps.subtract(vertsA, vertsB);
        break;
      }
      case BooleanOpType.UNION: {
        resultPolygons = BooleanOps.union(vertsA, vertsB);
        break;
      }
      default:
        return;
    }

    if (resultPolygons.length === 0) {
      this.world.removeBody(idA);
      this.world.removeBody(idB);
      this.trajectories.delete(idA);
      this.trajectories.delete(idB);
      this.bodyCount = this.world.getBodyCount();
      this.selectedBodyId = '';
      this.selectedBodyIds = [];
      return;
    }

    const udA: BodyRuntimeData | undefined = this.world.getBodyRuntimeData(idA);
    const resultColor: string = udA?.color ?? Colors.BODY_RECTANGLE;
    const resultFriction: number = udA?.friction ?? Defaults.FRICTION;
    const resultRestitution: number = udA?.restitution ?? Defaults.RESTITUTION;
    const resultDensity: number = Defaults.DENSITY;

    this.world.removeBody(idA);
    this.world.removeBody(idB);
    this.trajectories.delete(idA);
    this.trajectories.delete(idB);

    const resultIds: string[] = [];
    for (const poly of resultPolygons) {
      if (poly.length >= 3) {
        const newId: string = this.world.genBodyId();
        const def: BodyDef = this.makeBodyDef(
          newId, BodyShapeType.POLYGON, false, 0, 0, 0, 0, 0, resultColor
        );
        def.friction = resultFriction;
        def.restitution = resultRestitution;
        def.density = resultDensity;
        this.world.createPolygonBody(poly, def);
        resultIds.push(newId);
      }
    }

    this.bodyCount = this.world.getBodyCount();
    this.selectedBodyId = '';
    this.selectedBodyIds = [];

    if (resultIds.length === 1) {
      this.selectedBodyId = resultIds[0];
      const info: BodyInfo | null = this.buildBodyInfo(resultIds[0]);
      if (info !== null) this.onBodyInfoReady?.(info);
    }
  }

  private getBodyVerticesWorld(body: box2d.b2Body): Point[] {
    const fixture: box2d.b2Fixture | null = body.GetFixtureList();
    if (fixture === null) return [];
    const shape: box2d.b2Shape = fixture.GetShape();
    const shapeType: box2d.b2ShapeType = shape.GetType();
    const pos: box2d.b2Vec2 = body.GetPosition();
    const angle: number = body.GetAngle();
    const cos: number = Math.cos(angle);
    const sin: number = Math.sin(angle);

    if (shapeType === box2d.b2ShapeType.e_polygonShape) {
      const poly: box2d.b2PolygonShape = shape as box2d.b2PolygonShape;
      const verts: Point[] = [];
      for (let i: number = 0; i < poly.m_count; i++) {
        const lx: number = poly.m_vertices[i].x;
        const ly: number = poly.m_vertices[i].y;
        const pt: Point = { x: pos.x + cos * lx - sin * ly, y: pos.y + sin * lx + cos * ly };
        verts.push(pt);
      }
      return verts;
    }

    if (shapeType === box2d.b2ShapeType.e_circleShape) {
      const circle: box2d.b2CircleShape = shape as box2d.b2CircleShape;
      const r: number = circle.m_radius;
      const segments: number = 8;
      const verts: Point[] = [];
      for (let i: number = 0; i < segments; i++) {
        const a: number = (i / segments) * Math.PI * 2;
        const pt: Point = { x: pos.x + Math.cos(a) * r, y: pos.y + Math.sin(a) * r };
        verts.push(pt);
      }
      return verts;
    }
    return [];
  }

  private findBodyAtGridPoint(worldPoint: Point): string | null {
    let foundId: string | null = null;
    const testVec: box2d.b2Vec2 = new box2d.b2Vec2(worldPoint.x, worldPoint.y);

    this.world.forEachBody((body: box2d.b2Body, id: string) => {
      if (foundId !== null) return;
      if (id.startsWith('node_') || id.startsWith('anchor_')) return;
      const fixture: box2d.b2Fixture | null = body.GetFixtureList();
      if (fixture !== null) {
        let f: box2d.b2Fixture | null = fixture;
        while (f !== null) {
          if (f.TestPoint(testVec)) {
            foundId = id;
            return;
          }
          f = f.GetNext();
        }
      }
    });
    return foundId;
  }

  private readonly WORLD_HALF: number = 50;

  private clampPanOffset(): void {
    const ppm: number = PhysicsConfig.PIXELS_PER_METER * this.canvasScale;
    const worldPx: number = this.WORLD_HALF * ppm;
    if (this.panOffset.x < this.canvasW - worldPx) this.panOffset.x = this.canvasW - worldPx;
    if (this.panOffset.x > worldPx) this.panOffset.x = worldPx;
    if (this.panOffset.y < this.canvasH - worldPx) this.panOffset.y = this.canvasH - worldPx;
    if (this.panOffset.y > worldPx) this.panOffset.y = worldPx;
    if (this.canvasW > worldPx * 2) this.panOffset.x = (this.canvasW - worldPx * 2) / 2;
    if (this.canvasH > worldPx * 2) this.panOffset.y = (this.canvasH - worldPx * 2) / 2;
  }

  private cleanOutOfBounds(): void {
    const limit: number = this.WORLD_HALF;
    const toRemove: string[] = [];
    this.world.forEachBody((body: box2d.b2Body, id: string) => {
      const pos: box2d.b2Vec2 = body.GetPosition();
      if (Math.abs(pos.x) > limit || Math.abs(pos.y) > limit || pos.y < -limit) {
        toRemove.push(id);
      }
    });
    for (const id of toRemove) {
      this.world.removeBody(id);
      this.trajectories.delete(id);
      if (this.selectedBodyId === id) this.selectedBodyId = '';
      const idx: number = this.selectedBodyIds.indexOf(id);
      if (idx >= 0) this.selectedBodyIds.splice(idx, 1);
    }
    if (toRemove.length > 0) {
      this.bodyCount = this.world.getBodyCount();
    }
  }

  private toWorldX(sx: number): number {
    return (sx - this.panOffset.x) / (this.canvasScale * PhysicsConfig.PIXELS_PER_METER);
  }
  private toWorldY(sy: number): number {
    return (sy - this.panOffset.y) / (this.canvasScale * PhysicsConfig.PIXELS_PER_METER);
  }

  build() {
    Stack() {
      Canvas(this.ctx)
        .width('100%').height('100%')
        .onReady(() => this.startLoop())
        .onAreaChange((_old: Area, newArea: Area) => {
          this.canvasW = newArea.width as number;
          this.canvasH = newArea.height as number;
          // 固定视图：世界(0,0)映射到屏幕水平居中、上方75%处
          this.canvasScale = 1.0;
          this.panOffset.x = this.canvasW / 2;
          this.panOffset.y = this.canvasH * 0.75;
        })
        .onTouch((event: TouchEvent) => this.handleTouch(event))
    }
    .clip(true)
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)' })
    .layoutWeight(1)
    .backgroundColor(Colors.CANVAS_BG)
  }

  handleTouch(event: TouchEvent): void {
    if (event.touches.length === 0) return;
    const sx: number = event.touches[0].x;
    const sy: number = event.touches[0].y;
    const wx: number = this.toWorldX(sx);
    const wy: number = this.toWorldY(sy);

    const isCreationTool: boolean = (
      this.currentTool === EditorTool.CIRCLE ||
      this.currentTool === EditorTool.RECTANGLE ||
      this.currentTool === EditorTool.TRIANGLE ||
      this.currentTool === EditorTool.SPRING ||
      this.currentTool === EditorTool.ROPE ||
      this.currentTool === EditorTool.ANCHOR ||
      this.currentTool === EditorTool.ERASER
    );
    if (this.isRunning && isCreationTool) {
      if (this.currentTool !== EditorTool.SELECT && this.currentTool !== EditorTool.ERASER) {
        return;
      }
    }

    if (this.currentTool === EditorTool.TRIANGLE) {
      if (event.type === TouchType.Move) {
        this.lastMouseSX = sx;
        this.lastMouseSY = sy;
      }
      if (event.type === TouchType.Up) {
        const snapped: Point = CanvasUtils.snapPointToGrid({ x: wx, y: wy });
        this.trianglePoints.push(snapped);

        if (this.trianglePoints.length === 3) {
          this.finishTriangleCreate();
          this.trianglePoints = [];
        }
      }
      return;
    }

    const isDragCreate: boolean = (
      this.currentTool === EditorTool.CIRCLE ||
      this.currentTool === EditorTool.RECTANGLE
    );

    if (isDragCreate) {
      if (event.type === TouchType.Down) {
        const snapped: Point = CanvasUtils.snapPointToGrid({ x: wx, y: wy });
        this.createState.active = true;
        this.createState.startX = sx;
        this.createState.startY = sy;
        this.createState.currentX = sx;
        this.createState.currentY = sy;
        this.createState.snappedStartWX = snapped.x;
        this.createState.snappedStartWY = snapped.y;
      } else if (event.type === TouchType.Move && this.createState.active) {
        this.createState.currentX = sx;
        this.createState.currentY = sy;
      } else if (event.type === TouchType.Up && this.createState.active) {
        this.finishDragCreate(wx, wy);
        this.createState.active = false;
      }
      return;
    }

    if (event.type === TouchType.Up &&
      (this.currentTool === EditorTool.SPRING || this.currentTool === EditorTool.ROPE)) {
      const snapped: Point = CanvasUtils.snapPointToGrid({ x: wx, y: wy });
      const hitId: string | null = this.findBodyAtGridPoint(snapped);

      if (!this.twoPoint.active) {
        if (hitId !== null) {
          this.twoPoint.firstId = hitId;
          this.twoPoint.firstIsBody = true;
        } else {
          const nodeId: string = this.world.createSmallNode(snapped.x, snapped.y);
          this.twoPoint.firstId = nodeId;
          this.twoPoint.firstIsBody = false;
        }
        this.twoPoint.firstX = wx;
        this.twoPoint.firstY = wy;
        this.twoPoint.snappedFirstX = snapped.x;
        this.twoPoint.snappedFirstY = snapped.y;
        this.twoPoint.active = true;
      } else {
        let secondId: string = '';
        if (hitId !== null && hitId !== this.twoPoint.firstId) {
          secondId = hitId;
        } else if (hitId === this.twoPoint.firstId) {
          secondId = this.world.createSmallNode(snapped.x, snapped.y);
        } else {
          secondId = this.world.createSmallNode(snapped.x, snapped.y);
        }

        const dist: number = Math.sqrt(
          (snapped.x - this.twoPoint.snappedFirstX) * (snapped.x - this.twoPoint.snappedFirstX) +
          (snapped.y - this.twoPoint.snappedFirstY) * (snapped.y - this.twoPoint.snappedFirstY)
        );

        if (this.currentTool === EditorTool.SPRING) {
          this.world.createDistanceJoint(
            this.twoPoint.firstId, secondId, dist,
            Defaults.SPRING_STIFFNESS, 0.3
          );
        } else {
          this.world.createRopeJoint(this.twoPoint.firstId, secondId, dist);
        }

        this.bodyCount = this.world.getBodyCount();
        this.twoPoint.active = false;
        this.twoPoint.firstId = '';
      }
      return;
    }

    if (this.currentTool === EditorTool.SELECT) {
      if (event.type === TouchType.Down) {
        const hitId: string | null = this.world.queryPoint(wx, wy);
        if (hitId !== null && !this.isRunning) {
          this.dragMovingBody = true;
          const hitBody: box2d.b2Body | undefined = this.world.getBody(hitId);
          if (hitBody !== undefined) {
            const hitPos: box2d.b2Vec2 = hitBody.GetPosition();
            this.moveBodyStartWX = hitPos.x;
            this.moveBodyStartWY = hitPos.y;
          }
          this.selectedBodyId = hitId;
          this.selectedBodyIds = [hitId];
          this.onBodySelected?.(hitId);
          const info: BodyInfo | null = this.buildBodyInfo(hitId);
          if (info !== null) this.onBodyInfoReady?.(info);
          return;
        }
      }
      if (event.type === TouchType.Move && this.dragMovingBody && !this.isRunning) {
        const body: box2d.b2Body | undefined = this.world.getBody(this.selectedBodyId);
        if (body !== undefined) {
          const xf: box2d.b2Transform = new box2d.b2Transform();
          xf.p.x = wx;
          xf.p.y = wy;
          xf.q.SetAngle(body.GetAngle());
          body.SetTransform(xf);
        }
        return;
      }
      if (event.type === TouchType.Up) {
        this.dragMovingBody = false;
        if (this.twoPoint.active) { this.twoPoint.active = false; this.twoPoint.firstId = ''; return; }
        const hitId: string | null = this.world.queryPoint(wx, wy);
        if (hitId !== null) {
          const idx: number = this.selectedBodyIds.indexOf(hitId);
          if (idx >= 0 && this.selectedBodyIds.length <= 2) {
            this.selectedBodyIds = [hitId];
          } else {
            if (this.selectedBodyIds.length >= 2) {
              this.selectedBodyIds = [hitId];
            } else {
              this.selectedBodyIds.push(hitId);
            }
          }
          this.selectedBodyId = hitId;
          this.onBodySelected?.(hitId);
          const info: BodyInfo | null = this.buildBodyInfo(hitId);
          if (info !== null) { this.onBodyInfoReady?.(info); }
          if (this.selectedBodyIds.length === 2) {
            this.onTwoBodiesSelected?.(this.selectedBodyIds[0], this.selectedBodyIds[1]);
          }
        } else {
          this.selectedBodyId = '';
          this.selectedBodyIds = [];
          this.onBodyDeselected?.();
        }
        return;
      }
      return;
    }

    if (event.type === TouchType.Up && this.currentTool === EditorTool.ANCHOR) {
      const snapped: Point = CanvasUtils.snapPointToGrid({ x: wx, y: wy });
      const anchorId: string = this.world.createAnchor(snapped.x, snapped.y);
      this.bodyCount = this.world.getBodyCount();
      // Auto-select anchor and switch to SELECT mode
      this.selectCreatedBody(anchorId);
      return;
    }

    if (this.currentTool === EditorTool.ERASER) {
      if (event.type === TouchType.Down || event.type === TouchType.Move) {
        const hitId: string | null = this.world.queryPoint(wx, wy);
        if (hitId !== null) {
          this.world.removeBody(hitId);
          this.bodyCount = this.world.getBodyCount();
          if (this.selectedBodyId === hitId) this.selectedBodyId = '';
          if (this.twoPoint.firstId === hitId) { this.twoPoint.active = false; this.twoPoint.firstId = ''; }
          const idx: number = this.selectedBodyIds.indexOf(hitId);
          if (idx >= 0) this.selectedBodyIds.splice(idx, 1);
          this.trajectories.delete(hitId);
        }
      }
      return;
    }

  }

  private canAddBody(): boolean {
    return this.world.getBodyCount() < PhysicsConfig.MAX_BODIES;
  }

  finishDragCreate(wx: number, wy: number): void {
    if (!this.canAddBody()) return;
    const snappedStartWX: number = this.createState.snappedStartWX;
    const snappedStartWY: number = this.createState.snappedStartWY;
    let createdId: string = '';

    if (this.currentTool === EditorTool.CIRCLE) {
      const dx: number = wx - snappedStartWX;
      const dy: number = wy - snappedStartWY;
      const rawR: number = Math.sqrt(dx * dx + dy * dy);
      const r: number = Math.max(1.0, Math.round(rawR));
      const id: string = this.world.genBodyId();
      const def: BodyDef = this.makeBodyDef(
        id, BodyShapeType.CIRCLE, false,
        snappedStartWX, snappedStartWY,
        r * 2, r * 2, r, Colors.BODY_CIRCLE
      );
      def.dragVelocityX = 0;
      def.dragVelocityY = 0;
      this.world.createCircle(snappedStartWX, snappedStartWY, r, def);
      this.bodyCount = this.world.getBodyCount();
      createdId = id;
    } else if (this.currentTool === EditorTool.RECTANGLE) {
      const wxSnapped: number = CanvasUtils.snapToGridWorld(wx);
      const wySnapped: number = CanvasUtils.snapToGridWorld(wy);
      const hw: number = Math.max(0.5, Math.abs(wxSnapped - snappedStartWX) / 2);
      const hh: number = Math.max(0.5, Math.abs(wySnapped - snappedStartWY) / 2);
      const cx: number = (snappedStartWX + wxSnapped) / 2;
      const cy: number = (snappedStartWY + wySnapped) / 2;
      const id: string = this.world.genBodyId();
      const def: BodyDef = this.makeBodyDef(
        id, BodyShapeType.RECTANGLE, false,
        cx, cy, hw * 2, hh * 2, 0, Colors.BODY_RECTANGLE
      );
      def.dragVelocityX = 0;
      def.dragVelocityY = 0;
      this.world.createRect(cx, cy, hw * 2, hh * 2, def);
      this.bodyCount = this.world.getBodyCount();
      createdId = id;
    }

    // Auto-select created body and switch to SELECT mode for moving
    if (createdId !== '') {
      this.selectCreatedBody(createdId);
    }
  }

  finishTriangleCreate(): void {
    if (!this.canAddBody()) return;
    const p0: Point = this.trianglePoints[0];
    const p1: Point = this.trianglePoints[1];
    const p2: Point = this.trianglePoints[2];

    const cross: number = (p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x);
    if (Math.abs(cross) < 0.001) return;

    const id: string = this.world.genBodyId();
    const def: BodyDef = this.makeBodyDef(
      id, BodyShapeType.TRIANGLE, false,
      0, 0, 0, 0, 0, Colors.BODY_TRIANGLE
    );
    this.world.createTriangleFromVertices(p0, p1, p2, def);
    this.bodyCount = this.world.getBodyCount();

    // Auto-select created body and switch to SELECT mode
    this.selectCreatedBody(id);
  }

  // Helper: select a newly created body and switch to SELECT tool
  // Note: dragMovingBody is NOT set here — user must touch the body again to drag-move it
  private selectCreatedBody(id: string): void {
    this.selectedBodyId = id;
    this.selectedBodyIds = [id];
    this.onBodySelected?.(id);
    const info: BodyInfo | null = this.buildBodyInfo(id);
    if (info !== null) {
      this.onBodyInfoReady?.(info);
    }
    this.onRequestToolSwitch?.(EditorTool.SELECT);
  }

  makeBodyDef(id: string, shapeType: BodyShapeType, isStatic: boolean,
    x: number, y: number, w: number, h: number, r: number, color: string): BodyDef {
    const def: BodyDef = {
      id: id, shapeType: shapeType,
      dynamicsType: isStatic ? BodyDynamicsType.STATIC : BodyDynamicsType.DYNAMIC,
      x: x, y: y, angle: 0, width: w, height: h, radius: r,
      density: Defaults.DENSITY, friction: Defaults.FRICTION, restitution: Defaults.RESTITUTION,
      color: color, opacity: 1.0, lineWidth: 2, gravityScale: 1.0, fixedRotation: false,
      isLocked: false, linearVelocityX: 0, linearVelocityY: 0, angularVelocity: 0,
      name: Defaults.NAME, dragVelocityX: 0, dragVelocityY: 0
    };
    return def;
  }

  buildBodyInfo(id: string): BodyInfo | null {
    const ud: BodyRuntimeData | undefined = this.world.getBodyRuntimeData(id);
    if (ud === undefined) return null;
    const body: box2d.b2Body | undefined = this.world.getBody(id);
    if (body === undefined) return null;
    const vel: box2d.b2Vec2 = body.GetLinearVelocity();
    const speed: number = Math.sqrt(vel.x * vel.x + vel.y * vel.y);
    const angleDeg: number = speed > 0.001 ? Math.atan2(vel.y, vel.x) * 180 / Math.PI : 0;

    const info: BodyInfo = {
      id: ud.id,
      shapeType: ud.shapeType,
      dynamicsType: ud.dynamicsType,
      color: ud.color,
      opacity: ud.opacity,
      lineWidth: ud.lineWidth,
      mass: ud.mass,
      friction: ud.friction,
      restitution: ud.restitution,
      gravityScale: body.GetGravityScale(),
      fixedRotation: body.IsFixedRotation(),
      isLocked: ud.isLocked,
      width: ud.width,
      height: ud.height,
      radius: ud.radius,
      name: ud.name || ud.id,
      velocityAngle: angleDeg,
      velocityMagnitude: speed,
      springStiffness: ud.springStiffness || Defaults.SPRING_STIFFNESS,
      isFixed: ud.dynamicsType === 'static'
    };
    return info;
  }

  applyPropertyChange(id: string, key: string, value: Object): void {
    const body: box2d.b2Body | undefined = this.world.getBody(id);
    const ud: BodyRuntimeData | undefined = this.world.getBodyRuntimeData(id);
    if (body === undefined || ud === undefined) return;

    const numVal: number = typeof value === 'number' ? value as number : 0;
    const strVal: string = typeof value === 'string' ? value as string : '';
    const boolVal: boolean = typeof value === 'boolean' ? value as boolean : false;

    switch (key) {
      case '_delete':
        this.world.removeBody(id);
        this.trajectories.delete(id);
        this.bodyCount = this.world.getBodyCount();
        this.selectedBodyId = '';
        this.selectedBodyIds = [];
        return;
      case 'name':
        ud.name = strVal;
        break;
      case 'mass': {
        if (body.GetType() !== box2d.b2BodyType.b2_staticBody) {
          // 使用 GetMass/GetDensity 替代 ComputeMass，避免 ArkTS 绑定兼容问题
          const currentMass: number = body.GetMass();
          if (currentMass > 0.0001 && numVal > 0) {
            const fixture: box2d.b2Fixture | null = body.GetFixtureList();
            if (fixture !== null) {
              const currentDensity: number = fixture.GetDensity();
              // 密度与质量成正比：newDensity = currentDensity * (newMass / currentMass)
              const newDensity: number = currentDensity * (numVal / currentMass);
              fixture.SetDensity(newDensity);
              body.ResetMassData();
            }
          }
        }
        ud.mass = numVal;
        break;
      }
      case 'friction': {
        const fixture: box2d.b2Fixture | null = body.GetFixtureList();
        if (fixture !== null) fixture.SetFriction(numVal);
        ud.friction = numVal;
        break;
      }
      case 'restitution': {
        const fixture: box2d.b2Fixture | null = body.GetFixtureList();
        if (fixture !== null) fixture.SetRestitution(numVal);
        ud.restitution = numVal;
        break;
      }
      case 'color':
        ud.color = strVal;
        break;
      case 'velocityAngle': {
        const rad: number = numVal * Math.PI / 180;
        const mag: number = ud.velocityMagnitude || 0;
        const v: box2d.b2Vec2 = new box2d.b2Vec2(Math.cos(rad) * mag, Math.sin(rad) * mag);
        body.SetLinearVelocity(v);
        ud.velocityAngle = numVal;
        break;
      }
      case 'velocityMagnitude': {
        const rad: number = (ud.velocityAngle || 0) * Math.PI / 180;
        const v: box2d.b2Vec2 = new box2d.b2Vec2(Math.cos(rad) * numVal, Math.sin(rad) * numVal);
        body.SetLinearVelocity(v);
        ud.velocityMagnitude = numVal;
        break;
      }
      case 'isFixed': {
        const b2Type: box2d.b2BodyType = boolVal ?
          box2d.b2BodyType.b2_staticBody : box2d.b2BodyType.b2_dynamicBody;
        body.SetType(b2Type);
        ud.dynamicsType = boolVal ? 'static' : 'dynamic';
        ud.isFixed = boolVal;
        break;
      }
      case 'gravityScale':
        body.SetGravityScale(numVal);
        break;
      case 'fixedRotation':
        body.SetFixedRotation(boolVal);
        break;
      case 'lineWidth':
        ud.lineWidth = numVal;
        break;
    }
    body.SetUserData(ud);
  }

  renderFrame(): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    const w: number = this.canvasW;
    const h: number = this.canvasH;
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = Colors.CANVAS_BG;
    ctx.fillRect(0, 0, w, h);

    if (this.isRunning) {
      this.world.setGravity(this.gravityX, this.gravityY);
      // 自定义胡克定律弹簧力（刚度独立于质量，质量越大弹簧拉伸越长）
      this.world.applySpringForces();
      this.world.step(this.simulationSpeed * PhysicsConfig.TIME_STEP,
        PhysicsConfig.VELOCITY_ITER, PhysicsConfig.POSITION_ITER);
      this.cleanOutOfBounds();
    }

    ctx.save();
    ctx.translate(this.panOffset.x, this.panOffset.y);
    ctx.scale(this.canvasScale, this.canvasScale);

    this.drawGroundLine(ctx);
    this.drawWorldBoundary(ctx);
    if (this.showGrid) this.drawGrid(ctx);

    const bodyList: BodyRenderItem[] = [];
    const margin: number = 2;
    const viewMinX: number = this.toWorldX(-margin * PhysicsConfig.PIXELS_PER_METER);
    const viewMaxX: number = this.toWorldX(this.canvasW + margin * PhysicsConfig.PIXELS_PER_METER);
    const viewMinY: number = this.toWorldY(-margin * PhysicsConfig.PIXELS_PER_METER);
    const viewMaxY: number = this.toWorldY(this.canvasH + margin * PhysicsConfig.PIXELS_PER_METER);

    this.world.forEachBody((body: box2d.b2Body, id: string, data: BodyRuntimeData | undefined) => {
      if (data !== undefined) {
        const pos: box2d.b2Vec2 = body.GetPosition();
        const r: number = Math.max(data.width, data.height, data.radius * 2) + 2;
        if (pos.x + r < viewMinX || pos.x - r > viewMaxX ||
          pos.y + r < viewMinY || pos.y - r > viewMaxY) {
          return;
        }
        let area: number = 0;
        if (data.shapeType === 'circle') {
          area = Math.PI * data.radius * data.radius;
        } else if (data.shapeType === 'triangle') {
          area = (data.width * data.height) / 2;
        } else {
          area = data.width * data.height;
        }
        const item: BodyRenderItem = { body: body, id: id, area: area };
        bodyList.push(item);
      }
    });
    bodyList.sort((a, b) => b.area - a.area);
    for (const item of bodyList) {
      this.drawBody(ctx, item.body, item.id);
    }

    this.world.forEachJointInfo((info: JointInfo) => { this.drawJointLine(ctx, info); });

    if (this.twoPoint.active && this.twoPoint.firstId !== '') {
      this.drawFirstPointIndicator(ctx);
    }

    if (this.createState.active) this.drawCreatePreview(ctx);

    if (this.trianglePoints.length > 0) this.drawTrianglePreview(ctx);

    ctx.restore();
  }

  drawGrid(ctx: CanvasRenderingContext2D): void {
    const PPM: number = PhysicsConfig.PIXELS_PER_METER;
    const halfPx: number = this.WORLD_HALF * PPM;
    ctx.save();
    ctx.beginPath();
    ctx.rect(-halfPx, -halfPx, halfPx * 2, halfPx * 2);
    ctx.clip();
    ctx.strokeStyle = Colors.GRID_LINE;
    ctx.lineWidth = 0.5 / this.canvasScale;
    ctx.beginPath();
    for (let x: number = -halfPx; x <= halfPx; x += PPM) {
      ctx.moveTo(x, -halfPx);
      ctx.lineTo(x, halfPx);
    }
    for (let y: number = -halfPx; y <= halfPx; y += PPM) {
      ctx.moveTo(-halfPx, y);
      ctx.lineTo(halfPx, y);
    }
    ctx.stroke();
    ctx.restore();
  }

  drawGroundLine(ctx: CanvasRenderingContext2D): void {
    const gy: number = 0;
    ctx.strokeStyle = '#999';
    ctx.lineWidth = 2 / this.canvasScale;
    ctx.beginPath();
    const half: number = this.WORLD_HALF * PhysicsConfig.PIXELS_PER_METER;
    ctx.moveTo(-half, gy);
    ctx.lineTo(half, gy);
    ctx.stroke();
  }

  drawWorldBoundary(ctx: CanvasRenderingContext2D): void {
    const half: number = this.WORLD_HALF * PhysicsConfig.PIXELS_PER_METER;
    ctx.fillStyle = '#E8E9EB';
    ctx.fillRect(-half, -half, half * 2, half * 2);
    ctx.strokeStyle = '#BDBDBD';
    ctx.lineWidth = 2 / this.canvasScale;
    ctx.setLineDash([10, 5]);
    ctx.strokeRect(-half, -half, half * 2, half * 2);
    ctx.setLineDash([]);
  }

  drawBody(ctx: CanvasRenderingContext2D, body: box2d.b2Body, id: string): void {
    const pos: box2d.b2Vec2 = body.GetPosition();
    const sx: number = pos.x * PhysicsConfig.PIXELS_PER_METER;
    const sy: number = pos.y * PhysicsConfig.PIXELS_PER_METER;
    const angle: number = body.GetAngle();
    const selected: boolean = (id === this.selectedBodyId);
    const inMultiSelect: boolean = this.selectedBodyIds.indexOf(id) >= 0;
    const isFirstPoint: boolean = (this.twoPoint.active && id === this.twoPoint.firstId);
    const udObj: Object | undefined = body.GetUserData();
    if (udObj === undefined) return;
    const ud = udObj as Record<string, Object>;
    const shapeType: string = (ud['shapeType'] as string) ?? 'circle';
    const color: string = (ud['color'] as string) ?? '#999';
    const lw: number = (ud['lineWidth'] as number) ?? 2;
    const isStatic: boolean = (ud['dynamicsType'] as string) === 'static';
    const isNode: boolean = id.startsWith('node_');
    const PPM: number = PhysicsConfig.PIXELS_PER_METER;

    ctx.save();
    ctx.translate(sx, sy);
    ctx.rotate(angle);

    if (shapeType === 'circle') {
      const r: number = ((ud['radius'] as number) ?? 0.5) * PPM;
      ctx.beginPath();
      ctx.arc(0, 0, r, 0, Math.PI * 2);
      ctx.fillStyle = color;
      ctx.fill();
      if (selected || inMultiSelect) {
        ctx.strokeStyle = inMultiSelect && this.selectedBodyIds.length === 2 ? Colors.BOOLEAN_OP : Colors.BODY_SELECTED;
        ctx.lineWidth = 3 / this.canvasScale;
        ctx.stroke();
      } else if (isFirstPoint) {
        ctx.strokeStyle = '#FF9800';
        ctx.lineWidth = 3 / this.canvasScale;
        ctx.stroke();
      } else {
        ctx.strokeStyle = isStatic ? Colors.BODY_STATIC : 'rgba(0,0,0,0.25)';
        ctx.lineWidth = lw / this.canvasScale;
        ctx.stroke();
      }
      if ((isStatic && id.startsWith('anchor_')) || isNode) {
        ctx.strokeStyle = '#607D8B';
        ctx.lineWidth = 2 / this.canvasScale;
        const cs: number = 4;
        ctx.beginPath();
        ctx.moveTo(-cs, 0);
        ctx.lineTo(cs, 0);
        ctx.moveTo(0, -cs);
        ctx.lineTo(0, cs);
        ctx.stroke();
      }
    } else if (shapeType === 'triangle') {
      const fixture: box2d.b2Fixture | null = body.GetFixtureList();
      if (fixture !== null) {
        const shape: box2d.b2Shape = fixture.GetShape();
        if (shape.GetType() === box2d.b2ShapeType.e_polygonShape) {
          const poly: box2d.b2PolygonShape = shape as box2d.b2PolygonShape;
          ctx.beginPath();
          const v0x: number = poly.m_vertices[0].x * PPM;
          const v0y: number = poly.m_vertices[0].y * PPM;
          ctx.moveTo(v0x, v0y);
          for (let i: number = 1; i < poly.m_count; i++) {
            ctx.lineTo(poly.m_vertices[i].x * PPM, poly.m_vertices[i].y * PPM);
          }
          ctx.closePath();
          ctx.fillStyle = color;
          ctx.fill();
          if (selected || inMultiSelect) {
            ctx.strokeStyle = inMultiSelect && this.selectedBodyIds.length === 2 ?
              Colors.BOOLEAN_OP : Colors.BODY_SELECTED;
            ctx.lineWidth = 3 / this.canvasScale;
          } else if (isFirstPoint) {
            ctx.strokeStyle = '#FF9800';
            ctx.lineWidth = 3 / this.canvasScale;
          } else {
            ctx.strokeStyle = isStatic ? Colors.BODY_STATIC : 'rgba(0,0,0,0.25)';
            ctx.lineWidth = lw / this.canvasScale;
          }
          ctx.stroke();
        }
      }
    } else if (shapeType === 'polygon') {
      const fixture: box2d.b2Fixture | null = body.GetFixtureList();
      if (fixture !== null) {
        const shape: box2d.b2Shape = fixture.GetShape();
        if (shape.GetType() === box2d.b2ShapeType.e_polygonShape) {
          const poly: box2d.b2PolygonShape = shape as box2d.b2PolygonShape;
          ctx.beginPath();
          const vx0: number = poly.m_vertices[0].x * PPM;
          const vy0: number = poly.m_vertices[0].y * PPM;
          ctx.moveTo(vx0, vy0);
          for (let i: number = 1; i < poly.m_count; i++) {
            ctx.lineTo(poly.m_vertices[i].x * PPM, poly.m_vertices[i].y * PPM);
          }
          ctx.closePath();
          ctx.fillStyle = color;
          ctx.fill();
          if (selected || inMultiSelect) {
            ctx.strokeStyle = inMultiSelect && this.selectedBodyIds.length === 2 ?
              Colors.BOOLEAN_OP : Colors.BODY_SELECTED;
            ctx.lineWidth = 3 / this.canvasScale;
          } else {
            ctx.strokeStyle = isStatic ? Colors.BODY_STATIC : 'rgba(0,0,0,0.25)';
            ctx.lineWidth = lw / this.canvasScale;
          }
          ctx.stroke();
        }
      }
    } else if (shapeType === 'rectangle') {
      const hw: number = ((ud['width'] as number) ?? 1) * PPM / 2;
      const hh: number = ((ud['height'] as number) ?? 1) * PPM / 2;
      ctx.fillStyle = color;
      ctx.fillRect(-hw, -hh, hw * 2, hh * 2);
      if (selected || inMultiSelect) {
        ctx.strokeStyle = inMultiSelect && this.selectedBodyIds.length === 2 ?
          Colors.BOOLEAN_OP : Colors.BODY_SELECTED;
        ctx.lineWidth = 3 / this.canvasScale;
        ctx.strokeRect(-hw, -hh, hw * 2, hh * 2);
      } else if (isFirstPoint) {
        ctx.strokeStyle = '#FF9800';
        ctx.lineWidth = 3 / this.canvasScale;
        ctx.strokeRect(-hw, -hh, hw * 2, hh * 2);
      } else {
        ctx.strokeStyle = isStatic ? Colors.BODY_STATIC : 'rgba(0,0,0,0.25)';
        ctx.lineWidth = lw / this.canvasScale;
        ctx.strokeRect(-hw, -hh, hw * 2, hh * 2);
      }
    }
    ctx.restore();

    if (this.showTrajectory && !isStatic) this.drawTrajectory(ctx, id, sx, sy);
  }

  drawJointLine(ctx: CanvasRenderingContext2D, info: JointInfo): void {
    const posA: Point | null = this.world.getBodyPosition(info.bodyAId);
    const posB: Point | null = this.world.getBodyPosition(info.bodyBId);
    if (posA === null || posB === null) return;
    const ax: number = posA.x * PhysicsConfig.PIXELS_PER_METER;
    const ay: number = posA.y * PhysicsConfig.PIXELS_PER_METER;
    const bx: number = posB.x * PhysicsConfig.PIXELS_PER_METER;
    const by: number = posB.y * PhysicsConfig.PIXELS_PER_METER;

    if (info.type === 'spring') {
      ctx.strokeStyle = Colors.SPRING;
      ctx.lineWidth = 2.5 / this.canvasScale;
      ctx.beginPath();
      const segs: number = 14;
      for (let i: number = 0; i <= segs; i++) {
        const t: number = i / segs;
        const px: number = ax + (bx - ax) * t;
        const py: number = ay + (by - ay) * t;
        if (i > 0 && i < segs) {
          const perpX: number = -(by - ay) * 0.15;
          const perpY: number = (bx - ax) * 0.15;
          const off: number = (i % 2 === 0 ? 1 : -1);
          ctx.lineTo(px + perpX * off, py + perpY * off);
        } else {
          ctx.lineTo(px, py);
        }
      }
      ctx.stroke();
    } else if (info.type === 'rope') {
      const dx: number = bx - ax;
      const dy: number = by - ay;
      const currentDist: number = Math.sqrt(dx * dx + dy * dy);
      const maxLen: number = info.maxLength > 0 ? info.maxLength * PhysicsConfig.PIXELS_PER_METER : currentDist;
      const slackRatio: number = maxLen > 0 ? Math.max(0, 1 - (currentDist / maxLen)) : 0;

      ctx.strokeStyle = Colors.ROPE;
      ctx.lineWidth = 2.5 / this.canvasScale;

      if (slackRatio > 0.01 && currentDist > 0.01) {
        const droop: number = slackRatio * maxLen * 0.4;
        const perpX: number = -dy / currentDist;
        const perpY: number = dx / currentDist;
        const midX: number = (ax + bx) / 2 + perpX * droop;
        const midY: number = (ay + by) / 2 + perpY * droop;
        ctx.beginPath();
        ctx.moveTo(ax, ay);
        ctx.quadraticCurveTo(midX, midY, bx, by);
        ctx.stroke();
      } else {
        ctx.beginPath();
        ctx.moveTo(ax, ay);
        ctx.lineTo(bx, by);
        ctx.stroke();
      }
    } else {
      ctx.strokeStyle = '#999';
      ctx.lineWidth = 1.5 / this.canvasScale;
      ctx.beginPath();
      ctx.moveTo(ax, ay);
      ctx.lineTo(bx, by);
      ctx.stroke();
    }
  }

  drawFirstPointIndicator(ctx: CanvasRenderingContext2D): void {
    const pos: Point | null = this.world.getBodyPosition(this.twoPoint.firstId);
    if (pos === null) return;
    const px: number = pos.x * PhysicsConfig.PIXELS_PER_METER;
    const py: number = pos.y * PhysicsConfig.PIXELS_PER_METER;
    ctx.strokeStyle = '#FF9800';
    ctx.lineWidth = 2.5 / this.canvasScale;
    ctx.setLineDash([4, 4]);
    ctx.beginPath();
    ctx.arc(px, py, 18, 0, Math.PI * 2);
    ctx.stroke();
    ctx.setLineDash([]);
  }

  drawTrajectory(ctx: CanvasRenderingContext2D, id: string, sx: number, sy: number): void {
    if (!this.trajectories.has(id)) {
      const arr: Point[] = [];
      this.trajectories.set(id, arr);
    }
    const arr: Point[] | undefined = this.trajectories.get(id);
    if (arr === undefined) return;
    const pt: Point = { x: sx, y: sy };
    arr.push(pt);
    if (arr.length > 80) arr.splice(0, 1);
    if (arr.length < 2) return;
    ctx.beginPath();
    ctx.strokeStyle = Colors.TRAJECTORY;
    ctx.lineWidth = 1.5;
    ctx.globalAlpha = 0.6;
    ctx.moveTo(arr[0].x, arr[0].y);
    for (let i: number = 1; i < arr.length; i++) ctx.lineTo(arr[i].x, arr[i].y);
    ctx.stroke();
    ctx.globalAlpha = 1.0;
  }

  drawCreatePreview(ctx: CanvasRenderingContext2D): void {
    const snappedStartWX: number = this.createState.snappedStartWX;
    const snappedStartWY: number = this.createState.snappedStartWY;
    const x0: number = snappedStartWX * PhysicsConfig.PIXELS_PER_METER;
    const y0: number = snappedStartWY * PhysicsConfig.PIXELS_PER_METER;
    const wxCurr: number = (this.createState.currentX - this.panOffset.x) / (this.canvasScale * PhysicsConfig.PIXELS_PER_METER);
    const wyCurr: number = (this.createState.currentY - this.panOffset.y) / (this.canvasScale * PhysicsConfig.PIXELS_PER_METER);

    ctx.setLineDash([5, 3]);

    if (this.currentTool === EditorTool.CIRCLE) {
      const dx: number = wxCurr - snappedStartWX;
      const dy: number = wyCurr - snappedStartWY;
      const rawR: number = Math.sqrt(dx * dx + dy * dy);
      const r: number = Math.max(1, Math.round(rawR)) * PhysicsConfig.PIXELS_PER_METER;
      ctx.strokeStyle = 'rgba(77,182,172,0.6)';
      ctx.fillStyle = 'rgba(77,182,172,0.1)';
      ctx.lineWidth = 2 / this.canvasScale;
      ctx.beginPath();
      ctx.arc(x0, y0, r, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.strokeStyle = 'rgba(77,182,172,0.4)';
      ctx.lineWidth = 1 / this.canvasScale;
      ctx.beginPath();
      const ang: number = Math.atan2(dy, dx);
      ctx.moveTo(x0, y0);
      ctx.lineTo(x0 + Math.cos(ang) * r, y0 + Math.sin(ang) * r);
      ctx.stroke();
    } else if (this.currentTool === EditorTool.RECTANGLE) {
      const wxSnapped: number = CanvasUtils.snapToGridWorld(wxCurr);
      const wySnapped: number = CanvasUtils.snapToGridWorld(wyCurr);
      const x1s: number = wxSnapped * PhysicsConfig.PIXELS_PER_METER;
      const y1s: number = wySnapped * PhysicsConfig.PIXELS_PER_METER;
      const hw: number = Math.abs(x1s - x0) / 2;
      const hh: number = Math.abs(y1s - y0) / 2;
      const cx: number = (x0 + x1s) / 2;
      const cy: number = (y0 + y1s) / 2;
      ctx.strokeStyle = 'rgba(239,112,96,0.6)';
      ctx.fillStyle = 'rgba(239,112,96,0.1)';
      ctx.lineWidth = 2 / this.canvasScale;
      ctx.fillRect(cx - hw, cy - hh, hw * 2, hh * 2);
      ctx.strokeRect(cx - hw, cy - hh, hw * 2, hh * 2);
    }
    ctx.setLineDash([]);
  }

  drawTrianglePreview(ctx: CanvasRenderingContext2D): void {
    if (this.trianglePoints.length === 0) return;

    const PPM: number = PhysicsConfig.PIXELS_PER_METER;
    ctx.strokeStyle = 'rgba(171,71,188,0.6)';
    ctx.fillStyle = 'rgba(171,71,188,0.1)';
    ctx.lineWidth = 2 / this.canvasScale;

    for (const p of this.trianglePoints) {
      const sx: number = p.x * PPM;
      const sy: number = p.y * PPM;
      ctx.beginPath();
      ctx.arc(sx, sy, 5 / this.canvasScale, 0, Math.PI * 2);
      ctx.fillStyle = '#AB47BC';
      ctx.fill();
    }

    ctx.setLineDash([5, 3]);
    ctx.beginPath();
    if (this.trianglePoints.length >= 1) {
      const sx0: number = this.trianglePoints[0].x * PPM;
      const sy0: number = this.trianglePoints[0].y * PPM;
      ctx.moveTo(sx0, sy0);

      if (this.trianglePoints.length >= 2) {
        const sx1: number = this.trianglePoints[1].x * PPM;
        const sy1: number = this.trianglePoints[1].y * PPM;
        ctx.lineTo(sx1, sy1);

        if (this.trianglePoints.length === 3) {
          const sx2: number = this.trianglePoints[2].x * PPM;
          const sy2: number = this.trianglePoints[2].y * PPM;
          ctx.lineTo(sx2, sy2);
          ctx.closePath();
        } else {
          const mx: number = (this.lastMouseSX - this.panOffset.x) / this.canvasScale;
          const my: number = (this.lastMouseSY - this.panOffset.y) / this.canvasScale;
          ctx.lineTo(mx, my);
          ctx.lineTo(sx0, sy0);
        }
      }
    }
    ctx.stroke();
    ctx.setLineDash([]);
  }

}
