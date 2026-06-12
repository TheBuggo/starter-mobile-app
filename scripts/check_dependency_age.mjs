#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const DAY_MS = 24 * 60 * 60 * 1000;
const MIN_AGE_DAYS = Number.parseInt(process.env.MIN_DEPENDENCY_AGE_DAYS ?? '30', 10);
const NOW = process.env.DEPENDENCY_CHECK_NOW
  ? new Date(process.env.DEPENDENCY_CHECK_NOW)
  : new Date();
const CUTOFF = new Date(NOW.getTime() - MIN_AGE_DAYS * DAY_MS);
const ROOT = process.cwd();

const dependencyChecks = new Map();
const failures = [];
const npmMetadataCache = new Map();
const pubMetadataCache = new Map();

if (!Number.isFinite(MIN_AGE_DAYS) || MIN_AGE_DAYS < 1) {
  fail('MIN_DEPENDENCY_AGE_DAYS must be a positive integer.');
}

if (Number.isNaN(NOW.getTime())) {
  fail('DEPENDENCY_CHECK_NOW must be a valid date when provided.');
}

collectPubDependencies();
collectNpmDependencies();
collectRemoteNpmImports();

await verifyDependencyAges();
printReport();

if (failures.length > 0) {
  process.exitCode = 1;
}

function collectPubDependencies() {
  const pubspecPath = path.join(ROOT, 'pubspec.yaml');
  if (!fs.existsSync(pubspecPath)) {
    return;
  }

  for (const dependency of parsePubspecDirectDependencies(pubspecPath)) {
    checkPubspecDirectDependency(dependency);
  }

  const lockPath = path.join(ROOT, 'pubspec.lock');
  if (fs.existsSync(lockPath)) {
    for (const dependency of parsePubspecLock(lockPath)) {
      if (dependency.source === 'hosted') {
        addDependencyCheck({
          ecosystem: 'pub',
          name: dependency.name,
          version: dependency.version,
          location: 'pubspec.lock',
        });
        continue;
      }

      if (dependency.source !== 'sdk') {
        fail(
          `Cannot verify publish date for Dart package ${dependency.name} from ` +
            `${dependency.source} source in pubspec.lock.`,
        );
      }
    }
    return;
  }

  fail(
    'pubspec.lock is missing. Run `flutter pub get` and rerun this check so transitive ' +
      'Flutter/Dart packages are verified too.',
  );
}

function checkPubspecDirectDependency(dependency) {
  if (dependency.source === 'sdk') {
    return;
  }

  if (dependency.source !== 'hosted') {
    fail(
      `Cannot verify publish date for Dart dependency ${dependency.name} from ` +
        `${dependency.source} source in pubspec.yaml.`,
    );
    return;
  }

  if (!isExactSemver(dependency.version)) {
    fail(
      `Dart dependency ${dependency.name} in pubspec.yaml must use an exact version, ` +
        `not ${dependency.version}.`,
    );
    return;
  }

  addDependencyCheck({
    ecosystem: 'pub',
    name: dependency.name,
    version: dependency.version,
    location: 'pubspec.yaml',
  });
}

function collectNpmDependencies() {
  const packageJsonPaths = findFiles(ROOT, (filePath) => path.basename(filePath) === 'package.json');
  const packageLockPaths = findFiles(ROOT, (filePath) => path.basename(filePath) === 'package-lock.json');

  for (const packageJsonPath of packageJsonPaths) {
    checkPackageJsonPins(packageJsonPath);
  }

  for (const lockPath of packageLockPaths) {
    for (const dependency of parsePackageLock(lockPath)) {
      addDependencyCheck({
        ecosystem: 'npm',
        name: dependency.name,
        version: dependency.version,
        location: relativePath(lockPath),
      });
    }
  }

  for (const packageJsonPath of packageJsonPaths) {
    const directory = path.dirname(packageJsonPath);
    const lockPath = path.join(directory, 'package-lock.json');
    if (!fs.existsSync(lockPath)) {
      fail(
        `${relativePath(packageJsonPath)} has no package-lock.json. Use a deterministic ` +
          'lockfile before accepting npm dependencies.',
      );
    }
  }
}

function collectRemoteNpmImports() {
  const sourcePaths = findFiles(ROOT, (filePath) => /\.(cjs|cts|js|jsx|mjs|mts|ts|tsx)$/.test(filePath));

  for (const sourcePath of sourcePaths) {
    const contents = fs.readFileSync(sourcePath, 'utf8');
    collectEsmShImports(contents, sourcePath);
    collectNpmSchemeImports(contents, sourcePath);
  }
}

