const express = require("express");
const { exec } = require("child_process");
const util = require("util");
const fs = require("fs").promises;
const crypto = require("crypto");
const path = require("path");

const execPromise = util.promisify(exec);
const app = express();
const PORT = process.env.MCP_PORT || 3000;
const HOST = process.env.MCP_HOST || "0.0.0.0";
const RATE_LIMIT_WINDOW_MS = Number(process.env.MCP_RATE_LIMIT_WINDOW_MS || 60000);
const RATE_LIMIT_MAX = Number(process.env.MCP_RATE_LIMIT_MAX || 120);
const REPORTS_DIR = "/root/reports";
const SKILLS_DIR = process.env.MCP_SKILLS_DIR || "/root/skills";
const ARTIFACT_INDEX_PATH = path.join(REPORTS_DIR, "index.json");
const TOR_SOCKS_HOST = process.env.TOR_SOCKS_HOST || "127.0.0.1";
const TOR_SOCKS_PORT = Number(process.env.TOR_SOCKS_PORT || 9050);
const TOR_DDG_ONION =
  process.env.TOR_DDG_ONION ||
  "http://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion";
const TOR_START_COMMAND =
  process.env.TOR_START_COMMAND ||
  "tor --SocksPort 9050 --ControlPort 9051 --DataDirectory /tmp/tor --RunAsDaemon 1";
const OPENCLAW_GATEWAY_URL = process.env.OPENCLAW_GATEWAY_URL || "";
const OPENCLAW_REGISTER_PATH = process.env.OPENCLAW_REGISTER_PATH || "/api/mcp/register";
const OPENCLAW_HEARTBEAT_PATH = process.env.OPENCLAW_HEARTBEAT_PATH || "/api/mcp/heartbeat";
const OPENCLAW_REGISTER_METHOD = (process.env.OPENCLAW_REGISTER_METHOD || "POST").toUpperCase();
const OPENCLAW_HEARTBEAT_METHOD = (process.env.OPENCLAW_HEARTBEAT_METHOD || "POST").toUpperCase();
const OPENCLAW_HEARTBEAT_INTERVAL_MS = Number(process.env.OPENCLAW_HEARTBEAT_INTERVAL_MS || 30000);
const OPENCLAW_CONNECT_TIMEOUT_MS = Number(process.env.OPENCLAW_CONNECT_TIMEOUT_MS || 5000);
const OPENCLAW_REQUIRE_GATEWAY = String(process.env.OPENCLAW_REQUIRE_GATEWAY || "false").toLowerCase() === "true";
const OPENCLAW_GATEWAY_TOKEN = process.env.OPENCLAW_GATEWAY_TOKEN || "";
const MCP_ADVERTISED_URL = process.env.MCP_ADVERTISED_URL || process.env.MCP_PUBLIC_URL || "";

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
  res.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
  next();
});

// Logging middleware
const rateLimitState = new Map();

function logEvent(level, message, data = {}) {
  const payload = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...data,
  };
  console.log(JSON.stringify(payload));
}

function resolveAdvertisedUrl() {
  if (MCP_ADVERTISED_URL) {
    return MCP_ADVERTISED_URL;
  }
  const host = HOST === "0.0.0.0" ? process.env.HOSTNAME || "kali-pentest" : HOST;
  return `http://${host}:${PORT}`;
}

function appendQuery(url, payload) {
  const target = new URL(url);
  if (!payload || typeof payload !== "object") {
    return target.toString();
  }
  for (const [key, value] of Object.entries(payload)) {
    if (value === undefined || value === null) {
      continue;
    }
    target.searchParams.set(key, String(value));
  }
  return target.toString();
}

function httpRequestJson(method, url, payload, timeoutMs = 5000, extraHeaders = {}) {
  return new Promise((resolve) => {
    const finalUrl = method === "GET" ? appendQuery(url, payload) : url;
    const target = new URL(finalUrl);
    const transport = target.protocol === "https:" ? require("https") : require("http");
    const data = payload && method !== "GET" ? JSON.stringify(payload) : "";
    const options = {
      method,
      hostname: target.hostname,
      port: target.port || (target.protocol === "https:" ? 443 : 80),
      path: `${target.pathname}${target.search}`,
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(data),
        ...extraHeaders,
      },
      timeout: timeoutMs,
    };
    const req = transport.request(options, (res) => {
      let body = "";
      res.on("data", (chunk) => {
        body += chunk;
      });
      res.on("end", () => {
        resolve({ ok: res.statusCode >= 200 && res.statusCode < 300, statusCode: res.statusCode, body });
      });
    });
    req.on("error", (error) => resolve({ ok: false, error: error.message }));
    req.on("timeout", () => {
      req.destroy(new Error("timeout"));
    });
    if (data.length > 0) {
      req.write(data);
    }
    req.end();
  });
}

async function checkGatewayReachable(baseUrl) {
  try {
    const target = new URL(baseUrl);
    const dns = require("dns").promises;
    await dns.lookup(target.hostname);
    return true;
  } catch (_error) {
    return false;
  }
}

async function registerWithOpenClaw() {
  if (!OPENCLAW_GATEWAY_URL) {
    return { ok: true, skipped: true };
  }
  const advertisedUrl = resolveAdvertisedUrl();
  const registerUrl = new URL(OPENCLAW_REGISTER_PATH, OPENCLAW_GATEWAY_URL).toString();
  const payload = {
    name: "kali-mcp",
    url: advertisedUrl,
    healthUrl: `${advertisedUrl}/health`,
    version: "1.0.0",
    timestamp: new Date().toISOString(),
  };
  const headers = OPENCLAW_GATEWAY_TOKEN
    ? {
        Authorization: `Bearer ${OPENCLAW_GATEWAY_TOKEN}`,
        "X-OpenClaw-Token": OPENCLAW_GATEWAY_TOKEN,
      }
    : {};
  const result = await httpRequestJson(
    OPENCLAW_REGISTER_METHOD,
    registerUrl,
    payload,
    OPENCLAW_CONNECT_TIMEOUT_MS,
    headers
  );
  if (result.ok) {
    logEvent("info", "openclaw_register_ok", { url: registerUrl, statusCode: result.statusCode });
  } else {
    logEvent("error", "openclaw_register_failed", {
      url: registerUrl,
      statusCode: result.statusCode,
      error: result.error,
      responseBody: result.body ? result.body.slice(0, 500) : "",
    });
  }
  return result;
}

