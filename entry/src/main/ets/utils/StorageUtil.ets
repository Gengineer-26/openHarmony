import { distributedKVStore } from '@kit.ArkData';
import { SceneModel } from '../model/SceneModel';
import { common } from '@kit.AbilityKit';

const STORE_ID: string = 'PhysicsSandboxScenes';

// ====== 分布式 KV 存储（场景数据自动跨设备同步） ======

let gSceneKvStore: distributedKVStore.SingleKVStore | null = null;

async function getSceneKvStore(context: common.Context): Promise<distributedKVStore.SingleKVStore> {
  if (gSceneKvStore !== null) {
    return gSceneKvStore;
  }

  const kvManagerConfig: distributedKVStore.KVManagerConfig = {
    context: context,
    bundleName: 'com.example.myapplication'
  };
  const kvManager: distributedKVStore.KVManager = distributedKVStore.createKVManager(kvManagerConfig);

  const options: distributedKVStore.Options = {
    createIfMissing: true,
    encrypt: false,
    backup: false,
    autoSync: true,
    kvStoreType: distributedKVStore.KVStoreType.DEVICE_COLLABORATION,
    securityLevel: distributedKVStore.SecurityLevel.S1
  };
  gSceneKvStore = await kvManager.getKVStore(STORE_ID, options) as distributedKVStore.SingleKVStore;
  return gSceneKvStore;
}

async function readString(kvStore: distributedKVStore.SingleKVStore, key: string, defValue: string): Promise<string> {
  try {
    const raw: string | number | boolean | Uint8Array = await kvStore.get(key);
    if (raw !== undefined && raw !== null) {
      return raw.toString();
    }
  } catch (_e) {
    // key 不存在
  }
  return defValue;
}

function sceneListKey(): string {
  return 'scene_list';
}

export class StorageUtil {
  static async saveScene(context: common.Context, scene: SceneModel): Promise<void> {
    const kvStore: distributedKVStore.SingleKVStore = await getSceneKvStore(context);
    const key: string = 'scene_' + scene.timestamp.toString();
    const json: string = JSON.stringify(scene);
    await kvStore.put(key, json);

    // 更新场景列表索引
    let listStr: string = await readString(kvStore, sceneListKey(), '');
    if (listStr === '') {
      listStr = scene.timestamp.toString();
    } else {
      listStr = listStr + ',' + scene.timestamp.toString();
    }
    await kvStore.put(sceneListKey(), listStr);
  }

  static async loadAllScenes(context: common.Context): Promise<SceneModel[]> {
    const kvStore: distributedKVStore.SingleKVStore = await getSceneKvStore(context);
    const listStr: string = await readString(kvStore, sceneListKey(), '');
    if (listStr === '') {
      return [];
    }
    const timestamps: string[] = listStr.split(',');
    const scenes: SceneModel[] = [];
    for (let i: number = 0; i < timestamps.length; i++) {
      const ts: string = timestamps[i];
      if (ts === '') continue;
      const key: string = 'scene_' + ts;
      const json: string = await readString(kvStore, key, '');
      if (json !== '') {
        try {
          const scene: SceneModel = JSON.parse(json) as SceneModel;
          scenes.push(scene);
        } catch (_e) {
          // 跳过损坏的数据
        }
      }
    }
    scenes.sort((a: SceneModel, b: SceneModel) => b.timestamp - a.timestamp);
    return scenes;
  }

  static async deleteScene(context: common.Context, timestamp: number): Promise<void> {
    const kvStore: distributedKVStore.SingleKVStore = await getSceneKvStore(context);
    const key: string = 'scene_' + timestamp.toString();
    await kvStore.delete(key);

    // 从索引列表中移除
    const listStr: string = await readString(kvStore, sceneListKey(), '');
    if (listStr !== '') {
      const timestamps: string[] = listStr.split(',');
      const filtered: string[] = [];
      const target: string = timestamp.toString();
      for (const ts of timestamps) {
        if (ts !== target) {
          filtered.push(ts);
        }
      }
      await kvStore.put(sceneListKey(), filtered.join(','));
    }
  }

  // ====== 导出场景为 JSON 字符串（用于分享） ======
  static async exportSceneJson(context: common.Context, timestamp: number): Promise<string> {
    const kvStore: distributedKVStore.SingleKVStore = await getSceneKvStore(context);
    const key: string = 'scene_' + timestamp.toString();
    const json: string = await readString(kvStore, key, '');
    return json;
  }

  // ====== 导入场景 JSON（从其他人分享的文件导入） ======
  static async importSceneJson(context: common.Context, json: string): Promise<SceneModel | null> {
    try {
      const scene: SceneModel = JSON.parse(json) as SceneModel;
      // 分配新的时间戳，避免与已有场景冲突
      scene.timestamp = Date.now();
      await StorageUtil.saveScene(context, scene);
      return scene;
    } catch (_e) {
      return null;
    }
  }
}
