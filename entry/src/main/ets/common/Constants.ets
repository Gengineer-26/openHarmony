// ====== 沉浸光感主题色板 ======
export class Colors {
  static readonly BACKGROUND: string = '#F0F2F7';
  static readonly SURFACE: string = '#FFFFFF';
  static readonly CANVAS_BG: string = '#EFF1F4';
  static readonly GRID_LINE: string = '#DDE0E5';
  static readonly GRID_MAJOR: string = '#CDD0D8';
  static readonly BORDER: string = '#E4E7ED';
  static readonly TEXT_PRIMARY: string = '#1A1A2E';
  static readonly TEXT_SECONDARY: string = '#505570';
  static readonly TEXT_HINT: string = '#9CA0B0';
  static readonly PRIMARY: string = '#4F6EF7';
  static readonly PRIMARY_LIGHT: string = '#E8ECFF';
  static readonly ACCENT: string = '#00B8A9';
  static readonly ACCENT_LIGHT: string = '#E0F7F5';
  static readonly PLAY: string = '#22C55E';
  static readonly PAUSE: string = '#F59E0B';
  static readonly RESET: string = '#EF4444';
  static readonly RESET_LIGHT: string = '#FEE2E2';
  static readonly BODY_CIRCLE: string = '#4DB6AC';
  static readonly BODY_RECTANGLE: string = '#EF7060';
  static readonly BODY_TRIANGLE: string = '#AB47BC';
  static readonly BODY_STATIC: string = '#78909C';
  static readonly BODY_SELECTED: string = '#42A5F5';
  static readonly TRAJECTORY: string = '#FBBF24';
  static readonly FORCE: string = '#FF5252';
  static readonly TOOL_ACTIVE: string = '#E8ECFF';
  static readonly BOOLEAN_OP: string = '#FF6F00';
  static readonly ROPE: string = '#795548';
  static readonly SPRING: string = '#F59E0B';
  // 光感玻璃态
  static readonly AUTH_GRADIENT_START: string = '#667eea';
  static readonly AUTH_GRADIENT_END: string = '#764ba2';
  static readonly GLASS_BG: string = 'rgba(255,255,255,0.78)';
  static readonly GLASS_BG_THICK: string = 'rgba(255,255,255,0.94)';
  static readonly GLASS_BG_DARK: string = 'rgba(255,255,255,0.55)';
  static readonly CARD_SHADOW: string = 'rgba(0,0,0,0.06)';
  static readonly DIALOG_SHADOW: string = 'rgba(0,0,0,0.18)';
  static readonly PROFILE_PRIMARY: string = '#4F6EF7';
  static readonly PROFILE_ACCENT: string = '#764ba2';
  // Tab 激活色
  static readonly TAB_ACTIVE: string = '#4F6EF7';
  static readonly TAB_INACTIVE: string = '#9CA0B0';
}

// ====== 尺寸常量 ======
export class Sizes {
  static readonly TOOL_BAR_WIDTH: number = 60;
  static readonly TOOL_BAR_HEIGHT: number = 56;
  static readonly PROPERTY_PANEL_WIDTH: number = 260;
  static readonly CONTROL_BAR_HEIGHT: number = 48;
  static readonly TOP_BAR_HEIGHT: number = 44;
  static readonly BREAKPOINT_TABLET: number = 840;
  static readonly BREAKPOINT_MD: number = 600;
}

// ====== 默认物理参数 ======
export class Defaults {
  static readonly GRAVITY_X: number = 0;
  static readonly GRAVITY_Y: number = 9.8;
  static readonly FRICTION: number = 0.0;
  static readonly RESTITUTION: number = 0.0;
  static readonly DENSITY: number = 1.0;
  static readonly AIR_RESISTANCE: number = 0.01;
  static readonly SIMULATION_SPEED: number = 1.0;
  static readonly NAME: string = '物体';
  static readonly SPRING_STIFFNESS: number = 200.0;  // 胡克定律刚度 N/m
  static readonly VELOCITY_MAGNITUDE: number = 0;
  static readonly VELOCITY_ANGLE: number = 0;
  static readonly DRAG_VELOCITY_FACTOR: number = 0.5;
  static readonly MIN_SIZE: number = 0.5;
}