async function sendOpenClawHeartbeat() {
  if (!OPENCLAW_GATEWAY_URL) {
    return { ok: true, skipped: true };
  }
  const advertisedUrl = resolveAdvertisedUrl();
  const heartbeatUrl = new URL(OPENCLAW_HEARTBEAT_PATH, OPENCLAW_GATEWAY_URL).toString();
  const payload = {
    name: "kali-mcp",
    url: advertisedUrl,
    status: "healthy",
    timestamp: new Date().toISOString(),
  };
  const headers = OPENCLAW_GATEWAY_TOKEN
    ? {
        Authorization: `Bearer ${OPENCLAW_GATEWAY_TOKEN}`,
        "X-OpenClaw-Token": OPENCLAW_GATEWAY_TOKEN,
      }
    : {};
  const result = await httpRequestJson(
    OPENCLAW_HEARTBEAT_METHOD,
    heartbeatUrl,
    payload,
    OPENCLAW_CONNECT_TIMEOUT_MS,
    headers
  );
  if (result.ok) {
    logEvent("info", "openclaw_heartbeat_ok", { url: heartbeatUrl, statusCode: result.statusCode });
  } else {
    logEvent("error", "openclaw_heartbeat_failed", {
      url: heartbeatUrl,
      statusCode: result.statusCode,
      error: result.error,
      responseBody: result.body ? result.body.slice(0, 500) : "",
    });
  }
  return result;
}

async function startOpenClawHeartbeat() {
  if (!OPENCLAW_GATEWAY_URL) {
    return;
  }
  const reachable = await checkGatewayReachable(OPENCLAW_GATEWAY_URL);
  if (!reachable) {
    logEvent("error", "openclaw_gateway_unreachable", { url: OPENCLAW_GATEWAY_URL });
    if (OPENCLAW_REQUIRE_GATEWAY) {
      process.exit(1);
    }
  }
  const registered = await registerWithOpenClaw();
  if (!registered.ok && OPENCLAW_REQUIRE_GATEWAY) {
    process.exit(1);
  }
  if (OPENCLAW_HEARTBEAT_INTERVAL_MS > 0) {
    setInterval(() => {
      sendOpenClawHeartbeat();
    }, OPENCLAW_HEARTBEAT_INTERVAL_MS);
  }
}

app.use((req, res, next) => {
  logEvent("info", "request", {
    method: req.method,
    path: req.path,
    ip: req.ip,
  });
  next();
});

app.use((req, res, next) => {
  const key = `${req.ip}:${req.path}`;
  const now = Date.now();
  const entry = rateLimitState.get(key);
  if (!entry || now > entry.resetAt) {
    rateLimitState.set(key, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return next();
  }
  if (entry.count >= RATE_LIMIT_MAX) {
    return res.status(429).json({
      success: false,
      error: "Rate limit exceeded",
      retryAt: new Date(entry.resetAt).toISOString(),
    });
  }
  entry.count += 1;
  return next();
});

const riskPolicy = {
  blockedTokens: ["&&", "||", ";", "|", "`", "$(", ">", "<", "\n", "\r"],
  blockedPatterns: [/\/dev\/tcp/i, /\/dev\/udp/i],
};

function assessRisk(command) {
  const reasons = [];
  for (const token of riskPolicy.blockedTokens) {
    if (command.includes(token)) {
      reasons.push(`blocked_token:${token}`);
    }
  }
  for (const pattern of riskPolicy.blockedPatterns) {
    if (pattern.test(command)) {
      reasons.push(`blocked_pattern:${pattern}`);
    }
  }
  return { allowed: reasons.length === 0, reasons };
}

// Helper function para executar comandos de forma segura
async function executeCommand(command, timeout = 300000) {
  const risk = assessRisk(command);
  if (!risk.allowed) {
    return {
      success: false,
      error: "Command rejected by risk policy",
      stdout: "",
      stderr: "",
      risk,
    };
  }
  try {
    logEvent("info", "command_start", { command, timeout });
    const { stdout, stderr } = await execPromise(command, {
      timeout,
      maxBuffer: 10 * 1024 * 1024,
    });
    logEvent("info", "command_end", { command, success: true });
    return { success: true, stdout, stderr, risk };
  } catch (error) {
    logEvent("error", "command_end", { command, success: false, error: error.message });
    return {
      success: false,
      error: error.message,
      stdout: error.stdout || "",
      stderr: error.stderr || "",
      risk,
    };
  }
}

async function ensureTorRunning() {
  try {
    await execPromise("pgrep -x tor");
    return true;
  } catch (_error) {
    try {
      await execPromise(TOR_START_COMMAND, { timeout: 10000, maxBuffer: 1024 * 1024 });
    } catch (_startError) {}
  }
  try {
    await execPromise("pgrep -x tor");
    return true;
  } catch (_error) {
    return false;
  }
}

function buildTorCurlCommand(url, timeoutSec = 60) {
  const userAgent = "Mozilla/5.0 (X11; Linux x86_64)";
  return [
    "curl",
    "-sL",
    `--socks5-hostname ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}`,
    `--max-time ${timeoutSec}`,
    "--connect-timeout 20",
    `-A "${userAgent}"`,
    `"${url}"`,
  ].join(" ");
}

function isValidOnionUrl(value) {
  try {
    const parsed = new URL(value);
    return ["http:", "https:"].includes(parsed.protocol) && parsed.hostname.endsWith(".onion");
  } catch (_error) {
    return false;
  }
}

async function fetchViaTor(url, timeoutSec = 60) {
  const command = buildTorCurlCommand(url, timeoutSec);
  try {
    const { stdout, stderr } = await execPromise(command, {
      timeout: timeoutSec * 1000,
      maxBuffer: 10 * 1024 * 1024,
    });
    return { success: true, stdout, stderr };
  } catch (error) {
    return { success: false, stdout: error.stdout || "", stderr: error.stderr || "", error: error.message };
  }
}

function stripHtml(html) {
  let content = html.replace(/<script[\s\S]*?<\/script>/gi, " ");
  content = content.replace(/<style[\s\S]*?<\/style>/gi, " ");
  content = content.replace(/<[^>]+>/g, " ");
  content = content
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, "\"")
    .replace(/&#39;/gi, "'");
  return content.replace(/\s+/g, " ").trim();
}

function extractTitle(html) {
  const match = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  return match ? stripHtml(match[1]).slice(0, 200) : "";
}

function extractLinks(html) {
  const links = [];
  const regex = /href=["']([^"'#\s>]+)["']/gi;
  let match;
  while ((match = regex.exec(html))) {
    let href = match[1];
    if (href.startsWith("//")) {
      href = `http:${href}`;
    }
    if (href.includes("uddg=")) {
      const parts = href.split("uddg=");
      const candidate = parts[parts.length - 1];
      try {
        href = decodeURIComponent(candidate);
      } catch (_error) {}
    }
    if (href.startsWith("http") && href.includes(".onion")) {
      links.push(href);
    }
  }
  return Array.from(new Set(links));
}

function extractDuckDuckGoResults(html) {
  const results = [];
  const regex = /<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/gi;
  let match;
  while ((match = regex.exec(html))) {
    let href = match[1];
    if (href.includes("uddg=")) {
      const parts = href.split("uddg=");
      const candidate = parts[parts.length - 1];
      try {
        href = decodeURIComponent(candidate);
      } catch (_error) {}
    }
    if (href.startsWith("//")) {
      href = `http:${href}`;
    }
    const title = stripHtml(match[2]).slice(0, 200);
    results.push({ url: href, title });
  }
  const unique = new Map();
  for (const item of results) {
    if (!item.url) {
      continue;
    }
    if (!unique.has(item.url)) {
      unique.set(item.url, item);
    }
  }
  return Array.from(unique.values());
}

const injectionPatterns = [
  { name: "ignore_previous", regex: /ignore\s+(all|previous|above)\s+instructions/i },
  { name: "system_prompt", regex: /(system\s+prompt|developer\s+message)/i },
  { name: "jailbreak", regex: /(jailbreak|do\s+anything\s+now)/i },
  { name: "data_exfiltration", regex: /(send\s+secrets|exfiltrate|leak)/i },
  { name: "tool_override", regex: /(call\s+tools|invoke\s+tool|execute\s+command)/i },
];

function sanitizeText(text) {
  const lines = text.split(/\r?\n/);
  const removed = [];
  const kept = [];
  for (const line of lines) {
    const matched = injectionPatterns.find((pattern) => pattern.regex.test(line));
    if (matched) {
      removed.push(matched.name);
      continue;
    }
    kept.push(line);
  }
  return {
    text: kept.join("\n").replace(/\s+/g, " ").trim(),
    removed,
  };
}

function analyzePromptInjection(text) {
  const hits = [];
  for (const pattern of injectionPatterns) {
    if (pattern.regex.test(text)) {
      hits.push(pattern.name);
    }
  }
  return Array.from(new Set(hits));
}

function buildPageJson({ url, html, maxTextLength = 6000 }) {
  const title = extractTitle(html);
  const rawText = stripHtml(html);
  const sanitized = sanitizeText(rawText);
  const promptInjection = analyzePromptInjection(rawText);
  const text = sanitized.text.slice(0, maxTextLength);
  return {
    url,
    title,
    text,
    links: extractLinks(html),
    analysis: {
      wordCount: text ? text.split(/\s+/).length : 0,
      promptInjection,
      removedSignals: sanitized.removed,
      truncated: sanitized.text.length > text.length,
    },
  };
}

async function loadWordlist(wordlistPath) {
  try {
    const content = await fs.readFile(wordlistPath, "utf8");
    return content
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("#"));
  } catch (_error) {
    return [];
  }
}

