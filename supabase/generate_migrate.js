// 从 index.html 提取种子数据，生成 migrate.sql
// 用法: node generate_migrate.js
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const HTML = '/Users/mini/workbuddy-ai/粤春考助手/index.html';
const OUT = '/Users/mini/workbuddy-ai/粤春考助手/supabase/migrate.sql';

const html = fs.readFileSync(HTML, 'utf8');
const m = html.match(/<script>([\s\S]*?)<\/script>/);
if (!m) throw new Error('未找到 <script> 代码块');
let code = m[1];

// ---- 浏览器环境 stub ----
const store = new Map();
const localStorage = {
  getItem: (k) => (store.has(k) ? store.get(k) : null),
  setItem: (k, v) => store.set(k, String(v)),
  removeItem: (k) => store.delete(k),
};
const elStub = () => ({
  style: {}, classList: { add() {}, remove() {}, toggle() {} },
  appendChild() {}, remove() {}, setAttribute() {},
  textContent: '', innerHTML: '', value: '', dataset: {},
  addEventListener() {}, querySelectorAll: () => [], querySelector: () => null,
});
const document = {
  addEventListener() {}, getElementById: () => elStub(),
  querySelectorAll: () => [], querySelector: () => null,
  createElement: () => elStub(),
  body: elStub(),
};
const sandbox = {
  console, localStorage, document, window: { addEventListener() {}, document, localStorage },
  navigator: {}, setTimeout, clearTimeout, setInterval, clearInterval,
  Date, JSON, Math, Object, Array, String, Number, Boolean, RegExp,
  parseInt, parseFloat, isNaN, confirm: () => true, alert() {}, fetch() {},
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);

// 运行脚本后把 DB 暴露出来
code += '\n;globalThis.__DB = DB;';
vm.runInContext(code, sandbox);
const DB = sandbox.__DB;

// ---- 提取数据 ----
const keys = ['questions', 'words', 'templates', 'scoreLines', 'materials', 'essayMaterials', 'policies', 'announcements'];
const data = {};
for (const k of keys) data[k] = DB.get(k) || [];

console.log('提取统计:', JSON.stringify({
  questions: data.questions.length,
  words: data.words.length,
  templates: data.templates.length,
  scoreLines: data.scoreLines.length,
  materials: data.materials.length,
  essayMaterials: data.essayMaterials.length,
  policies: data.policies.length,
  announcements: data.announcements.length,
}));

