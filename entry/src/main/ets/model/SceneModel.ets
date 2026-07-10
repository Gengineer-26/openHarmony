import { BodyDef, JointDef } from './Types';

export class SceneModel {
  name: string = 'Untitled';
  timestamp: number = 0;
  gravityX: number = 0;
  gravityY: number = 9.8;
  airResistance: number = 0.01;
  simulationSpeed: number = 1.0;
  bodies: BodyDef[] = [];
  joints: JointDef[] = [];
}