function collectEsmShImports(contents, sourcePath) {
  const urlPattern = /https:\/\/esm\.sh\/[^\s'"`),]+/g;
  for (const match of contents.matchAll(urlPattern)) {
    const rawUrl = match[0];
    const specifier = parseEsmShSpecifier(rawUrl);
    if (!specifier) {
      fail(`Could not parse npm package specifier from ${rawUrl} in ${relativePath(sourcePath)}.`);
      continue;
    }

    addNpmSpecifier(specifier, relativePath(sourcePath), rawUrl);
  }
}

function collectNpmSchemeImports(contents, sourcePath) {
  const specifierPattern = /npm:([@a-zA-Z0-9._/-]+@[0-9][a-zA-Z0-9.+-]*)/g;
  for (const match of contents.matchAll(specifierPattern)) {
    addNpmSpecifier(match[1], relativePath(sourcePath), `npm:${match[1]}`);
  }
}

function addNpmSpecifier(specifier, location, rawSpecifier) {
  const parsed = parseNpmPackageSpecifier(specifier);
  if (!parsed) {
    fail(`${rawSpecifier} in ${location} must include an exact npm package version.`);
    return;
  }

  if (!isExactSemver(parsed.version)) {
    fail(`${rawSpecifier} in ${location} must use an exact npm package version.`);
    return;
  }

  addDependencyCheck({
    ecosystem: 'npm',
    name: parsed.name,
    version: parsed.version,
    location,
  });
}

async function verifyDependencyAges() {
  for (const dependency of dependencyChecks.values()) {
    let publishedAt;
    if (dependency.ecosystem === 'npm') {
      publishedAt = await fetchNpmPublishDate(dependency.name, dependency.version);
    } else if (dependency.ecosystem === 'pub') {
      publishedAt = await fetchPubPublishDate(dependency.name, dependency.version);
    }

    if (!publishedAt) {
      fail(
        `Could not verify publish date for ${formatDependency(dependency)}. Treating it as blocked.`,
      );
      continue;
    }

    dependency.publishedAt = publishedAt;
    if (publishedAt > CUTOFF) {
      fail(
        `${formatDependency(dependency)} was published ${formatDate(publishedAt)}, which is newer ` +
          `than the ${MIN_AGE_DAYS}-day cutoff ${formatDate(CUTOFF)}.`,
      );
    }
  }
}

async function fetchNpmPublishDate(name, version) {
  const metadata = await fetchNpmMetadata(name);
  const publishedAt = metadata?.time?.[version];
  return publishedAt ? new Date(publishedAt) : null;
}

async function fetchNpmMetadata(name) {
  if (npmMetadataCache.has(name)) {
    return npmMetadataCache.get(name);
  }

  const escapedName = name.startsWith('@') ? name.replace('/', '%2F') : encodeURIComponent(name);
  const metadata = await fetchJson(`https://registry.npmjs.org/${escapedName}`);
  npmMetadataCache.set(name, metadata);
  return metadata;
}

async function fetchPubPublishDate(name, version) {
  const metadata = await fetchPubMetadata(name);
  const match = metadata?.versions?.find((candidate) => candidate.version === version);
  return match?.published ? new Date(match.published) : null;
}

async function fetchPubMetadata(name) {
  if (pubMetadataCache.has(name)) {
    return pubMetadataCache.get(name);
  }

  const metadata = await fetchJson(`https://pub.dev/api/packages/${encodeURIComponent(name)}`);
  pubMetadataCache.set(name, metadata);
  return metadata;
}

async function fetchJson(url) {
  if (typeof fetch !== 'function') {
    fail('This check requires Node.js 18 or newer so registry metadata can be fetched.');
    return null;
  }

  try {
    const response = await fetch(url);
    if (!response.ok) {
      fail(`Registry request failed for ${url}: HTTP ${response.status}.`);
      return null;
    }
    return await response.json();
  } catch (error) {
    fail(`Registry request failed for ${url}: ${error.message}.`);
    return null;
  }
}

function parsePubspecLock(lockPath) {
  const dependencies = [];
  const lines = fs.readFileSync(lockPath, 'utf8').split(/\r?\n/);
  let inPackages = false;
  let current = null;

  for (const line of lines) {
    if (/^packages:\s*$/.test(line)) {
      inPackages = true;
      continue;
    }

    if (!inPackages) {
      continue;
    }

    if (/^[^\s]/.test(line)) {
      break;
    }

    const packageMatch = line.match(/^  ([^:\s]+):\s*$/);
    if (packageMatch) {
      if (current?.version) {
        dependencies.push(current);
      }
      current = { name: packageMatch[1], source: 'unknown', version: null };
      continue;
    }

    if (!current) {
      continue;
    }

    const sourceMatch = line.match(/^    source:\s*"?([^"\s]+)"?\s*$/);
    if (sourceMatch) {
      current.source = sourceMatch[1];
      continue;
    }

    const versionMatch = line.match(/^    version:\s*"?([^"\s]+)"?\s*$/);
    if (versionMatch) {
      current.version = versionMatch[1];
    }
  }

  if (current?.version) {
    dependencies.push(current);
  }

  return dependencies;
}