function hashContent(content) {
  return crypto.createHash("sha256").update(content).digest("hex");
}

async function hashFile(filePath) {
  try {
    const data = await fs.readFile(filePath);
    return hashContent(data);
  } catch (_error) {
    return hashContent(filePath);
  }
}

async function loadArtifactIndex() {
  try {
    const content = await fs.readFile(ARTIFACT_INDEX_PATH, "utf8");
    return JSON.parse(content);
  } catch (_error) {
    return { artifacts: [] };
  }
}

async function saveArtifactIndex(index) {
  await fs.writeFile(ARTIFACT_INDEX_PATH, JSON.stringify(index, null, 2));
}

async function addArtifact(artifact) {
  const index = await loadArtifactIndex();
  index.artifacts.push(artifact);
  await saveArtifactIndex(index);
  return artifact;
}

async function saveReport(toolName, target, data) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const filename = `${toolName}_${target.replace(/[^a-zA-Z0-9]/g, "_")}_${timestamp}.txt`;
  const filepath = path.join(REPORTS_DIR, filename);
  const content = JSON.stringify(data, null, 2);
  await fs.writeFile(filepath, content);
  const artifact = await addArtifact({
    hash: hashContent(content),
    tool: toolName,
    target,
    path: filepath,
    type: "report",
    createdAt: new Date().toISOString(),
  });
  return { filename, artifact };
}

async function createFileArtifact(tool, target, filePath, type = "output") {
  const hash = await hashFile(filePath);
  return addArtifact({
    hash,
    tool,
    target,
    path: filePath,
    type,
    createdAt: new Date().toISOString(),
  });
}

function buildResponse({ success, tool, target, command, result, report, artifacts = [], meta = {} }) {
  return {
    success,
    tool,
    target,
    command,
    stdout: result?.stdout || "",
    stderr: result?.stderr || "",
    error: result?.error || null,
    report,
    artifacts,
    meta,
    timestamp: new Date().toISOString(),
  };
}

async function listSkillNames() {
  try {
    const entries = await fs.readdir(SKILLS_DIR, { withFileTypes: true });
    const candidates = entries.filter((entry) => entry.isDirectory()).map((entry) => entry.name);
    const checks = await Promise.all(
      candidates.map(async (name) => {
        const skillPath = path.join(SKILLS_DIR, name, "SKILL.md");
        try {
          await fs.access(skillPath);
          return name;
        } catch (error) {
          return null;
        }
      })
    );
    return checks.filter((name) => name);
  } catch (error) {
    return [];
  }
}

function normalizeSkillName(value) {
  if (!value) {
    return null;
  }
  if (!/^[a-z0-9][a-z0-9_-]*$/i.test(value)) {
    return null;
  }
  return value;
}

async function readSkillContent(skillName) {
  const safeName = normalizeSkillName(skillName);
  if (!safeName) {
    return { error: "Invalid skill name" };
  }
  const skillPath = path.join(SKILLS_DIR, safeName, "SKILL.md");
  const resolved = path.resolve(skillPath);
  const rootResolved = path.resolve(SKILLS_DIR);
  if (!resolved.startsWith(rootResolved)) {
    return { error: "Invalid skill path" };
  }
  try {
    const content = await fs.readFile(resolved, "utf-8");
    return { name: safeName, content };
  } catch (error) {
    return { error: "Skill not found" };
  }
}