// ====== 字符串文本 ======
export class Texts {
  static readonly APP_NAME: string = '物理沙盒';
  static readonly TOOL_CIRCLE: string = '圆形';
  static readonly TOOL_RECT: string = '矩形';
  static readonly TOOL_TRIANGLE: string = '三角';
  static readonly TOOL_SELECT: string = '选择';
  static readonly TOOL_ERASER: string = '橡皮';
  static readonly TOOL_SPRING: string = '弹簧';
  static readonly TOOL_ROPE: string = '绳索';
  static readonly TOOL_HINGE: string = '铰链';
  static readonly TOOL_ROD: string = '杆件';
  static readonly TOOL_ANCHOR: string = '锚点';
  static readonly BTN_START: string = '启动';
  static readonly BTN_PAUSE: string = '暂停';
  static readonly BTN_STEP: string = '单步';
  static readonly BTN_RESET: string = '重置';
  static readonly BTN_SAVE: string = '保存';
  static readonly BTN_LOAD: string = '加载';
  static readonly BTN_CLEAR: string = '清空';
  static readonly LBL_OBJECTS: string = '物体';
  static readonly LBL_GRAVITY: string = '重力';
  static readonly LBL_FRICTION: string = '摩擦';
  static readonly LBL_RESTITUTION: string = '弹性';
  static readonly LBL_SPEED: string = '速度';
  static readonly LBL_TRAJECTORY: string = '轨迹';
  static readonly LBL_MASS: string = '质量';
  static readonly LBL_COLOR: string = '颜色';
  static readonly LBL_OPACITY: string = '不透明';
  static readonly LBL_OUTLINE: string = '轮廓';
  static readonly LBL_VELOCITY_DIR: string = '速度方向';
  static readonly LBL_VELOCITY_MAG: string = '速度大小';
  static readonly LBL_NAME: string = '名称';
  static readonly LBL_FIXED: string = '固定';
  static readonly LBL_STIFFNESS: string = '刚度';
  static readonly LBL_FIXED_ROT: string = '固定旋转';
  static readonly LBL_GRAVITY_SCALE: string = '重力比';
  static readonly BOOL_UNION: string = '结合';
  static readonly BOOL_SUBTRACT: string = '剪除';
  static readonly BOOL_INTERSECT: string = '相交';
  static readonly BOOL_TITLE: string = '布尔运算';
  // 认证相关
  static readonly LOGIN_TITLE: string = '登录';
  static readonly LOGIN_WELCOME: string = '欢迎回到物理沙盒';
  static readonly REGISTER_TITLE: string = '创建账号';
  static readonly REGISTER_SUBTITLE: string = '加入物理沙盒世界';
  static readonly PROFILE_TITLE: string = '个人中心';
  static readonly LABEL_USERNAME: string = '用户名';
  static readonly LABEL_PASSWORD: string = '密码';
  static readonly LABEL_CONFIRM_PWD: string = '确认密码';
  static readonly LABEL_NICKNAME: string = '昵称';
  static readonly LABEL_OLD_PWD: string = '旧密码';
  static readonly LABEL_NEW_PWD: string = '新密码';
  static readonly BTN_LOGIN: string = '登录';
  static readonly BTN_REGISTER: string = '注册';
  static readonly BTN_LOGOUT: string = '退出登录';
  static readonly BTN_SAVE_CHANGE: string = '保存';
  static readonly BTN_CANCEL: string = '取消';
  static readonly LINK_TO_REGISTER: string = '还没有账号？立即注册';
  static readonly LINK_TO_LOGIN: string = '已有账号？返回登录';
  static readonly PROFILE_EDIT_NICKNAME: string = '修改昵称';
  static readonly PROFILE_EDIT_PASSWORD: string = '修改密码';
  static readonly PROFILE_EDIT_AVATAR: string = '更换头像';
  static readonly ERR_USERNAME_FORMAT: string = '用户名需4-20位字母、数字、下划线或中文';
  static readonly ERR_PASSWORD_FORMAT: string = '密码至少8位，需包含字母和数字';
  static readonly ERR_PASSWORD_MISMATCH: string = '两次密码不一致';
  static readonly ERR_NICKNAME_FORMAT: string = '昵称需1-16个字符';
  static readonly ERR_LOGIN_FAILED: string = '用户名或密码错误';
  static readonly ERR_USERNAME_EXISTS: string = '用户名已存在';
  static readonly ERR_REGISTER_FAILED: string = '注册失败，请重试';
  static readonly ERR_OLD_PASSWORD_WRONG: string = '旧密码错误';
  static readonly SUCCESS_REGISTER: string = '注册成功，请登录';
  static readonly SUCCESS_UPDATE: string = '修改成功';
  static readonly APP_VERSION: string = '物理沙盒 v1.0.0';
}
