// 校验 configure.bat 生成的两份配置是否自洽、是否合法。
const fs = require('node:fs');
const path = require('node:path');

const dir = process.argv[2];
const authPath = path.join(dir, 'codex-home', 'auth.json');
const tomlPath = path.join(dir, 'codex-home', 'config.toml');

let pass = 0;
const check = (name, fn) => {
  try {
    const ok = fn();
    if (ok === false) throw new Error('断言为假');
    pass += 1;
    console.log(`  ✓ ${name}`);
  } catch (e) {
    console.error(`  ✗ ${name}\n    ${e.message}`);
    process.exitCode = 1;
  }
};

check('auth.json 是合法 JSON', () => {
  const j = JSON.parse(fs.readFileSync(authPath, 'utf8'));
  if (j.auth_mode !== 'apikey') throw new Error('auth_mode 不是 apikey');
  if (!j.OPENAI_API_KEY) throw new Error('缺 OPENAI_API_KEY');
  return true;
});

const toml = fs.readFileSync(tomlPath, 'utf8');

check('config.toml 有 openai_base_url', () => /^openai_base_url = ".+"$/m.test(toml));
check('config.toml 有 model_provider', () => /^model_provider = ".+"$/m.test(toml));

check('model_provider 与 [model_providers.X] 一致', () => {
  const mp = /^model_provider = "(.+)"$/m.exec(toml)?.[1];
  if (!mp) throw new Error('取不到 model_provider');
  if (!toml.includes(`[model_providers.${mp}]`)) {
    throw new Error(`model_provider="${mp}" 但没有 [model_providers.${mp}] 段`);
  }
  return true;
});

check('base_url 与 openai_base_url 一致', () => {
  const top = /^openai_base_url = "(.+)"$/m.exec(toml)?.[1];
  const inner = /^base_url = "(.+)"$/m.exec(toml)?.[1];
  if (top !== inner) throw new Error(`顶层 ${top} != 段内 ${inner}`);
  return true;
});

check('地址末尾没有多余斜杠（会拼成 //chat/completions）', () => {
  const top = /^openai_base_url = "(.+)"$/m.exec(toml)?.[1];
  if (top.endsWith('/')) throw new Error(`末尾有斜杠：${top}`);
  return true;
});

check('provider 名是合法的 TOML 裸键', () => {
  const mp = /^model_provider = "(.+)"$/m.exec(toml)?.[1];
  if (!/^[A-Za-z][A-Za-z0-9_-]*$/.test(mp)) throw new Error(`非法键名：${mp}`);
  return true;
});

check('auth.json 里没有多余的空行（覆盖写而非追加）', () => {
  const raw = fs.readFileSync(authPath, 'utf8');
  const lines = raw.split('\n').filter((l) => l.trim() !== '');
  if (lines.length !== 4) throw new Error(`实际 ${lines.length} 行有效内容，应为 4`);
  return true;
});

console.log(`\n通过：${pass} 项`);
