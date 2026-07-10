// 简单的表单校验工具（大学生作业级别，不做复杂加密）

export function validateUsername(username: string): string {
  if (username.trim().length < 4 || username.trim().length > 20) {
    return '用户名需4-20位字符';
  }
  const validPattern: RegExp = /^[a-zA-Z0-9_一-龥]+$/;
  if (!validPattern.test(username)) {
    return '用户名只能包含字母、数字、下划线或中文';
  }
  return '';
}

export function validatePassword(password: string): string {
  if (password.length < 6) {
    return '密码至少6位';
  }
  return '';
}

export function validateNickname(nickname: string): string {
  const trimmed: string = nickname.trim();
  if (trimmed.length < 1 || trimmed.length > 16) {
    return '昵称需1-16个字符';
  }
  return '';
}
