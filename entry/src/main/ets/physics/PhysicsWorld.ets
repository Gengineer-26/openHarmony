import * as box2d from '@ohos/box2d';
import { BodyDef, BodyRuntimeData, JointDef, JointType, Point, BodyDynamicsType, BodyShapeType } from '../model/Types';
import { PhysicsConfig } from './PhysicsConfig';
import { Defaults } from '../common/Constants';

// 关节可视化数据
export interface JointInfo {
  type: string;
  bodyAId: string;
  bodyBId: string;
  maxLength: number;
  stiffness: number;
}

// 自定义弹簧数据（胡克定律 F = k * Δx，刚度独立于质量）
interface SpringData {
  bodyAId: string;
  bodyBId: string;
  restLength: number;
  stiffness: number;
  damping: number;
}

export class PhysicsWorld {
  world: box2d.b2World;
  private bodyMap: Map<string, box2d.b2Body> = new Map();
  private jointInfoMap: Map<string, JointInfo> = new Map();
  private jointMap: Map<string, box2d.b2Joint> = new Map();
  private springMap: Map<string, SpringData> = new Map(); // 自定义弹簧
  private nextBodyId: number = 0;
  private nextJointId: number = 0;

  constructor(gravityX: number, gravityY: number) {
    const grav: box2d.b2Vec2 = new box2d.b2Vec2(gravityX, gravityY);
    this.world = new box2d.b2World(grav);
    this.createWalls();
  }

  // ====== 墙壁 ======
  private createWalls(): void {
    // Ground
    this.createStaticBox(0, -15, 60, 0.5, 'wall_ground');
    // Left wall
    this.createStaticBox(-21, 0, 0.5, 30, 'wall_left');
    // Right wall
    this.createStaticBox(21, 0, 0.5, 30, 'wall_right');
  }

  private createStaticBox(x: number, y: number, halfW: number, halfH: number, id: string): void {
    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = box2d.b2BodyType.b2_staticBody;
    bodyDef.position.x = x;
    bodyDef.position.y = y;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);
    const shape: box2d.b2PolygonShape = new box2d.b2PolygonShape();
    shape.SetAsBox(halfW, halfH);

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.friction = 0.5;
    body.CreateFixture(fixDef);

    const ud: BodyRuntimeData = {
      id: id, shapeType: 'rectangle', dynamicsType: 'static',
      color: '#78909C', opacity: 1.0, lineWidth: 1,
      width: halfW * 2, height: halfH * 2, radius: 0,
      mass: 0, friction: 0.5, restitution: 0.3, isLocked: true,
      name: '墙壁', velocityAngle: 0, velocityMagnitude: 0,
      springStiffness: 0, isFixed: true,
      dragVelocityX: 0, dragVelocityY: 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(id, body);
  }

  // ====== 创建圆形刚体 ======
  createCircle(x: number, y: number, radius: number, options: BodyDef): string {
    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = this.toB2BodyType(options.dynamicsType);
    bodyDef.position.x = x;
    bodyDef.position.y = y;
    bodyDef.angle = options.angle;
    bodyDef.linearVelocity.x = options.linearVelocityX || options.dragVelocityX || 0;
    bodyDef.linearVelocity.y = options.linearVelocityY || options.dragVelocityY || 0;
    bodyDef.angularVelocity = options.angularVelocity;
    bodyDef.fixedRotation = options.fixedRotation;
    bodyDef.gravityScale = options.gravityScale;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);

    const shape: box2d.b2CircleShape = new box2d.b2CircleShape();
    shape.m_radius = radius;

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.density = options.density;
    fixDef.friction = options.friction;
    fixDef.restitution = options.restitution;
    body.CreateFixture(fixDef);

    const vel: box2d.b2Vec2 = body.GetLinearVelocity();
    const speed: number = Math.sqrt(vel.x * vel.x + vel.y * vel.y);

