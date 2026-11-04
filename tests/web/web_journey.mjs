// JW01 (E26-W01): the Web export end to end in headless Chromium.
// Loads the exported page with ?qa=1 (src/platform/web_qa.gd prints status lines),
// enters the League, throws with a real mouse drag on the ball (touch emulation),
// waits for the roll to settle and the attempt save, reloads the page, and
// continues the saved attempt. Records load time, frame rate and download size.
// Usage: node tests/web/web_journey.mjs <url> <artifact-dir> [--inject-failure]
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const [url, outDir] = process.argv.slice(2);
const injectFailure = process.argv.includes("--inject-failure");
fs.mkdirSync(outDir, { recursive: true });
const failures = [];
const log = [];
const check = (ok, label) => { log.push(`${ok ? "PASS" : "FAIL"} ${label}`); if (!ok) failures.push(label); };

const browser = await chromium.launch({ args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--autoplay-policy=user-gesture-required"] });
const page = await browser.newPage({ viewport: { width: 540, height: 960 }, deviceScaleFactor: 1 });
// Record every AudioContext the page creates, to check the browser's autoplay gate.
await page.addInitScript(() => {
  const Native = window.AudioContext || window.webkitAudioContext;
  window.__audio = [];
  window.AudioContext = window.webkitAudioContext = class extends Native {
    constructor(...args) { super(...args); window.__audio.push(this); }
  };
});
const audioStates = () => page.evaluate(() => (window.__audio || []).map((c) => c.state));
let status = null;
let bytes = 0;
const errors = [];
page.on("console", (msg) => {
  const text = msg.text();
  if (text.startsWith("ROGUEWOOD_WEB_INPUT")) log.push("INPUT " + text.slice(20));
  else if (text.startsWith("ROGUEWOOD_WEB ")) status = JSON.parse(text.slice(14));
  else if (msg.type() === "error" || /SCRIPT ERROR|^ERROR:/.test(text)) errors.push(text);
});
page.on("pageerror", (e) => errors.push(String(e)));
page.on("response", async (r) => { const len = Number(r.headers()["content-length"] || 0); bytes += len; });

async function waitFor(pred, label, ms = 60000) {
  const start = Date.now();
  while (Date.now() - start < ms) {
    if (status && pred(status)) return status;
    await page.waitForTimeout(100);
  }
  check(false, `timed out: ${label} (last status ${JSON.stringify(status)})`);
  throw new Error(label);
}
const click = async (at) => { await page.mouse.click(at[0], at[1]); };

async function load(label) {
  status = null;
  const start = Date.now();
  await page.goto(url, { waitUntil: "load" });
  const s = await waitFor((s) => s.screen === "menu", `${label}: menu`, 120000);
  const seconds = (Date.now() - start) / 1000;
  log.push(`INFO ${label}: menu after ${seconds.toFixed(1)} s`);
  return { s, seconds };
}

try {
  const first = await load("first load");
  check(first.s.enter.visible && !first.s.saved, "first load: a fresh menu with Enter League and no saved attempt");
  log.push(`INFO downloaded ${(bytes / 1048576).toFixed(1)} MB (uncompressed transfer as served)`);
  const touchAction = await page.$eval("canvas", (c) => getComputedStyle(c).touchAction);
  check(touchAction === "none", `the canvas blocks browser scrolling and zooming (touch-action ${touchAction})`);

  // The browser's first click is the user gesture that lets audio start.
  const before = await audioStates();
  await click(first.s.enter.at);
  await page.waitForTimeout(500);
  const after = await audioStates();
  // Headless Chromium does not enforce the autoplay block, so only "running after the
  // first tap" is asserted; real browsers start suspended and Godot resumes on input.
  log.push(`INFO audio contexts before the first tap: ${before.join(",") || "none"}`);
  check(after.some((st) => st === "running"), `audio is running after the first tap (${after.join(",")})`);
  let s = await waitFor((s) => s.screen === "session" && s.state === "aim", "lab ready to aim");
  await page.screenshot({ path: path.join(outDir, "web_aim.png") });

  // A real drag on the ball: hold, then flick straight up fast.
  const [bx, by] = s.ball;
  await page.mouse.move(bx, by);
  await page.mouse.down();
  await page.waitForTimeout(120);
  // Software rendering in headless Chromium runs at about 13 fps and delivers each
  // move a frame or more apart, so the flick is three long steps rather than many
  // short ones; the gesture still sees a fast forward flick.
  for (let i = 1; i <= 2; i++) await page.mouse.move(bx, by - i * 150);
  // A flick lifts off while still moving: the last move and the release arrive in
  // the same browser task (separate Playwright calls would land a frame apart).
  await page.evaluate(([x, y]) => {
    const canvas = document.querySelector("canvas");
    const opts = { clientX: x, clientY: y, bubbles: true, cancelable: true, view: window };
    canvas.dispatchEvent(new MouseEvent("mousemove", { ...opts, buttons: 1 }));
    canvas.dispatchEvent(new MouseEvent("mouseup", { ...opts, button: 0, buttons: 0 }));
  }, [bx, by - 450]);
  s = await waitFor((s) => s.state === "rolling" || s.history >= 1, "the flick commits a throw", 10000);
  check(true, "a mouse flick on the ball commits a throw");
  const fps = [];
  const rollStart = Date.now();
  while (Date.now() - rollStart < 20000 && !(status.history >= 1)) { fps.push(status.fps); await page.waitForTimeout(500); }
  s = await waitFor((s) => s.history >= 1, "the roll settles", 30000);
  const rolled = fps.filter((f) => f > 0);
  log.push(`INFO frame rate while rolling (headless SwiftShader, not a device): ${rolled.join(", ")}`);
  await page.screenshot({ path: path.join(outDir, "web_rolled.png") });
  s = await waitFor((s) => s.saved, "the attempt save exists", 15000);
  check(true, `roll 1 settled (state ${s.state}) and the attempt is saved`);
  await page.waitForTimeout(1500); // let the browser flush user:// to IndexedDB

  const second = await load("reload");
  check(second.s.saved && second.s.continue.visible, "after a reload the menu offers Continue Attempt from IndexedDB");
  await click(second.s.continue.at);
  s = await waitFor((s) => s.screen === "session" && s.history >= 1, "the attempt resumes with its roll", 30000);
  check(s.history >= 1, `the resumed attempt keeps its committed roll (history ${s.history}, state ${s.state})`);
  await page.screenshot({ path: path.join(outDir, "web_resumed.png") });
  check(errors.length === 0, `no script errors (${errors.slice(0, 3).join(" | ")})`);
  if (injectFailure) check(false, "Injected diagnostic failure");
} catch (e) {
  if (!failures.length) check(false, String(e));
  await page.screenshot({ path: path.join(outDir, "web_failure.png") }).catch(() => {});
}
await browser.close();
fs.writeFileSync(path.join(outDir, "journey.log"), log.join("\n") + "\n" + errors.map((e) => "CONSOLE " + e).join("\n") + "\n");
console.log(log.join("\n"));
if (failures.length === 0) console.log("ROGUEWOOD_JW01_OK");
process.exit(failures.length ? 1 : 0);