// ---- SQL 生成辅助 ----
function sqlStr(v) {
  if (v === null || v === undefined) return 'NULL';
  return "'" + String(v).replace(/'/g, "''") + "'";
}
function sqlNum(v) {
  if (v === null || v === undefined || v === '') return 'NULL';
  return String(Number(v));
}
function insert(table, cols, rows) {
  const colSql = cols.join(', ');
  const lines = rows.map((r) => '(' + r.join(', ') + ')');
  return `insert into public.${table} (${colSql}) values\n  ${lines.join(',\n  ')}\non conflict (id) do nothing;`;
}

// ---- 各表数据转换 ----
const qRows = data.questions.map((q) => [
  sqlNum(q.id), sqlStr(q.subject), sqlStr(q.type), sqlStr(q.category),
  sqlStr(q.stem), sqlStr(JSON.stringify(q.options)), sqlNum(q.answer), sqlStr(q.analysis),
]);

const wRows = data.words.map((w) => [
  sqlNum(w.id), sqlStr(w.word), sqlStr(w.meaning), sqlStr(w.phonetic || ''),
]);

const tRows = data.templates.map((t) => [
  sqlNum(t.id), sqlStr(t.subject), sqlStr(t.category), sqlStr(t.title), sqlStr(t.content),
]);

const sRows = data.scoreLines.map((s) => [
  sqlNum(s.id), sqlNum(s.year), sqlStr(s.batch), sqlStr(s.college), sqlStr(s.major),
  sqlNum(s.score), sqlStr(s.property), sqlStr(s.region),
]);

const mRows = data.materials.map((mm, i) => [
  sqlNum(mm.id != null ? mm.id : i + 1), sqlStr(mm.name), sqlStr(mm.type), sqlStr(mm.category),
  sqlStr(mm.uploadTime || ''), sqlStr(mm.content || ''), sqlStr(mm.url || ''),
]);

const eRows = data.essayMaterials.map((e) => [
  sqlNum(e.id), sqlStr(e.type), sqlStr(e.title), sqlStr(e.content), sqlStr(e.date),
]);

const pRows = data.policies.map((p) => [
  sqlNum(p.id), sqlStr(p.title), sqlStr(p.content), sqlStr(p.date),
]);

// 公告本地无 id，按顺序补 1..N
const aRows = data.announcements.map((a, i) => [
  sqlNum(i + 1), sqlStr(a.title), sqlStr(a.content), sqlStr(a.time),
]);

// ---- 组装 SQL ----
const header = `-- ============================================================
-- 粤春考助手 · 数据迁移脚本（一次性执行）
-- 把本地种子数据灌入 Supabase，实现数据上云
-- 用法：Supabase 控制台 → SQL Editor → 粘贴全部执行一次
-- 说明：可重复执行（已存在 id 会跳过），不会产生重复数据
-- ============================================================

-- 1. 让 id 列接受显式值（应用侧用 Date.now() 或序号生成 id）
alter table public.questions       alter column id drop identity if exists;
alter table public.words           alter column id drop identity if exists;
alter table public.templates       alter column id drop identity if exists;
alter table public.score_lines     alter column id drop identity if exists;
alter table public.materials       alter column id drop identity if exists;
alter table public.essay_materials alter column id drop identity if exists;
alter table public.policies        alter column id drop identity if exists;
alter table public.announcements   alter column id drop identity if exists;

-- 2. materials 表补充上传时间列、正文内容列、文件链接列
alter table public.materials add column if not exists upload_time text;
alter table public.materials add column if not exists content text;
alter table public.materials add column if not exists file_url text;

-- ============================================================
-- 3. 灌入数据
-- ============================================================
`;

const parts = [];
parts.push('-- 题库 (' + data.questions.length + ' 条)');
parts.push(insert('questions', ['id', 'subject', 'type', 'category', 'stem', 'options', 'answer', 'analysis'], qRows));
parts.push('');
parts.push('-- 单词 (' + data.words.length + ' 条)');
parts.push(insert('words', ['id', 'word', 'meaning', 'phonetic'], wRows));
parts.push('');
parts.push('-- 答题模板 (' + data.templates.length + ' 条)');
parts.push(insert('templates', ['id', 'subject', 'category', 'title', 'content'], tRows));
parts.push('');
parts.push('-- 分数线 (' + data.scoreLines.length + ' 条)');
parts.push(insert('score_lines', ['id', 'year', 'batch', 'college', 'major', 'score', 'property', 'region'], sRows));
parts.push('');
parts.push('-- 学习资料 (' + data.materials.length + ' 条)');
parts.push(insert('materials', ['id', 'name', 'type', 'category', 'upload_time', 'content', 'file_url'], mRows));
parts.push('');
parts.push('-- 作文素材 (' + data.essayMaterials.length + ' 条)');
parts.push(insert('essay_materials', ['id', 'type', 'title', 'content', 'date'], eRows));
parts.push('');
parts.push('-- 政策解读 (' + data.policies.length + ' 条)');
parts.push(insert('policies', ['id', 'title', 'content', 'date'], pRows));
parts.push('');
parts.push('-- 公告 (' + data.announcements.length + ' 条)');
parts.push(insert('announcements', ['id', 'title', 'content', 'date'], aRows));
parts.push('');

fs.writeFileSync(OUT, header + parts.join('\n'), 'utf8');
console.log('已生成:', OUT);