function parsePubspecDirectDependencies(pubspecPath) {
  const dependencies = [];
  const lines = fs.readFileSync(pubspecPath, 'utf8').split(/\r?\n/);
  const sections = new Set(['dependencies', 'dev_dependencies', 'dependency_overrides']);
  let section = null;
  let current = null;

  for (const rawLine of lines) {
    const line = stripYamlComment(rawLine);
    const sectionMatch = line.match(/^([a-zA-Z_][\w]*):\s*$/);
    if (sectionMatch) {
      flushPubspecDependency(dependencies, current);
      current = null;
      section = sections.has(sectionMatch[1]) ? sectionMatch[1] : null;
      continue;
    }

    if (!section) {
      continue;
    }

    if (/^[^\s]/.test(line)) {
      flushPubspecDependency(dependencies, current);
      current = null;
      section = null;
      continue;
    }

    const dependencyMatch = line.match(/^  ([a-zA-Z_][\w]*):\s*(.*?)\s*$/);
    if (dependencyMatch) {
      flushPubspecDependency(dependencies, current);
      const value = unquote(dependencyMatch[2]);
      current = {
        name: dependencyMatch[1],
        source: value ? 'hosted' : 'unknown',
        version: value || null,
      };
      continue;
    }

    if (!current) {
      continue;
    }

    const sdkMatch = line.match(/^    sdk:\s*(.*?)\s*$/);
    if (sdkMatch) {
      current.source = 'sdk';
      current.version = unquote(sdkMatch[1]);
      continue;
    }

    if (/^    (git|path):/.test(line)) {
      current.source = line.trim().split(':')[0];
      continue;
    }

    const versionMatch = line.match(/^    version:\s*(.*?)\s*$/);
    if (versionMatch) {
      current.source = 'hosted';
      current.version = unquote(versionMatch[1]);
    }
  }

  flushPubspecDependency(dependencies, current);
  return dependencies;
}

function flushPubspecDependency(dependencies, dependency) {
  if (dependency?.name) {
    dependencies.push(dependency);
  }
}

function parsePackageLock(lockPath) {
  const lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
  const dependencies = [];

  if (lock.packages) {
    for (const [packagePath, packageData] of Object.entries(lock.packages)) {
      if (!packagePath || !packagePath.includes('node_modules/')) {
        continue;
      }

      const name = packageNameFromNodeModulesPath(packagePath);
      if (!name || !packageData.version) {
        continue;
      }

      dependencies.push({ name, version: packageData.version });
    }
    return dependencies;
  }

  walkPackageLockDependencies(lock.dependencies ?? {}, dependencies);
  return dependencies;
}

function walkPackageLockDependencies(dependencies, collected) {
  for (const [name, packageData] of Object.entries(dependencies)) {
    if (packageData.version) {
      collected.push({ name, version: packageData.version });
    }
    if (packageData.dependencies) {
      walkPackageLockDependencies(packageData.dependencies, collected);
    }
  }
}

function packageNameFromNodeModulesPath(packagePath) {
  const marker = 'node_modules/';
  const start = packagePath.lastIndexOf(marker);
  if (start === -1) {
    return null;
  }

  const pieces = packagePath.slice(start + marker.length).split('/');
  if (pieces[0]?.startsWith('@')) {
    return pieces.length > 1 ? `${pieces[0]}/${pieces[1]}` : null;
  }
  return pieces[0] || null;
}

function checkPackageJsonPins(packageJsonPath) {
  const manifest = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  const sections = ['dependencies', 'devDependencies', 'optionalDependencies', 'peerDependencies'];

  for (const section of sections) {
    for (const [name, specifier] of Object.entries(manifest[section] ?? {})) {
      checkNpmManifestSpecifier(name, specifier, `${relativePath(packageJsonPath)} ${section}`);
    }
  }

  for (const [name, specifier] of Object.entries(manifest.overrides ?? {})) {
    if (typeof specifier === 'string') {
      checkNpmManifestSpecifier(name, specifier, `${relativePath(packageJsonPath)} overrides`);
    }
  }

  for (const [name, specifier] of Object.entries(manifest.resolutions ?? {})) {
    if (typeof specifier === 'string') {
      checkNpmManifestSpecifier(name, specifier, `${relativePath(packageJsonPath)} resolutions`);
    }
  }
}