    const ud: BodyRuntimeData = {
      id: options.id, shapeType: 'circle', dynamicsType: options.dynamicsType,
      color: options.color, opacity: options.opacity, lineWidth: options.lineWidth,
      width: radius * 2, height: radius * 2, radius: radius,
      mass: options.density * Math.PI * radius * radius,
      friction: options.friction, restitution: options.restitution,
      isLocked: options.isLocked,
      name: options.name || Defaults.NAME,
      velocityAngle: speed > 0.001 ? Math.atan2(vel.y, vel.x) * 180 / Math.PI : 0,
      velocityMagnitude: speed,
      springStiffness: Defaults.SPRING_STIFFNESS,
      isFixed: options.dynamicsType === BodyDynamicsType.STATIC,
      dragVelocityX: options.dragVelocityX || 0,
      dragVelocityY: options.dragVelocityY || 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(options.id, body);
    return options.id;
  }

  // ====== 创建矩形刚体 ======
  createRect(x: number, y: number, w: number, h: number, options: BodyDef): string {
    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = this.toB2BodyType(options.dynamicsType);
    bodyDef.position.x = x;
    bodyDef.position.y = y;
    bodyDef.angle = options.angle;
    bodyDef.linearVelocity.x = options.linearVelocityX || options.dragVelocityX || 0;
    bodyDef.linearVelocity.y = options.linearVelocityY || options.dragVelocityY || 0;
    bodyDef.angularVelocity = options.angularVelocity;
    bodyDef.fixedRotation = options.fixedRotation;
    bodyDef.gravityScale = options.gravityScale;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);

    const shape: box2d.b2PolygonShape = new box2d.b2PolygonShape();
    shape.SetAsBox(w / 2, h / 2);

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.density = options.density;
    fixDef.friction = options.friction;
    fixDef.restitution = options.restitution;
    body.CreateFixture(fixDef);

    const vel: box2d.b2Vec2 = body.GetLinearVelocity();
    const speed: number = Math.sqrt(vel.x * vel.x + vel.y * vel.y);

    const ud: BodyRuntimeData = {
      id: options.id, shapeType: 'rectangle', dynamicsType: options.dynamicsType,
      color: options.color, opacity: options.opacity, lineWidth: options.lineWidth,
      width: w, height: h, radius: 0,
      mass: options.density * w * h,
      friction: options.friction, restitution: options.restitution,
      isLocked: options.isLocked,
      name: options.name || Defaults.NAME,
      velocityAngle: speed > 0.001 ? Math.atan2(vel.y, vel.x) * 180 / Math.PI : 0,
      velocityMagnitude: speed,
      springStiffness: Defaults.SPRING_STIFFNESS,
      isFixed: options.dynamicsType === BodyDynamicsType.STATIC,
      dragVelocityX: options.dragVelocityX || 0,
      dragVelocityY: options.dragVelocityY || 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(options.id, body);
    return options.id;
  }

  // ====== 创建三角形刚体 ======
  createTriangle(cx: number, cy: number, w: number, h: number, options: BodyDef): string {
    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = this.toB2BodyType(options.dynamicsType);
    bodyDef.position.x = cx;
    bodyDef.position.y = cy;
    bodyDef.angle = options.angle;
    bodyDef.linearVelocity.x = options.linearVelocityX || options.dragVelocityX || 0;
    bodyDef.linearVelocity.y = options.linearVelocityY || options.dragVelocityY || 0;
    bodyDef.angularVelocity = options.angularVelocity;
    bodyDef.fixedRotation = options.fixedRotation;
    bodyDef.gravityScale = options.gravityScale;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);

    const shape: box2d.b2PolygonShape = new box2d.b2PolygonShape();
    const halfW: number = w / 2;
    const halfH: number = h / 2;
    // 直角三角(局部坐标): 左下, 右下, 左上
    const vertices: box2d.b2Vec2[] = [
      new box2d.b2Vec2(-halfW, -halfH),
      new box2d.b2Vec2(halfW, -halfH),
      new box2d.b2Vec2(-halfW, halfH)
    ];
    shape.Set(vertices, 3);

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.density = options.density;
    fixDef.friction = options.friction;
    fixDef.restitution = options.restitution;
    body.CreateFixture(fixDef);