const toolRunner = {
  theharvester: { template: "theHarvester -d {target} {options}", category: "recon", description: "Email/domain harvesting", requiresTarget: true },
  "recon-ng": { template: "recon-ng {options}", category: "recon", description: "Reconnaissance framework", requiresTarget: false },
  dnsrecon: { template: "dnsrecon -d {target} {options}", category: "recon", description: "DNS enumeration", requiresTarget: true },
  whatweb: { template: "whatweb {options} {target}", category: "recon", description: "Web technology fingerprinting", requiresTarget: true },
  wafw00f: { template: "wafw00f {options} {target}", category: "recon", description: "WAF detection", requiresTarget: true },
  dmitry: { template: "dmitry {options} {target}", category: "recon", description: "Information gathering", requiresTarget: true },
  unicornscan: { template: "unicornscan {options} {target}", category: "recon", description: "Port scanner", requiresTarget: true },
  spiderfoot: { template: "spiderfoot -s {target} {options}", category: "recon", description: "OSINT automation", requiresTarget: true },
  enum4linux: { template: "enum4linux {options} {target}", category: "recon", description: "SMB enumeration", requiresTarget: true },
  "smtp-user-enum": { template: "smtp-user-enum {options} {target}", category: "recon", description: "SMTP user enumeration", requiresTarget: true },
  "snmp-check": { template: "snmp-check {options} {target}", category: "recon", description: "SNMP audit", requiresTarget: true },
  sslscan: { template: "sslscan {options} {target}", category: "recon", description: "SSL/TLS scanner", requiresTarget: true },
  sslstrip: { template: "sslstrip {options} {target}", category: "recon", description: "SSL stripping", requiresTarget: false },
  "ike-scan": { template: "ike-scan {options} {target}", category: "recon", description: "IKE scanner", requiresTarget: true },
  amap: { template: "amap {options} {target}", category: "recon", description: "Application mapper", requiresTarget: true },
  lbd: { template: "lbd {options} {target}", category: "recon", description: "Load balancer detection", requiresTarget: true },
  sublist3r: { template: "sublist3r -d {target} {options}", category: "recon", description: "Subdomain discovery", requiresTarget: true },
  cloudbrute: { template: "cloudbrute {options} -d {target}", category: "recon", description: "Cloud enumeration", requiresTarget: true },
  assetfinder: { template: "assetfinder {options} {target}", category: "recon", description: "Asset discovery", requiresTarget: true },
  gau: { template: "gau {options} {target}", category: "recon", description: "Get all URLs", requiresTarget: true },
  waybackurls: { template: "waybackurls {options} {target}", category: "recon", description: "Wayback URL discovery", requiresTarget: true },
  massdns: { template: "massdns {options} {target}", category: "recon", description: "DNS brute force", requiresTarget: true },
  paramspider: { template: "paramspider -d {target} {options}", category: "recon", description: "Parameter discovery", requiresTarget: true },
  arjun: { template: "arjun -u {target} {options}", category: "recon", description: "Parameter discovery", requiresTarget: true },
  joomscan: { template: "joomscan -u {target} {options}", category: "web", description: "Joomla scanner", requiresTarget: true },
  cmsmap: { template: "cmsmap {options} -t {target}", category: "web", description: "CMS scanner", requiresTarget: true },
  xsstrike: { template: "xsstrike -u {target} {options}", category: "web", description: "XSS scanner", requiresTarget: true },
  commix: { template: "commix -u {target} {options}", category: "web", description: "Command injection", requiresTarget: true },
  "beef-xss": { template: "beef-xss {options}", category: "web", description: "Browser exploitation framework", requiresTarget: false },
  skipfish: { template: "skipfish {options} {target}", category: "web", description: "Web security scanner", requiresTarget: true },
  arachni: { template: "arachni {options} {target}", category: "web", description: "Web vulnerability scanner", requiresTarget: true },
  davtest: { template: "davtest -url {target} {options}", category: "web", description: "WebDAV tester", requiresTarget: true },
  droopescan: { template: "droopescan scan {options} -u {target}", category: "web", description: "CMS scanner", requiresTarget: true },
  nosqlmap: { template: "nosqlmap -u {target} {options}", category: "web", description: "NoSQL injection", requiresTarget: true },
  brutespray: { template: "brutespray {options} -t {target}", category: "web", description: "Brute force orchestration", requiresTarget: true },
  ncrack: { template: "ncrack {options} {target}", category: "password", description: "Network authentication cracking", requiresTarget: true },
  cewl: { template: "cewl {options} {target}", category: "password", description: "Custom wordlist generator", requiresTarget: true },
  crunch: { template: "crunch {options}", category: "password", description: "Wordlist generator", requiresTarget: false },
  ophcrack: { template: "ophcrack {options}", category: "password", description: "Password cracker", requiresTarget: false },
  wifite: { template: "wifite {options}", category: "wireless", description: "Wireless attack automation", requiresTarget: false },
  bully: { template: "bully {options}", category: "wireless", description: "WPS attack tool", requiresTarget: false },
  kismet: { template: "kismet {options}", category: "wireless", description: "Wireless detector", requiresTarget: false },
  pixiewps: { template: "pixiewps {options}", category: "wireless", description: "WPS pin recovery", requiresTarget: false },
  "fern-wifi-cracker": { template: "fern-wifi-cracker {options}", category: "wireless", description: "Wireless attack tool", requiresTarget: false },
  mdk4: { template: "mdk4 {options}", category: "wireless", description: "Wireless testing", requiresTarget: false },
  airgeddon: { template: "airgeddon {options}", category: "wireless", description: "Wireless auditing suite", requiresTarget: false },
  "wifi-pumpkin3": { template: "wifi-pumpkin3 {options}", category: "wireless", description: "Rogue AP framework", requiresTarget: false },
  routersploit: { template: "rsf {options}", category: "exploitation", description: "Router exploitation framework", requiresTarget: false },
  set: { template: "setoolkit {options}", category: "exploitation", description: "Social-Engineer Toolkit", requiresTarget: false },
  msfvenom: { template: "msfvenom {options}", category: "exploitation", description: "Payload generator", requiresTarget: false },
  bettercap: { template: "bettercap {options}", category: "sniffing", description: "MITM framework", requiresTarget: false },
  driftnet: { template: "driftnet {options}", category: "sniffing", description: "Traffic image sniffer", requiresTarget: false },
  mitmf: { template: "mitmf {options}", category: "sniffing", description: "Man-in-the-middle framework", requiresTarget: false },
  yersinia: { template: "yersinia {options}", category: "sniffing", description: "Layer 2 attack tool", requiresTarget: false },
  weevely: { template: "weevely {options}", category: "post", description: "Web shell", requiresTarget: false },
  lazagne: { template: "lazagne {options}", category: "post", description: "Credential recovery", requiresTarget: false },
  "linux-exploit-suggester": { template: "linux-exploit-suggester {options}", category: "post", description: "Privilege escalation hints", requiresTarget: false },
  "windows-exploit-suggester": { template: "windows-exploit-suggester {options}", category: "post", description: "Privilege escalation hints", requiresTarget: false },
  autopsy: { template: "autopsy {options}", category: "forensics", description: "Digital forensics", requiresTarget: false },
  volatility: { template: "volatility {options}", category: "forensics", description: "Memory forensics", requiresTarget: false },
  binwalk: { template: "binwalk {options} {target}", category: "forensics", description: "Firmware analysis", requiresTarget: true },
  foremost: { template: "foremost {options} {target}", category: "forensics", description: "File carving", requiresTarget: true },
  ghidra: { template: "ghidra {options}", category: "forensics", description: "Reverse engineering", requiresTarget: false },
  radare2: { template: "radare2 {options} {target}", category: "forensics", description: "Reverse engineering", requiresTarget: true },
  apktool: { template: "apktool {options} {target}", category: "forensics", description: "Android reverse engineering", requiresTarget: true },
  dex2jar: { template: "d2j-dex2jar {options} {target}", category: "forensics", description: "Dex to jar", requiresTarget: true },
  strings: { template: "strings {options} {target}", category: "forensics", description: "Binary string extraction", requiresTarget: true },
  exiftool: { template: "exiftool {options} {target}", category: "forensics", description: "Metadata extraction", requiresTarget: true },
  dalfox: { template: "dalfox url {target} {options}", category: "bugbounty", description: "XSS scanner", requiresTarget: true },
  // Password cracking
  medusa: { template: "medusa {options}", category: "password", description: "Parallel network login auditor", requiresTarget: false },
  john: { template: "john {options} {target}", category: "password", description: "Password hash cracker", requiresTarget: true },
  hashcat: { template: "hashcat {options} {target}", category: "password", description: "GPU-accelerated password cracker", requiresTarget: true },
  // Network / AD
  crackmapexec: { template: "crackmapexec {options} {target}", category: "network", description: "AD and SMB testing", requiresTarget: false },
  responder: { template: "responder {options}", category: "network", description: "LLMNR/NBT-NS poisoning", requiresTarget: false },
  "bloodhound-python": { template: "bloodhound-python {options}", category: "ad", description: "Active Directory attack path collection", requiresTarget: false },
  ldapdomaindump: { template: "ldapdomaindump {options} {target}", category: "ad", description: "LDAP domain enumeration", requiresTarget: true },
  impacket: { template: "python3 /usr/share/doc/python3-impacket/examples/{options}", category: "network", description: "Network protocol scripts (impacket)", requiresTarget: false },
  // Wireless
  "aircrack-ng": { template: "aircrack-ng {options} {target}", category: "wireless", description: "WEP/WPA cracking suite", requiresTarget: false },
  reaver: { template: "reaver {options}", category: "wireless", description: "WPS PIN brute force", requiresTarget: false },
  "airmon-ng": { template: "airmon-ng {options}", category: "wireless", description: "Monitor mode manager", requiresTarget: false },
  "airodump-ng": { template: "airodump-ng {options}", category: "wireless", description: "Wireless packet capture", requiresTarget: false },
  "aireplay-ng": { template: "aireplay-ng {options}", category: "wireless", description: "Packet injection tool", requiresTarget: false },
};

