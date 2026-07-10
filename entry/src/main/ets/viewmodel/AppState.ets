import { EditorTool } from '../model/Types';
import { Defaults } from '../common/Constants';

@Observed
export class AppState {
  // 仿真控制
  isRunning: boolean = false;

  // 工具选择
  currentTool: EditorTool = EditorTool.CIRCLE;

  // 全局物理参数
  gravityX: number = Defaults.GRAVITY_X;
  gravityY: number = Defaults.GRAVITY_Y;
  airResistance: number = Defaults.AIR_RESISTANCE;
  simulationSpeed: number = Defaults.SIMULATION_SPEED;

  // 显示开关
  showGrid: boolean = true;
  showTrajectory: boolean = true;
  snapToGrid: boolean = true;

  // 选中物体
  selectedBodyId: string = '';

  // 统计
  bodyCount: number = 0;

  // 面板可见性
  showPropertyPanel: boolean = false;

  // 场景名
  sceneName: string = '未命名场景';
}
