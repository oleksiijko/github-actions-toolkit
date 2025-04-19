const fs = require('fs');
const path = require('path');

const [,, basePath, headPath] = process.argv;

const base = JSON.parse(fs.readFileSync(basePath, 'utf-8'));
const head = JSON.parse(fs.readFileSync(headPath, 'utf-8'));

const bDeps = base.dependencies || {};
const hDeps = head.dependencies || {};

const added = [];
const removed = [];
const changed = [];

for (const dep in bDeps) {
  if (!(dep in hDeps)) {
    removed.push(dep);
  } else if (bDeps[dep].version !== hDeps[dep].version) {
    changed.push({ name: dep, from: bDeps[dep].version, to: hDeps[dep].version });
  }
}

for (const dep in hDeps) {
  if (!(dep in bDeps)) {
    added.push(dep);
  }
}

const lines = [];

lines.push(`## 📦 Dependency Diff\n`);

if (added.length) {
  lines.push(`### ➕ Added`);
  for (const dep of added) {
    lines.push(`- \`${dep}@${hDeps[dep].version}\``);
  }
}

if (removed.length) {
  lines.push(`### ➖ Removed`);
  for (const dep of removed) {
    lines.push(`- \`${dep}@${bDeps[dep].version}\``);
  }
}

if (changed.length) {
  lines.push(`### 🔄 Updated`);
  for (const { name, from, to } of changed) {
    lines.push(`- \`${name}\` from \`${from}\` → \`${to}\``);
  }
}

if (added.length === 0 && removed.length === 0 && changed.length === 0) {
  lines.push(`✅ No changes in dependencies.`)
}

fs.writeFileSync('diff.md', lines.join('\n') + '\n');
