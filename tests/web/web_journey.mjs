// JW01 (E26-W01): the Web export end to end in headless Chromium.
// Loads the exported page with ?qa=1 (src/platform/web_qa.gd prints status lines),
// checks the Roguewood loading screen, favicon and apple-touch-icon (UI-7), taps
// through the title screen, enters the League, throws with a real mouse drag on the ball (touch emulation),
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

// Width and height of a PNG served at `href` (from its IHDR chunk).
async function pngSize(href) {
  const response = await page.request.get(new URL(href, page.url()).href);
  const body = await response.body();
  if (!response.ok() || body.length < 24 || body.toString("latin1", 1, 4) !== "PNG") return null;
  return [body.readUInt32BE(16), body.readUInt32BE(20)];
}

// The page loads with the Roguewood splash; the title screen comes up, and a tap on
// it opens the Clubhouse. `tap` is false only to look at the title first.
async function load(label, tap = true) {
  status = null;
  const start = Date.now();
  await page.goto(url, { waitUntil: "load" });
  // While the engine loads, the page shows its own loading screen (gone once the
  // engine starts, so it is read now).
  const head = await page.evaluate(() => {
    const splash = document.querySelector("#status-splash");
    const overlay = document.querySelector("#status");
    return {
      icon: document.querySelector('link[rel="icon"]')?.getAttribute("href"),
      touch: document.querySelector('link[rel="apple-touch-icon"]')?.getAttribute("href"),
      splash: splash?.getAttribute("src"), splashClass: splash?.className || "",
      statusColor: overlay ? getComputedStyle(overlay).backgroundColor : "",
      theme: document.querySelector('meta[name="theme-color"]')?.getAttribute("content"),
      homeName: document.querySelector('meta[name="apple-mobile-web-app-title"]')?.getAttribute("content"),
      title: document.title,
    };
  });
  if (!tap) await page.screenshot({ path: path.join(outDir, "web_loading.png") });
  let s = await waitFor((s) => s.screen === "title" && s.title.visible, `${label}: title screen`, 120000);
  const seconds = (Date.now() - start) / 1000;
  log.push(`INFO ${label}: title after ${seconds.toFixed(1)} s`);
  if (tap) {
    await page.waitForTimeout(300);
    await click(s.title.at);
    s = await waitFor((s) => s.screen === "menu", `${label}: the tap opens the Clubhouse`, 15000);
  }
  return { s, seconds, head };
}

