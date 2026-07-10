// ====== 2D向量类 ======
export class Vec2 {
  x: number = 0;
  y: number = 0;
}

// ====== 工具枚举 ======
export enum EditorTool {
  SELECT = 0,
  CIRCLE = 1,
  RECTANGLE = 2,
  ERASER = 3,
  SPRING = 4,
  ROPE = 5,
  HINGE = 6,
  ROD = 7,
  ANCHOR = 8,
  TRIANGLE = 9
}

// ====== 形状/动力学类型 ======
export enum BodyShapeType {
  CIRCLE = 'circle',
  RECTANGLE = 'rectangle',
  TRIANGLE = 'triangle',
  POLYGON = 'polygon'
}

export enum BodyDynamicsType {
  STATIC = 'static',
  DYNAMIC = 'dynamic',
  KINEMATIC = 'kinematic'
}

export enum JointType {
  DISTANCE = 'distance',
  REVOLUTE = 'revolute',
  WELD = 'weld'
}

// ====== 布尔运算类型 ======
export enum BooleanOpType {
  UNION = 'union',
  SUBTRACT = 'subtract',
  INTERSECT = 'intersect'
}

// ====== 多边形数据 ======
export interface Polygon {
  vertices: Point[];     // ordered CCW, max 8
  centroid: Point;
  area: number;
}

// ====== 刚体创建定义 ======
export interface BodyDef {
  id: string;
  shapeType: BodyShapeType;
  dynamicsType: BodyDynamicsType;
  x: number;
  y: number;
  angle: number;
  width: number;
  height: number;
  radius: number;
  density: number;
  friction: number;
  restitution: number;
  color: string;
  opacity: number;
  lineWidth: number;
  gravityScale: number;
  fixedRotation: boolean;
  isLocked: boolean;
  linearVelocityX: number;
  linearVelocityY: number;
  angularVelocity: number;
  // 新增字段
  name: string;
  dragVelocityX: number;
  dragVelocityY: number;
}

// ====== 关节创建定义 ======
export interface JointDef {
  type: JointType;
  bodyAId: string;
  bodyBId: string;
  length: number;
  stiffness: number;
  damping: number;
  anchorX: number;
  anchorY: number;
  maxLength: number;
}

// ====== 运行时刚体元数据(附在b2Body.UserData) ======
export interface BodyRuntimeData {
  id: string;
  shapeType: string;
  dynamicsType: string;
  color: string;
  opacity: number;
  lineWidth: number;
  width: number;
  height: number;
  radius: number;
  mass: number;
  friction: number;
  restitution: number;
  isLocked: boolean;
  // 新增字段
  name: string;
  velocityAngle: number;
  velocityMagnitude: number;
  springStiffness: number;
  isFixed: boolean;
  dragVelocityX: number;
  dragVelocityY: number;
}

// ====== 工具栏按钮定义 ======
export interface ToolItem {
  id: number;
  label: string;
  icon: string;
  color: string;
}

// ====== 属性面板显示数据 ======
export interface BodyInfo {
  id: string;
  shapeType: string;
  dynamicsType: string;
  color: string;
  opacity: number;
  lineWidth: number;
  mass: number;
  friction: number;
  restitution: number;
  gravityScale: number;
  fixedRotation: boolean;
  isLocked: boolean;
  width: number;
  height: number;
  radius: number;
  // 新增字段
  name: string;
  velocityAngle: number;
  velocityMagnitude: number;
  springStiffness: number;
  isFixed: boolean;
}

// ====== 场景数据 ======
export interface SceneData {
  name: string;
  timestamp: number;
  gravityX: number;
  gravityY: number;
  airResistance: number;
  simulationSpeed: number;
  bodies: BodyDef[];
  joints: JointDef[];
}

// ====== 2D坐标点(轻量) ======
export interface Point {
  x: number;
  y: number;
}

// ====== 平移偏移 ======
export interface PanOffset {
  x: number;
  y: number;
}

// ====== 属性变更请求 ======
export interface PropertyChange {
  id: string;
  key: string;
  value: Object;
}

// ====== 布尔运算请求 ======
export interface BooleanOpRequest {
  opType: string;
  idA: string;
  idB: string;
}

// ====== 场景导入数据 ======
export interface SceneImportData {
  bodies: BodyDef[];
  joints: JointDef[];
}