    const area: number = (w * h) / 2;
    const vel: box2d.b2Vec2 = body.GetLinearVelocity();
    const speed: number = Math.sqrt(vel.x * vel.x + vel.y * vel.y);

    const ud: BodyRuntimeData = {
      id: options.id, shapeType: 'triangle', dynamicsType: options.dynamicsType,
      color: options.color, opacity: options.opacity, lineWidth: options.lineWidth,
      width: w, height: h, radius: 0,
      mass: options.density * area,
      friction: options.friction, restitution: options.restitution,
      isLocked: options.isLocked,
      name: options.name || Defaults.NAME,
      velocityAngle: speed > 0.001 ? Math.atan2(vel.y, vel.x) * 180 / Math.PI : 0,
      velocityMagnitude: speed,
      springStiffness: Defaults.SPRING_STIFFNESS,
      isFixed: options.dynamicsType === BodyDynamicsType.STATIC,
      dragVelocityX: options.dragVelocityX || 0,
      dragVelocityY: options.dragVelocityY || 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(options.id, body);
    return options.id;
  }

  // ====== 创建三角形(三点) ======
  createTriangleFromVertices(p0: Point, p1: Point, p2: Point, options: BodyDef): string {
    // 用三点计算质心
    const cx: number = (p0.x + p1.x + p2.x) / 3;
    const cy: number = (p0.y + p1.y + p2.y) / 3;

    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = this.toB2BodyType(options.dynamicsType);
    bodyDef.position.x = cx;
    bodyDef.position.y = cy;
    bodyDef.angle = options.angle;
    bodyDef.linearVelocity.x = options.linearVelocityX || options.dragVelocityX || 0;
    bodyDef.linearVelocity.y = options.linearVelocityY || options.dragVelocityY || 0;
    bodyDef.angularVelocity = options.angularVelocity;
    bodyDef.fixedRotation = options.fixedRotation;
    bodyDef.gravityScale = options.gravityScale;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);

    const shape: box2d.b2PolygonShape = new box2d.b2PolygonShape();
    // 转换为局部坐标（相对于质心）
    const vertices: box2d.b2Vec2[] = [
      new box2d.b2Vec2(p0.x - cx, p0.y - cy),
      new box2d.b2Vec2(p1.x - cx, p1.y - cy),
      new box2d.b2Vec2(p2.x - cx, p2.y - cy)
    ];
    shape.Set(vertices, 3);

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.density = options.density;
    fixDef.friction = options.friction;
    fixDef.restitution = options.restitution;
    body.CreateFixture(fixDef);

    // 计算三角形面积
    const area: number = Math.abs(
      (p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x)
    ) / 2;

    const vel: box2d.b2Vec2 = body.GetLinearVelocity();
    const speed: number = Math.sqrt(vel.x * vel.x + vel.y * vel.y);
    const w: number = Math.max(Math.abs(p1.x - p0.x), Math.abs(p2.x - p0.x));
    const h: number = Math.max(Math.abs(p1.y - p0.y), Math.abs(p2.y - p0.y));

    const ud: BodyRuntimeData = {
      id: options.id, shapeType: 'triangle', dynamicsType: options.dynamicsType,
      color: options.color, opacity: options.opacity, lineWidth: options.lineWidth,
      width: w * 2, height: h * 2, radius: 0,
      mass: options.density * area,
      friction: options.friction, restitution: options.restitution,
      isLocked: options.isLocked,
      name: options.name || Defaults.NAME,
      velocityAngle: speed > 0.001 ? Math.atan2(vel.y, vel.x) * 180 / Math.PI : 0,
      velocityMagnitude: speed,
      springStiffness: Defaults.SPRING_STIFFNESS,
      isFixed: options.dynamicsType === BodyDynamicsType.STATIC,
      dragVelocityX: options.dragVelocityX || 0,
      dragVelocityY: options.dragVelocityY || 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(options.id, body);
    return options.id;
  }