const categoryTags = {
  scanning: ["recon"],
  bruteforce: ["auth"],
  recon: ["recon"],
  web: ["web"],
  network: ["network"],
  ad: ["ad"],
  cloud: ["cloud"],
  exploitation: ["exploit"],
  wireless: ["wireless"],
  sniffing: ["network"],
  post: ["post"],
  forensics: ["forensics"],
  bugbounty: ["bugbounty"],
};

function getTags(category) {
  return categoryTags[category] || [];
}

function toolRunExample(tool, targetExample = "example.com") {
  return {
    endpoint: "/api/tools/run",
    body: { tool, target: targetExample, options: "" },
  };
}

function buildToolCommand(tool, target, options) {
  const config = toolRunner[tool];
  if (!config) {
    return null;
  }
  return config.template
    .replace("{target}", target || "")
    .replace("{options}", options || "")
    .replace(/\s+/g, " ")
    .trim();
}

async function runConfiguredTool({ tool, target, options, timeout = 900000 }) {
  const command = buildToolCommand(tool, target, options);
  if (!command) {
    return { error: "Tool not supported" };
  }
  const result = await executeCommand(command, timeout);
  const report = await saveReport(tool, target || tool, { command, ...result });
  return { command, result, report };
}

// ==================== ROUTES ====================

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() });
});

// Home
app.get("/", (req, res) => {
  res.json({
    name: "Kali MCP Pentest Server",
    version: "1.0.0",
    endpoints: {
      nmap: "/api/scan/nmap",
      masscan: "/api/scan/masscan",
      hydra: "/api/bruteforce/hydra",
      amass: "/api/recon/amass",
      subfinder: "/api/recon/subfinder",
      sqlmap: "/api/web/sqlmap",
      wpscan: "/api/web/wpscan",
      nikto: "/api/web/nikto",
      dirb: "/api/web/dirb",
      gobuster: "/api/web/gobuster",
      httpx: "/api/web/httpx",
      nuclei: "/api/web/nuclei",
      ffuf: "/api/web/ffuf",
      feroxbuster: "/api/web/feroxbuster",
      dirsearch: "/api/web/dirsearch",
      metasploit: "/api/exploit/msfconsole",
      toolsRun: "/api/tools/run",
      toolsDryRun: "/api/tools/dry-run",
      toolsPipeline: "/api/tools/pipeline",
      onionSearch: "/api/onion/search",
      tools: "/api/tools/list",
      skills: "/api/skills/list",
      skill: "/api/skills/:tool",
      artifacts: "/api/artifacts",
      reportSummary: "/api/reports/summary/:filename",
      nosqlmap: "/api/web/nosqlmap",
      apiDocs: "/api-docs",
      swaggerJson: "/swagger.json",
    },
  });
});