try {
  // UI-7: the loading screen, the favicon and the apple-touch-icon are Roguewood's.
  const titled = await load("first load", false);
  const before = await audioStates();
  const head = titled.head;
  const favicon = head.icon ? await pngSize(head.icon) : null;
  const touch = head.touch ? await pngSize(head.touch) : null;
  const splash = head.splash ? await pngSize(head.splash) : null;
  check(favicon && favicon[0] === favicon[1] && favicon[0] >= 192 && head.icon === "index.icon.png", `the favicon is the project icon, square (${head.icon} ${favicon})`);
  check(touch && touch[0] === 180 && touch[1] === 180, `the apple-touch-icon is 180 x 180 (${head.touch} ${touch})`);
  check(splash && splash[0] === 720 && splash[1] === 560 && head.splashClass.includes("fullsize--false") && head.statusColor === "rgb(11, 17, 22)",
    `the loading screen is the Roguewood splash on the night background (${head.splash} ${splash}, ${head.splashClass}, ${head.statusColor})`);
  check(head.theme === "#0b1116" && head.homeName === "Roguewood" && head.title === "Roguewood", `theme colour, home-screen name and page title (${JSON.stringify(head)})`);
  // UI-10: the loading progress is a pixel ball rolling down a short lane toward a pin,
  // driven by the engine's own progress element (kept, invisible); the pin tips at 100%.
  // UI-36: the spin, bob and roll are CSS animations and transitions (they keep playing
  // while a phone's main thread starts the game), an unknown download size loops the
  // roll and knockdown, and when the engine removes its overlay the knockdown plays out
  // before the overlay fades. The engine removes its overlay once it starts, so the
  // loader is run again on a stand-in overlay with the same ids.
  const loader = await page.evaluate(async () => {
    if (!document.querySelector("#rw-loader-js") || typeof window.rwLoaderStart !== "function") return { found: false };
    const wait = (ms) => new Promise((r) => setTimeout(r, ms));
    const stand = document.createElement("div");
    stand.id = "status";
    stand.style.cssText = "position:absolute;inset:0;width:600px;height:400px;";
    stand.innerHTML = '<progress id="status-progress"></progress>';
    document.body.appendChild(stand);
    window.rwLoaderStart(stand);
    await new Promise((r) => requestAnimationFrame(r));
    const lane = stand.querySelector("#rw-loader"), pr = stand.querySelector("#status-progress");
    if (!lane) return { found: false, started: true };
    const roll = lane.querySelector("#rw-roll"), pin = lane.querySelector("#rw-pin");
    const css = (el) => el.getAnimations().map((a) => a.animationName || a.transitionProperty).filter(Boolean);
    const shown = pr.style.display, opacity = getComputedStyle(pr).opacity;
    const at = async (value) => {
      pr.style.display = "block"; pr.max = 1; pr.value = value;
      await wait(700);
      const m = new DOMMatrixReadOnly(getComputedStyle(roll).transform);
      return { x: m.m41, shown: getComputedStyle(lane).display, progress: lane.dataset.progress, pinDown: pin.classList.contains("down") };
    };
    const quarter = await at(0.25);
    const moving = { ball: css(lane.querySelector("#rw-ball")), bob: css(lane.querySelector("#rw-bob")) };
    const most = await at(0.9);
    // UI-38: at 100% the pin waits for the ball to reach it.
    pr.value = 1;
    await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
    const arriving = { progress: lane.dataset.progress, pinDown: pin.classList.contains("down") };
    const done = await at(1.0);
    // No total from the server: the roll and the knockdown loop.
    pr.removeAttribute("value");
    await wait(100);
    const idle = { progress: lane.dataset.progress, idle: lane.classList.contains("idle"), roll: css(roll), pin: css(pin) };
    // The engine removes the overlay: it comes back for the knockdown, then fades and goes.
    stand.remove();
    await wait(200);
    const finale = { back: stand.isConnected, pinDown: pin.classList.contains("down"), progress: lane.dataset.progress, taps: getComputedStyle(stand).pointerEvents };
    await wait(1500);
    finale.gone = !stand.isConnected;
    pr.style.display = shown;
    return { found: true, opacity, ball: lane.querySelector("#rw-ball").getAttribute("src").startsWith("data:image/svg+xml"), quarter, moving, most, arriving, done, idle, finale };
  });
  check(loader.found && loader.opacity === "0" && loader.ball && loader.quarter.shown === "block" && loader.most.x > loader.quarter.x + 40
    && !loader.most.pinDown && loader.done.pinDown && loader.done.progress === "1.000", `the loader rolls a pixel ball toward a pin that tips at 100% (${JSON.stringify(loader)})`);
  check(loader.found && loader.arriving.progress === "1.000" && !loader.arriving.pinDown && loader.done.pinDown,
    `at 100% the pin falls only once the ball reaches it (${JSON.stringify(loader.arriving)})`);
  check(loader.found && loader.moving.ball.includes("rw-spin") && loader.moving.bob.includes("rw-bob"),
    `the ball's spin and bob are CSS animations (${JSON.stringify(loader.moving)})`);
  check(loader.found && loader.idle.idle && loader.idle.progress === "idle" && loader.idle.roll.includes("rw-run") && loader.idle.pin.includes("rw-knock"),
    `with no known download size the ball rolls and knocks the pin over in a loop (${JSON.stringify(loader.idle)})`);
  check(loader.found && loader.finale.back && loader.finale.pinDown && loader.finale.progress === "1.000" && loader.finale.taps === "none" && loader.finale.gone,
    `when the engine removes its overlay, the knockdown plays out, taps pass through, then it goes (${JSON.stringify(loader.finale)})`);
  await page.screenshot({ path: path.join(outDir, "web_title.png") });
  // The browser's first tap, on the title, is the user gesture that lets audio start.
  await click(titled.s.title.at);
  const first = { s: await waitFor((s) => s.screen === "menu", "first load: the tap opens the Clubhouse", 15000) };
  check(first.s.enter.visible && !first.s.saved, "first load: a tap on the title opens a fresh menu with Enter League and no saved attempt");
  log.push(`INFO downloaded ${(bytes / 1048576).toFixed(1)} MB (uncompressed transfer as served)`);
  const touchAction = await page.$eval("canvas", (c) => getComputedStyle(c).touchAction);
  check(touchAction === "none", `the canvas blocks browser scrolling and zooming (touch-action ${touchAction})`);

  await click(first.s.enter.at);
  await page.waitForTimeout(500);
  const after = await audioStates();
  // Headless Chromium does not enforce the autoplay block, so only "running after the
  // first tap" is asserted; real browsers start suspended and Godot resumes on input.
  log.push(`INFO audio contexts before the first tap: ${before.join(",") || "none"}`);
  check(after.some((st) => st === "running"), `audio is running after the first taps (${after.join(",")})`);
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
