// get-deps.js
// Usage: node get-deps.js <platform> <browser> [<browser2> ...]
// Example: node get-deps.js ubuntu24.04-x64 chromium
// Output: one apt package per line (sorted, deduplicated)

const path = require('path');
// nativeDeps is not in the package exports, so we resolve it directly
const nativeDepsPath = path.join(
  path.dirname(require.resolve('playwright-core/package.json')),
  'lib', 'server', 'registry', 'nativeDeps.js'
);
const { deps } = require(nativeDepsPath);

const [platform, ...browsers] = process.argv.slice(2);

if (!platform || browsers.length === 0) {
  console.error('Usage: node get-deps.js <platform> <browser> [<browser2> ...]');
  console.error('Platforms:', Object.keys(deps).join(', '));
  process.exit(1);
}

const platformDeps = deps[platform];
if (!platformDeps) {
  console.error(`Unknown platform: ${platform}`);
  console.error('Available:', Object.keys(deps).join(', '));
  process.exit(1);
}

const allDeps = new Set();

// Always include "tools" (fonts, xvfb, etc.)
if (platformDeps.tools) {
  platformDeps.tools.forEach(d => allDeps.add(d));
}

for (const browser of browsers) {
  const browserDeps = platformDeps[browser];
  if (!browserDeps) {
    console.error(`Unknown browser "${browser}" for platform "${platform}"`);
    console.error('Available:', Object.keys(platformDeps).join(', '));
    process.exit(1);
  }
  browserDeps.forEach(d => allDeps.add(d));
}

for (const dep of [...allDeps].sort()) {
  console.log(dep);
}