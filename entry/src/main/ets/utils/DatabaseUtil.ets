import { distributedKVStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_ID: string = 'PhysicalSandboxStore';

export interface UserRecord {
  id: number;
  username: string;
  password: string;
  nickname: string;
  avatar_path: string;
  created_at: number;
  updated_at: number;
}

// ==================== 内部工具 ====================

let gKvStore: distributedKVStore.SingleKVStore | null = null;

async function getKvStore(context: common.Context): Promise<distributedKVStore.SingleKVStore> {
  if (gKvStore !== null) {
    return gKvStore;
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
  gKvStore = await kvManager.getKVStore(STORE_ID, options) as distributedKVStore.SingleKVStore;
  return gKvStore;
}

// 安全读取字符串，key 不存在时返回默认值
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

function userKey(username: string): string {
  return 'user_' + username;
}

function listKey(): string {
  return 'user_list';
}

// ==================== 注册 ====================

export async function registerUser(
  context: common.Context,
  username: string,
  password: string,
  nickname: string
): Promise<number> {
  const kvStore: distributedKVStore.SingleKVStore = await getKvStore(context);

  // ID 计数器
  const counterStr: string = await readString(kvStore, 'id_counter', '0');
  let idCounter: number = parseInt(counterStr);
  idCounter = idCounter + 1;
  kvStore.put('id_counter', idCounter.toString());

  // 用户名列表
  let nameList: string = await readString(kvStore, listKey(), '');
  if (nameList === '') {
    nameList = username;
  } else {
    nameList = nameList + ',' + username;
  }
  kvStore.put(listKey(), nameList);

  // 用户数据
  const now: number = Date.now();
  const user: UserRecord = {
    id: idCounter,
    username: username,
    password: password,
    nickname: nickname,
    avatar_path: '',
    created_at: now,
    updated_at: now
  };
  kvStore.put(userKey(username), JSON.stringify(user));
  return idCounter;
}

// ==================== 登录 ====================

export async function getUserByUsername(
  context: common.Context,
  username: string
): Promise<UserRecord | null> {
  const kvStore: distributedKVStore.SingleKVStore = await getKvStore(context);
  const json: string = await readString(kvStore, userKey(username), '');
  if (json === '') {
    return null;
  }
  return JSON.parse(json) as UserRecord;
}

export async function checkUsernameExists(
  context: common.Context,
  username: string
): Promise<boolean> {
  const kvStore: distributedKVStore.SingleKVStore = await getKvStore(context);
  const json: string = await readString(kvStore, userKey(username), '');
  return json !== '';
}

// ==================== 个人中心 ====================

export async function getUserById(
  context: common.Context,
  userId: number
): Promise<UserRecord | null> {
  const kvStore: distributedKVStore.SingleKVStore = await getKvStore(context);
  const nameList: string = await readString(kvStore, listKey(), '');
  if (nameList === '') {
    return null;
  }
  const names: string[] = nameList.split(',');
  for (let i: number = 0; i < names.length; i++) {
    const json: string = await readString(kvStore, userKey(names[i]), '');
    if (json !== '') {
      const user: UserRecord = JSON.parse(json) as UserRecord;
      if (user.id === userId) {
        return user;
      }
    }
  }
  return null;
}

export async function updateNickname(
  context: common.Context,
  userId: number,
  newNickname: string
): Promise<void> {
  const user: UserRecord | null = await getUserById(context, userId);
  if (user === null) {
    return;
  }
  const kvStore: distributedKVStore.SingleKVStore = await getKvStore(context);
  user.nickname = newNickname;
  user.updated_at = Date.now();
  kvStore.put(userKey(user.username), JSON.stringify(user));
}

export async function updatePassword(
  context: common.Context,
  userId: number,
  oldPassword: string,
  newPassword: string
): Promise<boolean> {
  const user: UserRecord | null = await getUserById(context, userId);
  if (user === null || user.password !== oldPassword) {
    return false;
  }
  const kvStore: distributedKVStore.SingleKVStore = await getKvStore(context);
  user.password = newPassword;
  user.updated_at = Date.now();
  kvStore.put(userKey(user.username), JSON.stringify(user));
  return true;
}