  // ====== 创建多边形刚体(布尔运算用) ======
  createPolygonBody(worldVertices: Point[], options: BodyDef): string {
    // 计算质心
    let cx: number = 0;
    let cy: number = 0;
    for (const v of worldVertices) { cx += v.x; cy += v.y; }
    cx /= worldVertices.length;
    cy /= worldVertices.length;

    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = this.toB2BodyType(options.dynamicsType);
    bodyDef.position.x = cx;
    bodyDef.position.y = cy;
    bodyDef.angle = options.angle;
    bodyDef.linearVelocity.x = options.linearVelocityX || 0;
    bodyDef.linearVelocity.y = options.linearVelocityY || 0;
    bodyDef.angularVelocity = options.angularVelocity;
    bodyDef.fixedRotation = options.fixedRotation;
    bodyDef.gravityScale = options.gravityScale;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);

    // 转换世界坐标为局部坐标
    const localVerts: box2d.b2Vec2[] = [];
    for (const v of worldVertices) {
      localVerts.push(new box2d.b2Vec2(v.x - cx, v.y - cy));
    }

    const shape: box2d.b2PolygonShape = new box2d.b2PolygonShape();
    shape.Set(localVerts, localVerts.length);

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.density = options.density;
    fixDef.friction = options.friction;
    fixDef.restitution = options.restitution;
    body.CreateFixture(fixDef);

