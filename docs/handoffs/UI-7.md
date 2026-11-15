# Agent task handoff — UI-7 (a title screen, a loading screen and the web icons)

## Assignment
- **Objective:** the owner's play notes of 2026-11-15: "the Godot loading screen is acting as the title screen; it needs to be replaced with an actual title screen", and "need a favicon and an apple-touch-icon".
- **Owner:** Claude (interface and platform, E26). Reviewer: the repository owner, by PR. Final brand art is Codex's (below).
- **State:** DONE, with provisional art.
- **Branch:** `claude/roguewood-build`, after DC-N3 (`0d23600`).
- **Paths:** src/bootstrap/title_screen.gd (new) and bootstrap.gd; src/platform/web_qa.gd; project.godot (icon, boot splash); export_presets.cfg (the Web page's head); tools/author_brand.py and assets/brand/ (new); tests/shell_smoke.gd (J01), tests/web/web_journey.mjs (JW01), tools/capture_phone_tour.gd; tools/qa.py (J01's captures); docs/art/ASSET-LEDGER.md.

## What changed
- **A title screen** (src/bootstrap/title_screen.gd) opens the game:
  - It shows the House hall at night (Codex's House Division 1 backdrop), the ROGUEWOOD wordmark in the bundled pixel font (bold, brass, ink outline, walnut shadow), the House Ball rolling slowly, and a pulsing "Tap to start" ("Click or press any key" on a desktop without touch).
  - Any tap or click, the accept key, any other key, or a gamepad button starts. The title fades out over 0.3 s to the Clubhouse, with focus on Continue Attempt or Enter League.
  - Under reduced motion the ball and the prompt are still and the fade is skipped. Settings are not yet saved between launches (E25), so this follows the session's setting.
  - The first tap is also the browser's user gesture, so audio can start as soon as the Clubhouse opens.
- **When it shows:** whenever the shell is the running scene, which is how the engine starts the game on the desktop and on the web. A journey or tool that embeds the shell as a child still opens at the Clubhouse, so every other journey is unchanged. J01, the web journey and the phone tour start the game the engine's way and pass the title with real input.
- **The loading screen** is Roguewood's: `application/boot_splash/image` is assets/brand/splash.png (the House Ball over the wordmark), centred on the title's night colour (#0b1116), not stretched. The web page shows it while the engine downloads, with a brass progress bar; the engine shows it again as it starts.
- **Icons:** `application/config/icon` is assets/brand/icon.png (512 × 512, opaque: the House Ball on lane-wood boards, readable at 16 px). Godot's Web export writes the favicon (`index.icon.png`) and the 180 × 180 apple-touch-icon from it. Opaque and full-bleed, because iOS fills transparency with black and rounds the corners itself.
- **The page head** adds `theme-color` (#0b1116) and `apple-mobile-web-app-title` ("Roguewood", the name under a home-screen icon), and the body background matches, so there is no black flash.

## Limitations and choices
- **Provisional art.** The icon, splash and wordmark are composed by tools/author_brand.py and title_screen.gd from Codex's House Ball and House backdrop and the bundled font. No new illustration was made. They stand in until Codex's brand art lands.
- **No subtitle**, per the design plan ("Approved game title: Roguewood. No subtitle").
- **The title has one action.** Options and Continue stay in the Clubhouse, where they are now.
- **Not checked:** the icon on a real iPhone home screen, and the favicon in a desktop browser tab. The web journey checks the files, sizes and links in headless Chromium.

## For Codex (UI-A4, Wave 13; owner, 2026-11-15)
- Prompt: docs/prompts/codex-wave13-ui-a4.md. Every piece goes at a fixed path, so no code changes are needed:
  - **The logo:** `assets/brand/logo.png`. While it exists, the title shows it in place of the lettered wordmark (the label's text stays for tools and tests).
  - **The app icon:** `assets/brand/icon.png`, 512 × 512 and opaque.
  - **The boot splash:** `assets/brand/splash.png`, on #0b1116.
  - **Optional key art:** `assets/brand/title_art.png`, in place of the House backdrop.
- Owner's decisions: no subtitle, and the title keeps one action.
- J01 and JW01 check that the title, the splash and both icons are present, and their sizes. The logo and key-art hooks were tried with a stand-in image (not committed).

## Validation
See docs/AI-HANDOFF.md, "Wave 13 progress".