// ==================== NMAP ====================
app.post("/api/scan/nmap", async (req, res) => {
  const { target, options = "-sV -sC", output: _output = "normal" } = req.body;

  if (!target) {
    return res.status(400).json({ error: "Target is required" });
  }

  const outputFile = `/root/nmap-results/nmap_${target.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}`;
  const command = `nmap ${options} ${target} -oN ${outputFile}.txt -oX ${outputFile}.xml`;

  const result = await executeCommand(command);
  const report = await saveReport("nmap", target, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("nmap", target, `${outputFile}.txt`, "output"),
    await createFileArtifact("nmap", target, `${outputFile}.xml`, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "nmap",
    target,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { output: _output },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// ==================== MASSCAN ====================
app.post("/api/scan/masscan", async (req, res) => {
  const { target, ports = "1-65535", rate = "1000" } = req.body;

  if (!target) {
    return res.status(400).json({ error: "Target is required" });
  }

  const outputFile = `/root/nmap-results/masscan_${target.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}.txt`;
  const command = `masscan ${target} -p${ports} --rate=${rate} -oL ${outputFile}`;

  const result = await executeCommand(command);
  const report = await saveReport("masscan", target, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("masscan", target, outputFile, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "masscan",
    target,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { ports, rate },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// ==================== HYDRA ====================
app.post("/api/bruteforce/hydra", async (req, res) => {
  const {
    target,
    service,
    username,
    userlist,
    password,
    passlist = "/root/wordlists/rockyou.txt",
    port,
    options = "",
  } = req.body;

  if (!target || !service) {
    return res.status(400).json({ error: "Target and service are required" });
  }

  let command = "hydra ";

  if (username) {
    command += `-l ${username} `;
  }
  if (userlist) {
    command += `-L ${userlist} `;
  }
  if (password) {
    command += `-p ${password} `;
  }
  if (passlist && !password) {
    command += `-P ${passlist} `;
  }
  if (port) {
    command += `-s ${port} `;
  }

  command += `${options} ${target} ${service}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("hydra", target, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "hydra",
    target,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { service, username, userlist, password, passlist, port, options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/recon/amass", async (req, res) => {
  const { domain, options = "" } = req.body;

  if (!domain) {
    return res.status(400).json({ error: "Domain is required" });
  }

  const command = `amass enum -d ${domain} ${options}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("amass", domain, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "amass",
    target: domain,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/recon/subfinder", async (req, res) => {
  const { domain, options = "" } = req.body;

  if (!domain) {
    return res.status(400).json({ error: "Domain is required" });
  }

  const command = `subfinder -d ${domain} ${options}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("subfinder", domain, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "subfinder",
    target: domain,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// ==================== SQLMAP ====================
app.post("/api/web/sqlmap", async (req, res) => {
  const { url, options = "--batch --risk=1 --level=1" } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const command = `sqlmap -u "${url}" ${options}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("sqlmap", url, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "sqlmap",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// ==================== WPSCAN ====================
app.post("/api/web/wpscan", async (req, res) => {
  const { url, options = "--enumerate p,t,u" } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const command = `wpscan --url ${url} ${options}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("wpscan", url, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "wpscan",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// ==================== NIKTO ====================
app.post("/api/web/nikto", async (req, res) => {
  const { host, port = 80, ssl = false } = req.body;

  if (!host) {
    return res.status(400).json({ error: "Host is required" });
  }

  const outputFile = `/root/reports/nikto_${host.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}.txt`;
  const sslFlag = ssl ? "-ssl" : "";
  const command = `nikto -h ${host} -p ${port} ${sslFlag} -o ${outputFile}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("nikto", host, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("nikto", host, outputFile, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "nikto",
    target: host,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { port, ssl },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// ==================== DIRB ====================
app.post("/api/web/dirb", async (req, res) => {
  const { url, wordlist = "/usr/share/wordlists/dirb/common.txt" } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const outputFile = `/root/reports/dirb_${url.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}.txt`;
  const command = `dirb ${url} ${wordlist} -o ${outputFile}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("dirb", url, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("dirb", url, outputFile, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "dirb",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { wordlist },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// ==================== GOBUSTER ====================
app.post("/api/web/gobuster", async (req, res) => {
  const {
    url,
    wordlist = "/usr/share/wordlists/dirb/common.txt",
    mode = "dir",
    extensions = "",
  } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const outputFile = `/root/reports/gobuster_${url.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}.txt`;
  let command = `gobuster ${mode} -u ${url} -w ${wordlist} -o ${outputFile}`;

  if (extensions) {
    command += ` -x ${extensions}`;
  }

  const result = await executeCommand(command, 600000);
  const report = await saveReport("gobuster", url, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("gobuster", url, outputFile, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "gobuster",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { wordlist, mode, extensions },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/web/httpx", async (req, res) => {
  const { target, options = "" } = req.body;

  if (!target) {
    return res.status(400).json({ error: "Target is required" });
  }

  const command = `httpx -u ${target} ${options}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("httpx", target, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "httpx",
    target,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/web/nuclei", async (req, res) => {
  const { target, options = "" } = req.body;

  if (!target) {
    return res.status(400).json({ error: "Target is required" });
  }

  const command = `nuclei -u ${target} ${options}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("nuclei", target, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "nuclei",
    target,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/web/ffuf", async (req, res) => {
  const { url, wordlist = "/usr/share/wordlists/dirb/common.txt", options = "" } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const outputFile = `/root/reports/ffuf_${url.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}.json`;
  const command = `ffuf -u ${url} -w ${wordlist} ${options} -of json -o ${outputFile}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("ffuf", url, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("ffuf", url, outputFile, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "ffuf",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { wordlist, options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/web/feroxbuster", async (req, res) => {
  const { url, options = "" } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const outputFile = `/root/reports/feroxbuster_${url.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}.txt`;
  const command = `feroxbuster -u ${url} ${options} -o ${outputFile}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("feroxbuster", url, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("feroxbuster", url, outputFile, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "feroxbuster",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/web/dirsearch", async (req, res) => {
  const { url, options = "" } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const outputFile = `/root/reports/dirsearch_${url.replace(/[^a-zA-Z0-9]/g, "_")}_${Date.now()}.txt`;
  const command = `dirsearch -u ${url} ${options} -o ${outputFile}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("dirsearch", url, { command, ...result });
  const artifacts = [
    report.artifact,
    await createFileArtifact("dirsearch", url, outputFile, "output"),
  ];
  const payload = buildResponse({
    success: result.success,
    tool: "dirsearch",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts,
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/tools/run", async (req, res) => {
  const { tool, target, options = "", stream = false } = req.body;

  if (!tool) {
    return res.status(400).json({ error: "Tool is required" });
  }

  const config = toolRunner[tool];
  if (!config) {
    return res.status(400).json({ error: "Tool not supported" });
  }

  if (config.requiresTarget && !target) {
    return res.status(400).json({ error: "Target is required" });
  }

  const command = buildToolCommand(tool, target, options);
  if (!command) {
    return res.status(400).json({ error: "Tool not supported" });
  }

  if (stream) {
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
    });
    res.write(`event: start\ndata: ${JSON.stringify({ tool, target, command })}\n\n`);
  }

  const result = await executeCommand(command, 900000);
  const report = await saveReport(tool, target || tool, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool,
    target: target || null,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });

  if (stream) {
    res.write(`event: complete\ndata: ${JSON.stringify(payload)}\n\n`);
    return res.end();
  }

  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.post("/api/tools/dry-run", async (req, res) => {
  const { tool, target, options = "" } = req.body;

  if (!tool) {
    return res.status(400).json({ error: "Tool is required" });
  }

  const config = toolRunner[tool];
  if (!config) {
    return res.status(400).json({ error: "Tool not supported" });
  }

  if (config.requiresTarget && !target) {
    return res.status(400).json({ error: "Target is required" });
  }

  const command = buildToolCommand(tool, target, options);
  const risk = assessRisk(command);
  const payload = buildResponse({
    success: risk.allowed,
    tool,
    target: target || null,
    command,
    result: { stdout: "", stderr: "", error: risk.allowed ? null : "Command rejected by risk policy" },
    report: null,
    artifacts: [],
    meta: { options, dryRun: true, risk },
  });

  if (!risk.allowed) {
    return res.status(400).json(payload);
  }
  return res.json(payload);
});

app.post("/api/tools/pipeline", async (req, res) => {
  const { steps = [] } = req.body;

  if (!Array.isArray(steps) || steps.length === 0) {
    return res.status(400).json({ error: "Steps array is required" });
  }

  const results = [];
  for (const step of steps) {
    const { tool, target, options = "", dryRun = false } = step;
    if (!tool) {
      results.push({ success: false, error: "Tool is required" });
      continue;
    }
    const config = toolRunner[tool];
    if (!config) {
      results.push({ success: false, tool, error: "Tool not supported" });
      continue;
    }
    if (config.requiresTarget && !target) {
      results.push({ success: false, tool, error: "Target is required" });
      continue;
    }

    const command = buildToolCommand(tool, target, options);
    if (dryRun) {
      const risk = assessRisk(command);
      results.push(
        buildResponse({
          success: risk.allowed,
          tool,
          target: target || null,
          command,
          result: { stdout: "", stderr: "", error: risk.allowed ? null : "Command rejected by risk policy" },
          report: null,
          artifacts: [],
          meta: { options, dryRun: true, risk },
        })
      );
      continue;
    }

    const executed = await runConfiguredTool({ tool, target, options });
    if (executed.error) {
      results.push({ success: false, tool, error: executed.error });
      continue;
    }
    results.push(
      buildResponse({
        success: executed.result.success,
        tool,
        target: target || null,
        command: executed.command,
        result: executed.result,
        report: executed.report.filename,
        artifacts: [executed.report.artifact],
        meta: { options },
      })
    );
  }

  const payload = {
    success: results.every((item) => item.success),
    results,
    timestamp: new Date().toISOString(),
  };
  return res.json(payload);
});

app.post("/api/onion/search", async (req, res) => {
  const {
    query = "",
    wordlist = [],
    wordlistPath = "",
    maxResults = 10,
    maxPages = 5,
    useDuckDuckGo = true,
    timeoutSec = 60,
    maxTextLength = 6000,
  } = req.body;

  const hasWordlist = Array.isArray(wordlist) && wordlist.length > 0;
  if (!query && !hasWordlist && !wordlistPath) {
    return res.status(400).json({ success: false, error: "Query or wordlist is required" });
  }

  const torReady = await ensureTorRunning();
  if (!torReady) {
    return res.status(500).json({ success: false, error: "Tor not running" });
  }

  const searchResults = [];
  const seeds = new Set();
  let searchError = null;

  if (useDuckDuckGo && query) {
    const searchUrl = `${TOR_DDG_ONION}/?q=${encodeURIComponent(query)}&ia=web`;
    const ddg = await fetchViaTor(searchUrl, timeoutSec);
    if (ddg.success) {
      const results = extractDuckDuckGoResults(ddg.stdout).filter((item) => isValidOnionUrl(item.url));
      for (const item of results) {
        if (searchResults.length >= maxResults) {
          break;
        }
        searchResults.push(item);
        seeds.add(item.url);
      }
    } else {
      searchError = ddg.error || ddg.stderr || "duckduckgo_fetch_failed";
    }
  }

  const fileWordlist = wordlistPath ? await loadWordlist(wordlistPath) : [];
  const providedWordlist = Array.isArray(wordlist) ? wordlist : [];
  for (const link of [...providedWordlist, ...fileWordlist]) {
    if (isValidOnionUrl(link)) {
      seeds.add(link);
    }
  }

  const seedLinks = Array.from(seeds).slice(0, Math.max(1, Number(maxResults) || 10));
  const pages = [];
  for (const url of seedLinks.slice(0, Math.max(1, Number(maxPages) || 5))) {
    const pageResult = await fetchViaTor(url, timeoutSec);
    if (!pageResult.success) {
      pages.push({ url, error: pageResult.error || pageResult.stderr || "fetch_failed" });
      continue;
    }
    pages.push(buildPageJson({ url, html: pageResult.stdout, maxTextLength }));
  }

  return res.json({
    success: true,
    query: query || null,
    tor: { socksHost: TOR_SOCKS_HOST, socksPort: TOR_SOCKS_PORT },
    searchResults,
    pages,
    counts: {
      searchResults: searchResults.length,
      pages: pages.length,
      seeds: seedLinks.length,
    },
    searchError,
  });
});

// ==================== METASPLOIT ====================
app.post("/api/exploit/msfconsole", async (req, res) => {
  const { commands } = req.body;

  if (!commands || !Array.isArray(commands)) {
    return res.status(400).json({ error: "Commands array is required" });
  }

  const rcFile = `/tmp/msf_${Date.now()}.rc`;
  await fs.writeFile(rcFile, commands.join("\n"));

  const command = `msfconsole -q -r ${rcFile}`;

  const result = await executeCommand(command, 900000);
  const report = await saveReport("msfconsole", "exploit", { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "msfconsole",
    target: "exploit",
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { commands },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

app.get("/api/skills/list", async (req, res) => {
  const skills = await listSkillNames();
  res.json({ skills: skills.sort() });
});

app.get("/api/skills/:tool", async (req, res) => {
  const { tool } = req.params;
  const result = await readSkillContent(tool);
  if (result.error) {
    return res.status(404).json({ error: result.error });
  }
  return res.json(result);
});

// ==================== TOOLS LIST ====================
app.get("/api/tools/list", async (req, res) => {
  const skillNames = new Set(await listSkillNames());
  const tools = [
    { name: "nmap", category: "scanning", description: "Network port scanner" },
    { name: "masscan", category: "scanning", description: "Fast port scanner" },
    { name: "hydra", category: "bruteforce", description: "Password brute force tool" },
    { name: "medusa", category: "bruteforce", description: "Parallel password cracker" },
    { name: "john", category: "bruteforce", description: "Password hash cracker" },
    { name: "amass", category: "recon", description: "Subdomain enumeration" },
    { name: "subfinder", category: "recon", description: "Fast subdomain discovery" },
    { name: "sqlmap", category: "web", description: "SQL injection tool" },
    { name: "wpscan", category: "web", description: "WordPress vulnerability scanner" },
    { name: "nikto", category: "web", description: "Web server scanner" },
    { name: "dirb", category: "web", description: "Directory brute force" },
    { name: "gobuster", category: "web", description: "URI/DNS brute force" },
    { name: "httpx", category: "web", description: "HTTP probing toolkit" },
    { name: "nuclei", category: "web", description: "Template-based vulnerability scanner" },
    { name: "ffuf", category: "web", description: "Fast web fuzzer" },
    { name: "feroxbuster", category: "web", description: "Content discovery tool" },
    { name: "dirsearch", category: "web", description: "Web path discovery" },
    { name: "crackmapexec", category: "network", description: "AD and SMB testing" },
    { name: "responder", category: "network", description: "LLMNR/NBT-NS poisoning" },
    { name: "impacket-scripts", category: "network", description: "Network protocol scripts" },
    { name: "bloodhound", category: "ad", description: "Active Directory attack paths" },
    { name: "ldapdomaindump", category: "ad", description: "LDAP domain enumeration" },
    { name: "awscli", category: "cloud", description: "AWS CLI tooling" },
    { name: "zaproxy", category: "web", description: "Web proxy and scanner" },
    { name: "burpsuite", category: "web", description: "Web proxy and testing suite" },
    { name: "metasploit", category: "exploitation", description: "Exploitation framework" },
  ];

  const extendedTools = Object.entries(toolRunner).map(([name, config]) => ({
    name,
    category: config.category,
    description: config.description,
    tags: getTags(config.category),
    examples: [toolRunExample(name)],
    skillAvailable: skillNames.has(name),
    skillEndpoint: `/api/skills/${name}`,
  }));

  const baseTools = tools.map((tool) => ({
    ...tool,
    tags: getTags(tool.category),
    examples: [toolRunExample(tool.name)],
    skillAvailable: skillNames.has(tool.name),
    skillEndpoint: `/api/skills/${tool.name}`,
  }));

  res.json({ tools: baseTools.concat(extendedTools) });
});

// ==================== REPORTS ====================
app.get("/api/reports", async (req, res) => {
  try {
    const files = await fs.readdir(REPORTS_DIR);
    const reports = await Promise.all(
      files.map(async (file) => {
        const filePath = path.join(REPORTS_DIR, file);
        const stats = await fs.stat(filePath);
        return {
          name: file,
          path: filePath,
          size: stats.size,
          modifiedAt: stats.mtime.toISOString(),
        };
      })
    );
    res.json({ reports });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get("/api/reports/summary/:filename", async (req, res) => {
  try {
    const filepath = path.join(REPORTS_DIR, req.params.filename);
    const content = await fs.readFile(filepath, "utf8");
    const summary = content.slice(0, 4000);
    res.json({
      filename: req.params.filename,
      summary,
      truncated: content.length > summary.length,
    });
  } catch (error) {
    console.error(error);
    res.status(404).json({ error: "Report not found" });
  }
});

app.get("/api/reports/:filename", async (req, res) => {
  try {
    const filepath = path.join(REPORTS_DIR, req.params.filename);
    const content = await fs.readFile(filepath, "utf8");
    res.json({ filename: req.params.filename, content });
  } catch (error) {
    console.error(error);
    res.status(404).json({ error: "Report not found" });
  }
});

app.get("/api/artifacts", async (req, res) => {
  const { tool, target, type } = req.query;
  const index = await loadArtifactIndex();
  let artifacts = index.artifacts;
  if (tool) {
    artifacts = artifacts.filter((item) => item.tool === tool);
  }
  if (target) {
    artifacts = artifacts.filter((item) => item.target === target);
  }
  if (type) {
    artifacts = artifacts.filter((item) => item.type === type);
  }
  res.json({ artifacts });
});

// ==================== API DOCS (Swagger UI) ====================
app.get("/api-docs", (req, res) => {
  res.setHeader("Content-Type", "text/html");
  res.send(`<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Kali MCP API Docs</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: "/swagger.json",
      dom_id: "#swagger-ui",
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      layout: "BaseLayout",
      deepLinking: true,
      defaultModelsExpandDepth: 1,
      defaultModelExpandDepth: 2,
      docExpansion: "list"
    });
  </script>
</body>
</html>`);
});

app.get("/swagger.json", async (req, res) => {
  try {
    const swaggerPath = path.join(__dirname, "swagger.json");
    const content = await fs.readFile(swaggerPath, "utf-8");
    res.setHeader("Content-Type", "application/json");
    res.send(content);
  } catch (_err) {
    res.status(404).json({ error: "swagger.json not found" });
  }
});

// ==================== NOSQLMAP ====================
app.post("/api/web/nosqlmap", async (req, res) => {
  const { url, options = "" } = req.body;

  if (!url) {
    return res.status(400).json({ error: "URL is required" });
  }

  const command = `nosqlmap -u ${url} ${options}`;

  const result = await executeCommand(command, 600000);
  const report = await saveReport("nosqlmap", url, { command, ...result });
  const payload = buildResponse({
    success: result.success,
    tool: "nosqlmap",
    target: url,
    command,
    result,
    report: report.filename,
    artifacts: [report.artifact],
    meta: { options },
  });
  if (!result.success) {
    return res.status(500).json(payload);
  }
  return res.json(payload);
});

// Error handling
app.use((err, req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Internal server error", message: err.message });
});

// Start server
app.listen(PORT, HOST, () => {
  console.log("=".repeat(50));
  console.log("  Kali MCP Pentest Server");
  console.log("=".repeat(50));
  console.log(`Server running on http://${HOST}:${PORT}`);
  console.log(`API Documentation: http://${HOST}:${PORT}/api-docs`);
  console.log(`Swagger JSON:      http://${HOST}:${PORT}/swagger.json`);
  console.log("=".repeat(50));
  startOpenClawHeartbeat();
});