    // 计算包围盒作为宽高近似
    let minX: number = worldVertices[0].x, maxX: number = worldVertices[0].x;
    let minY: number = worldVertices[0].y, maxY: number = worldVertices[0].y;
    for (const v of worldVertices) {
      if (v.x < minX) minX = v.x;
      if (v.x > maxX) maxX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.y > maxY) maxY = v.y;
    }

    const ud: BodyRuntimeData = {
      id: options.id, shapeType: 'polygon', dynamicsType: options.dynamicsType,
      color: options.color, opacity: options.opacity, lineWidth: options.lineWidth,
      width: maxX - minX, height: maxY - minY, radius: 0,
      mass: options.density * (maxX - minX) * (maxY - minY),
      friction: options.friction, restitution: options.restitution,
      isLocked: options.isLocked,
      name: options.name || Defaults.NAME,
      velocityAngle: 0, velocityMagnitude: 0,
      springStiffness: Defaults.SPRING_STIFFNESS,
      isFixed: options.dynamicsType === BodyDynamicsType.STATIC,
      dragVelocityX: 0, dragVelocityY: 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(options.id, body);
    return options.id;
  }

  // ====== 创建锚点 ======
  createAnchor(x: number, y: number): string {
    const id: string = 'anchor_' + this.nextBodyId.toString();
    this.nextBodyId += 1;

    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = box2d.b2BodyType.b2_staticBody;
    bodyDef.position.x = x;
    bodyDef.position.y = y;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);

    const shape: box2d.b2CircleShape = new box2d.b2CircleShape();
    shape.m_radius = 0.15;

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.friction = 0.5;
    body.CreateFixture(fixDef);

    const ud: BodyRuntimeData = {
      id: id, shapeType: 'circle', dynamicsType: 'static',
      color: '#78909C', opacity: 1.0, lineWidth: 2,
      width: 0.3, height: 0.3, radius: 0.15,
      mass: 0, friction: 0.5, restitution: 0.3, isLocked: true,
      name: '锚点', velocityAngle: 0, velocityMagnitude: 0,
      springStiffness: 0, isFixed: true,
      dragVelocityX: 0, dragVelocityY: 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(id, body);
    return id;
  }

  // ====== 创建自由节点(绳子/弹簧) ======
  createSmallNode(x: number, y: number): string {
    const id: string = 'node_' + this.nextBodyId.toString();
    this.nextBodyId += 1;

    const bodyDef: box2d.b2BodyDef = new box2d.b2BodyDef();
    bodyDef.type = box2d.b2BodyType.b2_staticBody;
    bodyDef.position.x = x;
    bodyDef.position.y = y;

    const body: box2d.b2Body = this.world.CreateBody(bodyDef);

    const shape: box2d.b2CircleShape = new box2d.b2CircleShape();
    shape.m_radius = 0.1;

    const fixDef: box2d.b2FixtureDef = new box2d.b2FixtureDef();
    fixDef.shape = shape;
    fixDef.friction = 0.3;
    body.CreateFixture(fixDef);

    const ud: BodyRuntimeData = {
      id: id, shapeType: 'circle', dynamicsType: 'static',
      color: '#90A4AE', opacity: 0.8, lineWidth: 1,
      width: 0.2, height: 0.2, radius: 0.1,
      mass: 0, friction: 0.3, restitution: 0.2, isLocked: false,
      name: '节点', velocityAngle: 0, velocityMagnitude: 0,
      springStiffness: 0, isFixed: true,
      dragVelocityX: 0, dragVelocityY: 0
    };
    body.SetUserData(ud);
    this.bodyMap.set(id, body);
    return id;
  }

  // ====== 弹簧（胡克定律自定义施力，刚度独立于质量）======
  createDistanceJoint(bodyAId: string, bodyBId: string,
    length: number, stiffness: number, damping: number): void {
    const bodyA: box2d.b2Body | undefined = this.bodyMap.get(bodyAId);
    const bodyB: box2d.b2Body | undefined = this.bodyMap.get(bodyBId);
    if (bodyA === undefined || bodyB === undefined) return;

    const jId: string = 'j_' + this.nextJointId.toString();
    this.nextJointId += 1;

    // 不创建 Box2D 关节，改用自定义胡克定律弹簧
    // stiffness 单位为 N/m（每米伸长产生的力），与质量无关
    const springData: SpringData = {
      bodyAId: bodyAId,
      bodyBId: bodyBId,
      restLength: length,
      stiffness: stiffness,
      damping: damping
    };
    this.springMap.set(jId, springData);

    // 仍存入 jointInfoMap 用于渲染
    const info: JointInfo = {
      type: 'spring', bodyAId: bodyAId, bodyBId: bodyBId,
      maxLength: length, stiffness: stiffness
    };
    this.jointInfoMap.set(jId, info);
  }

  // ====== 每帧施加弹簧力（胡克定律 F = k * Δx + damping）======
  applySpringForces(): void {
    this.springMap.forEach((s: SpringData) => {
      const bodyA: box2d.b2Body | undefined = this.bodyMap.get(s.bodyAId);
      const bodyB: box2d.b2Body | undefined = this.bodyMap.get(s.bodyBId);
      if (bodyA === undefined || bodyB === undefined) return;

      const posA: box2d.b2Vec2 = bodyA.GetWorldCenter();
      const posB: box2d.b2Vec2 = bodyB.GetWorldCenter();
      const dx: number = posB.x - posA.x;
      const dy: number = posB.y - posA.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist < 0.0001) return;

      // 胡克定律：F_spring = k * (当前长度 - 原始长度)
      const stretch: number = dist - s.restLength;
      const springForce: number = s.stiffness * stretch;

      // 阻尼力（沿弹簧方向的速度差）
      const nx: number = dx / dist;
      const ny: number = dy / dist;
      const velA: box2d.b2Vec2 = bodyA.GetLinearVelocity();
      const velB: box2d.b2Vec2 = bodyB.GetLinearVelocity();
      const relVelAlong: number = (velB.x - velA.x) * nx + (velB.y - velA.y) * ny;
      const dampForce: number = s.damping * relVelAlong;

      const totalForce: number = springForce + dampForce;
      const fx: number = totalForce * nx;
      const fy: number = totalForce * ny;

      bodyA.ApplyForceToCenter(new box2d.b2Vec2(fx, fy), true);
      bodyB.ApplyForceToCenter(new box2d.b2Vec2(-fx, -fy), true);
    });
  }

  createRevoluteJoint(bodyAId: string, bodyBId: string,
    anchorX: number, anchorY: number): void {
    const bodyA: box2d.b2Body | undefined = this.bodyMap.get(bodyAId);
    const bodyB: box2d.b2Body | undefined = this.bodyMap.get(bodyBId);
    if (bodyA === undefined || bodyB === undefined) return;

    const jd: box2d.b2RevoluteJointDef = new box2d.b2RevoluteJointDef();
    const anchor: box2d.b2Vec2 = new box2d.b2Vec2(anchorX, anchorY);
    jd.Initialize(bodyA, bodyB, anchor);

    const joint: box2d.b2Joint = this.world.CreateJoint(jd);
    const jId: string = 'j_' + this.nextJointId.toString();
    this.nextJointId += 1;
    const info: JointInfo = {
      type: 'revolute', bodyAId: bodyAId, bodyBId: bodyBId,
      maxLength: 0, stiffness: 0
    };
    this.jointInfoMap.set(jId, info);
    this.jointMap.set(jId, joint);
  }

  createWeldJoint(bodyAId: string, bodyBId: string): void {
    const bodyA: box2d.b2Body | undefined = this.bodyMap.get(bodyAId);
    const bodyB: box2d.b2Body | undefined = this.bodyMap.get(bodyBId);
    if (bodyA === undefined || bodyB === undefined) return;

    const jd: box2d.b2WeldJointDef = new box2d.b2WeldJointDef();
    jd.Initialize(bodyA, bodyB, bodyA.GetWorldCenter());

    const joint: box2d.b2Joint = this.world.CreateJoint(jd);
    const jId: string = 'j_' + this.nextJointId.toString();
    this.nextJointId += 1;
    const info: JointInfo = {
      type: 'weld', bodyAId: bodyAId, bodyBId: bodyBId,
      maxLength: 0, stiffness: 0
    };
    this.jointInfoMap.set(jId, info);
    this.jointMap.set(jId, joint);
  }

  createRopeJoint(bodyAId: string, bodyBId: string, maxLength: number): void {
    const bodyA: box2d.b2Body | undefined = this.bodyMap.get(bodyAId);
    const bodyB: box2d.b2Body | undefined = this.bodyMap.get(bodyBId);
    if (bodyA === undefined || bodyB === undefined) return;

    const jd: box2d.b2RopeJointDef = new box2d.b2RopeJointDef();
    jd.bodyA = bodyA;
    jd.bodyB = bodyB;
    jd.localAnchorA.x = 0;
    jd.localAnchorA.y = 0;
    jd.localAnchorB.x = 0;
    jd.localAnchorB.y = 0;
    jd.maxLength = maxLength;

    const joint: box2d.b2Joint = this.world.CreateJoint(jd);
    const jId: string = 'j_' + this.nextJointId.toString();
    this.nextJointId += 1;
    const info: JointInfo = {
      type: 'rope', bodyAId: bodyAId, bodyBId: bodyBId,
      maxLength: maxLength, stiffness: 0
    };
    this.jointInfoMap.set(jId, info);
    this.jointMap.set(jId, joint);
  }

  // ====== 关节查询(用于渲染) ======
  forEachJointInfo(callback: (info: JointInfo) => void): void {
    this.jointInfoMap.forEach((info: JointInfo) => {
      callback(info);
    });
  }

  // ====== 绳索松弛比例 ======
  getRopeJointSlackRatio(jointId: string): number {
    const joint: box2d.b2Joint | undefined = this.jointMap.get(jointId);
    if (joint === undefined) return 0;
    if (joint.GetType() !== box2d.b2JointType.e_ropeJoint) return 0;
    // 计算两个物体的当前距离
    const info: JointInfo | undefined = this.jointInfoMap.get(jointId);
    if (info === undefined) return 0;
    const posA: Point | null = this.getBodyPosition(info.bodyAId);
    const posB: Point | null = this.getBodyPosition(info.bodyBId);
    if (posA === null || posB === null) return 0;
    const dx: number = posB.x - posA.x;
    const dy: number = posB.y - posA.y;
    const currentDist: number = Math.sqrt(dx * dx + dy * dy);
    const maxLen: number = info.maxLength;
    if (maxLen <= 0) return 0;
    return Math.max(0, 1 - currentDist / maxLen);
  }

  // ====== 管理 ======
  removeBody(id: string): void {
    const body: box2d.b2Body | undefined = this.bodyMap.get(id);
    if (body !== undefined) {
      this.world.DestroyBody(body);
      this.bodyMap.delete(id);
    }
  }

  removeBodies(ids: string[]): void {
    for (const id of ids) {
      this.removeBody(id);
    }
  }

  getBody(id: string): box2d.b2Body | undefined {
    return this.bodyMap.get(id);
  }

  getBodyPosition(id: string): Point | null {
    const body: box2d.b2Body | undefined = this.bodyMap.get(id);
    if (body === undefined) return null;
    const pos: box2d.b2Vec2 = body.GetPosition();
    const result: Point = { x: pos.x, y: pos.y };
    return result;
  }

  getBodyRuntimeData(id: string): BodyRuntimeData | undefined {
    const body: box2d.b2Body | undefined = this.bodyMap.get(id);
    if (body === undefined) return undefined;
    const ud: Object | undefined = body.GetUserData();
    if (ud === undefined) return undefined;
    return ud as BodyRuntimeData;
  }

  setBodyPosition(id: string, x: number, y: number, angle: number): void {
    const body: box2d.b2Body | undefined = this.bodyMap.get(id);
    if (body !== undefined) {
      const xf: box2d.b2Transform = new box2d.b2Transform();
      xf.p.x = x;
      xf.p.y = y;
      xf.q.SetAngle(angle);
      body.SetTransform(xf);
    }
  }

  setBodyLinearVelocity(id: string, vx: number, vy: number): void {
    const body: box2d.b2Body | undefined = this.bodyMap.get(id);
    if (body !== undefined) {
      const vel: box2d.b2Vec2 = new box2d.b2Vec2(vx, vy);
      body.SetLinearVelocity(vel);
    }
  }

  setBodyType(id: string, dynamicsType: string): void {
    const body: box2d.b2Body | undefined = this.bodyMap.get(id);
    if (body !== undefined) {
      body.SetType(this.toB2BodyType(dynamicsType));
    }
  }

  applyForce(id: string, fx: number, fy: number): void {
    const body: box2d.b2Body | undefined = this.bodyMap.get(id);
    if (body !== undefined) {
      const force: box2d.b2Vec2 = new box2d.b2Vec2(fx, fy);
      body.ApplyForceToCenter(force, true);
    }
  }

  // ====== 仿真 ======
  step(timeStep: number, velIter: number, posIter: number): void {
    this.world.Step(timeStep, velIter, posIter);
  }

  setGravity(x: number, y: number): void {
    const grav: box2d.b2Vec2 = new box2d.b2Vec2(x, y);
    this.world.SetGravity(grav);
  }

  // ====== 查询 ======
  queryPoint(worldX: number, worldY: number): string | null {
    let closestId: string | null = null;
    let closestDist: number = 0.6;

    this.bodyMap.forEach((body: box2d.b2Body, id: string) => {
      if (id.startsWith('wall_')) return;
      const pos: box2d.b2Vec2 = body.GetPosition();
      const dx: number = pos.x - worldX;
      const dy: number = pos.y - worldY;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist < closestDist) {
        closestDist = dist;
        closestId = id;
      }
    });
    return closestId;
  }

  forEachBody(callback: (body: box2d.b2Body, id: string, data: BodyRuntimeData | undefined) => void): void {
    this.bodyMap.forEach((body: box2d.b2Body, id: string) => {
      if (id.startsWith('wall_')) return;
      const ud: Object | undefined = body.GetUserData();
      const data: BodyRuntimeData | undefined = ud !== undefined ? (ud as BodyRuntimeData) : undefined;
      callback(body, id, data);
    });
  }

  getBodyCount(): number {
    let count: number = 0;
    this.bodyMap.forEach((_body: box2d.b2Body, id: string) => {
      if (!id.startsWith('wall_')) count += 1;
    });
    return count;
  }

  // ====== 生命周期 ======
  clearAll(): void {
    this.bodyMap.forEach((body: box2d.b2Body, id: string) => {
      if (id.startsWith('wall_')) return;
      this.world.DestroyBody(body);
    });
    const newMap: Map<string, box2d.b2Body> = new Map();
    this.bodyMap.forEach((body: box2d.b2Body, id: string) => {
      if (id.startsWith('wall_')) {
        newMap.set(id, body);
      }
    });
    this.bodyMap = newMap;
    this.jointInfoMap.clear();
    this.jointMap.clear();
    this.springMap.clear();
    this.nextBodyId = 0;
    this.nextJointId = 0;
  }

  // ====== 工具方法 ======
  private toB2BodyType(dt: string): box2d.b2BodyType {
    if (dt === 'static') return box2d.b2BodyType.b2_staticBody;
    if (dt === 'kinematic') return box2d.b2BodyType.b2_kinematicBody;
    return box2d.b2BodyType.b2_dynamicBody;
  }

  genBodyId(): string {
    const id: string = 'b_' + this.nextBodyId.toString();
    this.nextBodyId += 1;
    return id;
  }

  // 导入场景后更新 nextBodyId，避免与已导入物体 ID 冲突
  syncNextBodyId(): void {
    let maxId: number = 0;
    this.bodyMap.forEach((_body: box2d.b2Body, id: string) => {
      if (id.startsWith('b_')) {
        const num: number = parseInt(id.substring(2));
        if (!isNaN(num) && num >= maxId) {
          maxId = num + 1;
        }
      }
    });
    if (maxId > this.nextBodyId) {
      this.nextBodyId = maxId;
    }
  }

  // ====== 导出场景数据（保存用） ======
  exportAllBodyDefs(): BodyDef[] {
    const defs: BodyDef[] = [];
    this.bodyMap.forEach((body: box2d.b2Body, id: string) => {
      // 只排除墙壁，nodes 和 anchors 也需要导出（弹簧/绳索依赖它们）
      if (id.startsWith('wall_')) return;
      const udObj: Object | undefined = body.GetUserData();
      if (udObj === undefined) return;
      const ud: BodyRuntimeData = udObj as BodyRuntimeData;
      const pos: box2d.b2Vec2 = body.GetPosition();
      const vel: box2d.b2Vec2 = body.GetLinearVelocity();

      const def: BodyDef = {
        id: ud.id,
        shapeType: ud.shapeType as BodyShapeType,
        dynamicsType: ud.isFixed ? BodyDynamicsType.STATIC : BodyDynamicsType.DYNAMIC,
        x: pos.x,
        y: pos.y,
        angle: body.GetAngle(),
        width: ud.width,
        height: ud.height,
        radius: ud.radius,
        density: 1.0,
        friction: ud.friction,
        restitution: ud.restitution,
        color: ud.color,
        opacity: ud.opacity,
        lineWidth: ud.lineWidth,
        gravityScale: body.GetGravityScale(),
        fixedRotation: body.IsFixedRotation(),
        isLocked: ud.isLocked,
        linearVelocityX: vel.x,
        linearVelocityY: vel.y,
        angularVelocity: body.GetAngularVelocity(),
        name: ud.name,
        dragVelocityX: ud.dragVelocityX || 0,
        dragVelocityY: ud.dragVelocityY || 0
      };
      defs.push(def);
    });
    return defs;
  }

  exportAllJointDefs(): JointDef[] {
    const defs: JointDef[] = [];
    this.jointInfoMap.forEach((info: JointInfo) => {
      // 获取两个物体的位置来计算锚点
      const posA: Point | null = this.getBodyPosition(info.bodyAId);
      const posB: Point | null = this.getBodyPosition(info.bodyBId);
      const anchorX: number = posA !== null ? posA.x : 0;
      const anchorY: number = posA !== null ? posA.y : 0;
      const length: number = posA !== null && posB !== null ?
        Math.sqrt((posB.x - posA.x) ** 2 + (posB.y - posA.y) ** 2) : 0;

      const def: JointDef = {
        type: info.type as JointType,
        bodyAId: info.bodyAId,
        bodyBId: info.bodyBId,
        length: info.maxLength || length,
        stiffness: info.stiffness || 200,
        damping: 0.3,
        anchorX: anchorX,
        anchorY: anchorY,
        maxLength: info.maxLength || length
      };
      defs.push(def);
    });
    return defs;
  }
}