function checkNpmManifestSpecifier(name, specifier, location) {
  if (typeof specifier !== 'string') {
    return;
  }

  if (/^(file|link|workspace):/.test(specifier)) {
    return;
  }

  if (specifier.startsWith('npm:')) {
    const parsed = parseNpmPackageSpecifier(specifier.slice('npm:'.length));
    if (!parsed || !isExactSemver(parsed.version)) {
      fail(`${name} in ${location} must use an exact npm alias version, not ${specifier}.`);
    }
    return;
  }

  if (!isExactSemver(specifier)) {
    fail(`${name} in ${location} must use an exact npm version, not ${specifier}.`);
  }
}

function parseEsmShSpecifier(rawUrl) {
  try {
    const url = new URL(rawUrl);
    let pathname = decodeURIComponent(url.pathname).replace(/^\/+/, '');
    pathname = pathname.replace(/^v\d+\//, '');
    return pathname;
  } catch {
    return null;
  }
}

function parseNpmPackageSpecifier(specifier) {
  const cleanSpecifier = specifier.split('?')[0].replace(/^\/+/, '');
  const pieces = cleanSpecifier.split('/');

  if (pieces[0]?.startsWith('@')) {
    if (pieces.length < 2) {
      return null;
    }

    const versionStart = pieces[1].lastIndexOf('@');
    if (versionStart <= 0) {
      return null;
    }

    return {
      name: `${pieces[0]}/${pieces[1].slice(0, versionStart)}`,
      version: pieces[1].slice(versionStart + 1),
    };
  }

  const versionStart = pieces[0].lastIndexOf('@');
  if (versionStart <= 0) {
    return null;
  }

  return {
    name: pieces[0].slice(0, versionStart),
    version: pieces[0].slice(versionStart + 1),
  };
}

function addDependencyCheck(dependency) {
  if (!isExactSemver(dependency.version)) {
    fail(`${formatDependency(dependency)} must use an exact semantic version.`);
    return;
  }

  const key = `${dependency.ecosystem}:${dependency.name}@${dependency.version}`;
  const existing = dependencyChecks.get(key);
  if (existing) {
    existing.locations.add(dependency.location);
    return;
  }

  dependencyChecks.set(key, {
    ...dependency,
    locations: new Set([dependency.location]),
  });
}

function findFiles(directory, predicate) {
  const ignoredDirectories = new Set([
    '.dart_tool',
    '.git',
    '.pub',
    '.pub-cache',
    'build',
    'coverage',
    'node_modules',
  ]);
  const files = [];

  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      if (!ignoredDirectories.has(entry.name)) {
        files.push(...findFiles(entryPath, predicate));
      }
      continue;
    }

    if (entry.isFile() && predicate(entryPath)) {
      files.push(entryPath);
    }
  }

  return files;
}

function stripYamlComment(line) {
  const commentStart = line.indexOf('#');
  return commentStart === -1 ? line : line.slice(0, commentStart);
}

function unquote(value) {
  return value.trim().replace(/^['"]|['"]$/g, '');
}

function isExactSemver(value) {
  return /^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/.test(value);
}

function relativePath(filePath) {
  return path.relative(ROOT, filePath) || path.basename(filePath);
}

function formatDependency(dependency) {
  return `${dependency.ecosystem}:${dependency.name}@${dependency.version}`;
}

function formatDate(date) {
  return date.toISOString().slice(0, 10);
}

function fail(message) {
  failures.push(message);
}

function printReport() {
  console.log(`Dependency publish-age check (${MIN_AGE_DAYS} day minimum)`);
  console.log(`Cutoff date: ${formatDate(CUTOFF)}`);

  const dependencies = [...dependencyChecks.values()].sort((a, b) =>
    formatDependency(a).localeCompare(formatDependency(b)),
  );

  if (dependencies.length === 0) {
    console.log('No registry dependencies found.');
  } else {
    console.log(`Checked ${dependencies.length} registry dependency version(s):`);
    for (const dependency of dependencies) {
      const publishedAt = dependency.publishedAt ? formatDate(dependency.publishedAt) : 'unverified';
      const locations = [...dependency.locations].sort().join(', ');
      console.log(`- ${formatDependency(dependency)} published ${publishedAt} (${locations})`);
    }
  }

  if (failures.length === 0) {
    console.log('PASS: no checked package version is younger than the minimum age.');
    return;
  }

  console.log('FAIL: dependency policy violations found:');
  for (const failure of failures) {
    console.log(`- ${failure}`);
  }
}
