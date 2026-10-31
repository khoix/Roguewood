"""Roguewood headless verification; unimplemented suites fail explicitly."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# Captured evidence is output, never a Godot resource. Avoid reimporting every
# journey screenshot before each subsequent check (and on resumed workspaces).
(ROOT / "artifacts").mkdir(exist_ok=True)
(ROOT / "artifacts/.gdignore").touch()
VERSION = (ROOT / ".godot-version").read_text().strip()
# journey -> script, success marker, artifact directory, rendered captures, timeout, extra engine flags
JOURNEYS = {
    "JAVC07AC": ("res://tests/upgrade_identity_contact.gd", "ROGUEWOOD_UPGRADE_IDENTITY_OK", "artifacts/av-c07-a/contact", ("contact",), 180, ["--fixed-fps", "60"]),
    "J21R03": ("res://tests/proprietor_art_journey.gd", "ROGUEWOOD_J21R03_OK", "artifacts/e21-r03/native",
        ("rival.proprietor_intro", "rival.proprietor_landscape", "proprietor_reduced", "proprietor_reaction", "proprietor_defeated"), 900, ["--fixed-fps", "60"]),
    "J21R04": ("res://tests/house_rival_art_journey.gd", "ROGUEWOOD_J03C05_OK", "artifacts/e21-r04/native",
        ("rival.custodian_champion_intro", "rival.custodian_champion_landscape", "rival.old_lou_intro", "rival.old_lou_landscape", "c05_house_rules", "c05_champion", "c05_house_pins", "rival.old_lou_defeated"), 900, ["--fixed-fps", "60"]),
    "J21RC": ("res://tests/house_rival_contact.gd", "ROGUEWOOD_HOUSE_RIVAL_CONTACT_OK", "artifacts/e21-r03-r04/contact",
        ("rival.proprietor", "rival.old_lou"), 180, ["--fixed-fps", "60"]),
    "J22L01ART": ("res://tests/house_theme_journey.gd", "ROGUEWOOD_HOUSE_THEME_OK", "artifacts/e22-l01-art",
        tuple("division_%02d" % i for i in range(1,9)) + ("championship", "house_oil", "dry_backend", "reduced", "landscape", "contact"), 180, ["--fixed-fps", "60"]),
    "JAVC04CC": ("res://tests/av_c04_contact.gd", "ROGUEWOOD_AV_C04_CONTACT_OK", "artifacts/av-c04-c/contact", ("contact",), 180, ["--fixed-fps", "60"]),
    "JAVC04C": ("res://tests/av_c04_c_journey.gd", "ROGUEWOOD_AV_C03_OK AV-C04-C", "artifacts/av-c04-c/native",
        ("ball_mod_echo_charge_shop", "pin_mod_lantern_shop", "owned_shop", "inventory", "ball_mod_echo_charge_inspector", "ball_mod_echo_charge_binder", "pin_mod_lantern_binder", "ball_mod_echo_charge_host_detail", "charge_hook_shop", "charge_hook_host_detail", "pin_mod_lantern_host_detail", "ball_mod_echo_charge_activation", "pin_mod_lantern_activation", "lantern_unlit", "lantern_reduced", "charge_rolling", "charge_hook_rolling", "stage1_reduced", "stage1_landscape"), 900, ["--fixed-fps", "60"]),
    "JAVC04BC": ("res://tests/av_c04_contact.gd", "ROGUEWOOD_AV_C04_CONTACT_OK", "artifacts/av-c04-b/contact", ("contact",), 180, ["--fixed-fps", "60"]),
    "JAVC04B": ("res://tests/av_c04_b_journey.gd", "ROGUEWOOD_AV_C03_OK AV-C04-B", "artifacts/av-c04-b/native",
        ("ball_mod_chalk_grip_shop", "ball_mod_spin_wax_shop", "ball_mod_coin_slot_shop", "owned_shop", "inventory", "ball_mod_chalk_grip_binder", "ball_mod_spin_wax_binder", "ball_mod_coin_slot_binder", "ball_mod_chalk_grip_inspector", "ball_mod_spin_wax_inspector", "ball_mod_coin_slot_inspector", "ball_mod_chalk_grip_host_detail", "ball_mod_spin_wax_host_detail", "ball_mod_coin_slot_host_detail", "ball_mod_chalk_grip_rolling", "ball_mod_spin_wax_rolling", "ball_mod_coin_slot_rolling", "ball_mod_chalk_grip_activation", "ball_mod_spin_wax_activation", "ball_mod_coin_slot_activation", "wax_trail", "stage1_reduced", "stage1_landscape"), 900, ["--fixed-fps", "60"]),
    "JAVC04AC": ("res://tests/av_c04_contact.gd", "ROGUEWOOD_AV_C04_CONTACT_OK", "artifacts/av-c04-a/contact", ("contact",), 180, ["--fixed-fps", "60"]),
    "JAVC04A": ("res://tests/av_c04_a_journey.gd", "ROGUEWOOD_AV_C03_OK AV-C04-A", "artifacts/av-c04-a/native",
        ("pin_mod_brass_cap_shop", "pin_mod_gilt_leaf_shop", "pin_mod_keystone_shop", "owned_shop", "inventory", "pin_mod_brass_cap_host_detail", "pin_mod_gilt_leaf_host_detail", "pin_mod_keystone_host_detail", "pin_mod_brass_cap_binder", "pin_mod_gilt_leaf_binder", "pin_mod_keystone_binder", "host_overlays", "pin_mod_brass_cap_activation", "pin_mod_gilt_leaf_activation", "pin_mod_keystone_activation", "stage1_reduced", "stage1_landscape"), 900, ["--fixed-fps", "60"]),
    "JAVC03BC": ("res://tests/av_c03_contact.gd", "ROGUEWOOD_AV_C03_CONTACT_OK", "artifacts/av-c03-b/contact", ("contact",), 180, ["--fixed-fps", "60"]),
    "JAVC03B": ("res://tests/av_c03_b_journey.gd", "ROGUEWOOD_AV_C03_OK", "artifacts/av-c03-b/native",
        ("charm_sweet_spot_shop", "charm_back_row_shop", "charm_underdog_shop", "inventory", "charm_sweet_spot_binder", "charm_back_row_binder", "charm_underdog_binder", "charm_sweet_spot_activation", "charm_back_row_activation", "charm_underdog_activation", "back_row_partial", "stage1_reduced", "stage1_landscape"), 900, ["--fixed-fps", "60"]),
    "JAVC03AC": ("res://tests/av_c03_contact.gd", "ROGUEWOOD_AV_C03_CONTACT_OK", "artifacts/av-c03-a/contact", ("contact",), 180, ["--fixed-fps", "60"]),
    "JAVC03A": ("res://tests/av_c03_a_journey.gd", "ROGUEWOOD_AV_C03_OK", "artifacts/av-c03-a/native",
        ("pin_crown_shop", "charm_crown_jewel_shop", "charm_split_specialist_shop", "inventory", "pin_crown_binder", "charm_crown_jewel_binder", "charm_split_specialist_binder", "crown_rack_detail", "pin_crown_activation", "pin_crown_zero_activation", "charm_crown_jewel_activation", "charm_split_specialist_activation", "stage1_reduced", "stage1_landscape"), 900, ["--fixed-fps", "60"]),
    "J12V08C": ("res://tests/ability_v08_contact.gd", "ROGUEWOOD_V08_CONTACT_OK", "artifacts/e20-v08/contact", ("contact",), 180, ["--fixed-fps", "60"]),
    "J12V08": ("res://tests/ability_v08_journey.gd", "ROGUEWOOD_V08_OK", "artifacts/e20-v08/native",
        ("charm_pin_counter_activation", "charm_hot_streak_activation", "charm_last_stand_activation", "charm_tip_jar_activation", "charm_banana_ball_activation", "charm_plumb_line_activation", "charm_glass_cutter_activation", "pin_glass_activation", "glass_ordered_breaks", "stage3_fast", "stage1_reduced", "stage2_reduced", "stage3_reduced", "stage1_landscape", "stage2_landscape", "stage3_landscape"), 900, ["--fixed-fps", "60"]),
    "J19A16": ("res://tests/glass_art_journey.gd", "ROGUEWOOD_GLASS_ART_OK", "artifacts/e19-a16/native",
        ("glass_shop", "glass_inventory", "glass_rack", "glass_rack_detail", "glass_reduced", "glass_landscape", "glass_break", "glass_break_detail", "glass_binder", "glass_restored", "glass_next_rack"), 900, ["--fixed-fps", "60"]),
    "J03C02": ("res://tests/glass_c02_journey.gd", "ROGUEWOOD_J03C02_OK", "artifacts/e18-c02", ("c02_breaks", "c02_reloaded", "c02_second"), 600, ["--fixed-fps", "60"]),
    "J03C05": ("res://tests/house_c05_journey.gd", "ROGUEWOOD_J03C05_OK", "artifacts/e18-c05", ("c05_house_rules", "c05_champion", "c05_house_pins"), 900, ["--fixed-fps", "60"]),
    "J03C06": ("res://tests/tactics_c06_journey.gd", "ROGUEWOOD_J03C06_OK", "artifacts/e18-c06", ("c06_shop", "c06_reserve_call", "c06_nudge", "c06_feature_frame", "c06_rule_waiver", "c06_surveyor"), 900, ["--fixed-fps", "60"]),
    "J03C07": ("res://tests/upgrades_c07_journey.gd", "ROGUEWOOD_J03C07_OK", "artifacts/e18-c07", ("c07_license", "c07_upgrades", "c07_feature_shop", "c07_division_two"), 900, ["--fixed-fps", "60"]),
    "J03C08": ("res://tests/house_c08_journey.gd", "ROGUEWOOD_J03C08_OK", "artifacts/e18-c08", ("c08_shop", "c08_strike", "c08_open", "c08_holdouts"), 900, ["--fixed-fps", "60"]),
    "J03C09": ("res://tests/house_c09_journey.gd", "ROGUEWOOD_J03C09_OK", "artifacts/e18-c09", ("c09_shop", "c09_rally", "c09_pickup"), 900, ["--fixed-fps", "60"]),
    "J03C10": ("res://tests/house_c10_journey.gd", "ROGUEWOOD_J03C10_OK", "artifacts/e18-c10", ("c10_shop", "c10_strike", "c10_spare", "c10_open", "c10_jar"), 900, ["--fixed-fps", "60"]),
    "J03C04": ("res://tests/mods_c04_journey.gd", "ROGUEWOOD_J03C04_OK", "artifacts/e18-c04", ("c04_shop", "c04_strike", "c04_open"), 900, ["--fixed-fps", "60"]),
    "J03C03": ("res://tests/crown_c03_journey.gd", "ROGUEWOOD_J03C03_OK", "artifacts/e18-c03", ("c03_split", "c03_strike"), 600, ["--fixed-fps", "60"]),
    "J03C01": ("res://tests/charm_c01_journey.gd", "ROGUEWOOD_J03C01_OK", "artifacts/e18-c01", ("c01_strike", "c01_streak", "c01_spare", "c01_open"), 600, ["--fixed-fps", "60"]),
    "J11": ("res://tests/clubhouse_journey.gd", "ROGUEWOOD_J11_OK", "artifacts/e16",
            ("clubhouse_locked", "clubhouse_goals", "clubhouse_mastered", "clubhouse_trophies", "clubhouse_discovered", "clubhouse_return"), 1500, ["--fixed-fps", "60"]),
    "J10": ("res://tests/career_journey.gd", "ROGUEWOOD_J10_OK", "artifacts/e15",
            ("career_fresh", "career_unlocked", "career_spare", "career_lost", "career_no_duplicate", "career_practice", "career_menu"), 900, ["--fixed-fps", "60"]),
    "J09": ("res://tests/campaign_journey.gd", "ROGUEWOOD_J09_OK", "artifacts/e14", ("campaign_shop", "campaign_won", "campaign_endless", "campaign_lost"), 1500, ["--fixed-fps", "60"]),
    "J08": ("res://tests/motion_journey.gd", "ROGUEWOOD_J08_OK", "artifacts/e12",
            ("aim", "foil", "reveal", "rolling", "impact", "scoring", "reaction", "returned"), 900, ["--fixed-fps", "60"]),
    "J01": ("res://tests/shell_smoke.gd", "ROGUEWOOD_SHELL_OK", "artifacts/e03", ("menu", "session", "reset", "returned"), 30, []),
    "J02": ("res://tests/throw_journey.gd", "ROGUEWOOD_J02_OK", "artifacts/e04",
            ("aim", "cancelled", "rolling", "roll1", "roll2_aim", "frame", "gutter", "target", "curve_right_hold",
             "curve_right", "curve_left", "assist", "landscape"), 600, ["--fixed-fps", "60"]),
    "J03": ("res://tests/scoring_journey.gd", "ROGUEWOOD_J03_OK", "artifacts/e06",
            ("scoring", "strike", "spare", "open"), 600, ["--fixed-fps", "60"]),
    "J04": ("res://tests/deck_journey.gd", "ROGUEWOOD_J04_OK", "artifacts/e07",
            ("hand", "keep", "match_over", "exhausted", "direct"), 900, ["--fixed-fps", "60"]),
    "J05": ("res://tests/shop_journey.gd", "ROGUEWOOD_J05_OK", "artifacts/e08",
            ("shop", "bought", "funds", "place_pin", "full_slot", "removed", "landscape", "match2"), 900, ["--fixed-fps", "60"]),
    "J06": ("res://tests/division_journey.gd", "ROGUEWOOD_J06_OK", "artifacts/e13",
            ("slice_preview", "slice_echo", "slice_shop", "slice_dead_straight", "slice_cleared", "slice_clean_sweep", "slice_won",
             "slice_lost_again", "preview", "shop_preview", "intro", "boss", "lost", "won", "lost_again"), 1500, ["--fixed-fps", "60"]),
    "J07": ("res://tests/save_journey.gd", "ROGUEWOOD_J07_OK", "artifacts/e10",
            ("continue_menu", "resumed_hand", "resumed_roll", "resumed_frame", "resumed_shop", "resumed_reroll",
             "resumed_roll2", "career_kept", "fallback", "no_save"), 300, ["--fixed-fps", "60"]),
}
# Wave 1 presentation extension; production slice content (separate from lab J08).
JOURNEYS["J08A01"] = ("res://tests/ball_art_journey.gd", "ROGUEWOOD_BALL_ART_OK", "artifacts/e19-a01/native",
                       ("ball_inspect", "ball_aim", "ball_scored", "ball_reduced"), 300, ["--fixed-fps", "60"])
# A01 completion evidence: actual offer artwork and House binder slot.
JOURNEYS["J08A01"] = (*JOURNEYS["J08A01"][:3], JOURNEYS["J08A01"][3] + ("ball_shop", "ball_house"), *JOURNEYS["J08A01"][4:])
JOURNEYS["J08A02"] = ("res://tests/pin_art_journey.gd", "ROGUEWOOD_PIN_ART_OK", "artifacts/e19-a02/native",
                       ("pin_rack", "pin_reduced", "pin_fallen", "pin_ruby_shop", "pin_gold_shop", "pin_anchor_shop",
                        "pin_wood_binder", "pin_ruby_binder", "pin_gold_binder", "pin_anchor_binder"), 300, ["--fixed-fps", "60"])
JOURNEYS["J08A02"] = (*JOURNEYS["J08A02"][:3], JOURNEYS["J08A02"][3] + ("pin_rack_detail", "pin_impact_detail"), *JOURNEYS["J08A02"][4:])
# Wave 1 item identity batches share the real purchase/placement/binder journey.
JOURNEYS["J08A03"] = ("res://tests/item_art_journey.gd", "ROGUEWOOD_ITEM_ART_OK", "artifacts/e19-a03/native",
                       ("equipped", "reduced", "scored", "landscape", "rack_detail"), 600, ["--fixed-fps", "60"])
JOURNEYS["J08A04"] = ("res://tests/item_art_journey.gd", "ROGUEWOOD_ITEM_ART_OK", "artifacts/e19-a04/native",
                       ("equipped", "reduced", "scored", "landscape"), 600, ["--fixed-fps", "60"])
JOURNEYS["J08A05"] = ("res://tests/item_art_journey.gd", "ROGUEWOOD_ITEM_ART_OK", "artifacts/e19-a05/native",
                       ("equipped", "reduced", "scored", "landscape"), 600, ["--fixed-fps", "60"])
JOURNEYS["J08A06"] = ("res://tests/item_art_journey.gd", "ROGUEWOOD_ITEM_ART_OK", "artifacts/e19-a06/native",
                       ("equipped", "reduced", "scored", "landscape"), 600, ["--fixed-fps", "60"])
JOURNEYS["J08A06R"] = ("res://tests/rule_art_journey.gd", "ROGUEWOOD_J06_STAGE1_OK", "artifacts/e19-a06/rules",
                       ("slice_preview", "slice_dead_straight", "slice_clean_sweep", "slice_won"), 900, ["--fixed-fps", "60"])
JOURNEYS["J08A07"] = ("res://tests/item_art_journey.gd", "ROGUEWOOD_ITEM_ART_OK", "artifacts/e19-a07/native",
                       ("equipped", "reduced", "scored", "landscape", "kit_house_binder"), 600, ["--fixed-fps", "60"])
JOURNEYS["J12R01"] = ("res://tests/rival_art_journey.gd", "ROGUEWOOD_J06_STAGE1_OK", "artifacts/e21-r01/native",
                       ("slice_dead_straight", "slice_clean_sweep", "slice_won"), 1200, ["--fixed-fps", "60"])
JOURNEYS["J12R02"] = ("res://tests/rival_art_journey.gd", "ROGUEWOOD_J06_STAGE1_OK", "artifacts/e21-r02/native",
                       ("rival_custodian_intro", "slice_dead_straight", "slice_clean_sweep", "slice_won"), 1200, ["--fixed-fps", "60"])
JOURNEYS["J12V01"] = ("res://tests/ability_journey.gd", "ROGUEWOOD_ABILITY_OK", "artifacts/e20-v01/native",
                       ("ball_echo_activation", "charm_encore_activation", "resolved", "reduced", "landscape"), 900, ["--fixed-fps", "60"])
JOURNEYS["J12V02"] = ("res://tests/ability_journey.gd", "ROGUEWOOD_ABILITY_OK", "artifacts/e20-v02/native",
                       ("pin_grower_activation", "charm_patient_investor_activation", "resolved", "reduced", "landscape"), 900, ["--fixed-fps", "60"])
JOURNEYS["J12V03"] = ("res://tests/ability_journey.gd", "ROGUEWOOD_ABILITY_OK", "artifacts/e20-v03/native",
                       ("pin_gold_activation", "charm_gold_rush_activation", "resolved", "reduced", "landscape"), 900, ["--fixed-fps", "60"])
JOURNEYS["J12V04"] = ("res://tests/ability_journey.gd", "ROGUEWOOD_ABILITY_OK", "artifacts/e20-v04/native",
                       ("pin_anchor_activation", "charm_standing_order_activation", "charm_lone_survivor_activation", "resolved", "reduced", "landscape"), 900, ["--fixed-fps", "60"])
JOURNEYS["J12V05"] = ("res://tests/ability_journey.gd", "ROGUEWOOD_ABILITY_OK", "artifacts/e20-v05/native",
                       ("charm_finisher_activation", "charm_turkey_club_activation", "charm_last_chance_activation", "resolved", "reduced", "landscape"), 900, ["--fixed-fps", "60"])
JOURNEYS["J12V06"] = ("res://tests/ability_journey.gd", "ROGUEWOOD_ABILITY_OK", "artifacts/e20-v06/native",
                       ("charm_flat_bonus_activation", "charm_spare_change_activation", "charm_house_favorite_activation", "resolved", "reduced", "landscape"), 900, ["--fixed-fps", "60"])
JOURNEYS["J12V07"] = ("res://tests/ability_journey.gd", "ROGUEWOOD_ABILITY_OK", "artifacts/e20-v07/native",
                       ("ball_hook_activation", "charm_hook_artist_activation", "ball_hammer_activation", "pin_rubber_activation", "pin_wood_activation", "pin_ruby_activation", "resolved", "reduced", "landscape"), 1200, ["--fixed-fps", "60"])
JOURNEYS["J12"] = ("res://tests/dense_ability_journey.gd", "ROGUEWOOD_DENSE_ABILITY_OK", "artifacts/e20-dense/native",
                    ("dense", "controls", "reduced", "landscape", "settlement"), 1200, ["--fixed-fps", "60"])
# Content set per journey (E13, ADR 008): mechanism journeys keep the lab fixtures;
# the shell journey and J06 stage 1 play the production slice (the game's default).
CONTENT = {"J03C05": "house_c05", "J09": "slice", "J02": "lab", "J03": "lab", "J04": "lab", "J05": "lab", "J07": "lab", "J08": "lab"}
CONTENT.update({"J21R03": "house_c05", "J21R04": "house_c05"})
# Multi-stage journeys whose stages are different scripts, content and save
# directories: J06 plays the slice's two Divisions, then the E09 lab Division.
STAGE_RUNS = {"J06": [("res://tests/slice_journey.gd", "slice"), ("res://tests/division_journey.gd", "lab")]}
STAGE_RUNS["J12V08"] = [("res://tests/ability_v08_journey.gd", "slice")] * 3
# Journeys that restart the game: each stage is a separate engine process sharing
# one save directory; stage k prints ROGUEWOOD_<journey>_STAGE<k>_OK.
STAGES = {"J09": 3, "J07": 10, "J10": 3, "J11": 2}
# Wave 2: retain the complete J11 flow and add Clubhouse art/layout assertions.
JOURNEYS["J11ART"] = ("res://tests/art_club_journey.gd", "ROGUEWOOD_J11_OK", "artifacts/e16-art/native",
    ("clubhouse_locked_720", "clubhouse_mastered_1280", "clubhouse_trophies_bottom_720", "clubhouse_discovered_1280"), 1200, ["--fixed-fps", "60"])
STAGES["J11ART"] = 2
# Wave 3 D02 previews read both authored and landed design blocks.
for art_batch in range(13, 16):
    JOURNEYS[f"J19A{art_batch:02}"] = ("res://tests/art_d02_preview.gd", "ROGUEWOOD_D02_ART_OK",
        f"artifacts/e19-a{art_batch:02}/preview", ("contact", "comparison"), 180, ["--fixed-fps", "60"])
for art_batch in (13, 14):
    JOURNEYS[f"J19A{art_batch:02}N"] = ("res://tests/art_d02_native_journey.gd", "ROGUEWOOD_D02_NATIVE_ART_OK",
        f"artifacts/e19-a{art_batch:02}/native", ("inventory", "reduced", "landscape", "scored"), 900, ["--fixed-fps", "60"])

# Authored D01 resources stay out of the live catalogue until E18.
for art_batch in range(8, 13):
    JOURNEYS[f"J19A{art_batch:02}"] = ("res://tests/art_d01_preview.gd", "ROGUEWOOD_D01_ART_OK",
        f"artifacts/e19-a{art_batch:02}/preview", ("contact", "comparison"), 180, ["--fixed-fps", "60"])


def engine():
    executable = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    if not executable:
        raise RuntimeError("Godot not found; install pinned version and set GODOT_BIN")
    version = subprocess.check_output([executable, "--version"], text=True).strip()
    if not version.startswith(VERSION + ".stable."):
        raise RuntimeError(f"Expected {VERSION}.stable, got {version}")
    return executable


def run(args, marker=None, log_path=None, timeout=120):
    try:
        result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        def decode(value):
            return value.decode(errors="replace") if isinstance(value, bytes) else (value or "")
        output = decode(error.stdout) + decode(error.stderr) + "\nTIMEOUT\n"
        if log_path:
            log_path.parent.mkdir(parents=True, exist_ok=True)
            log_path.write_text(output)
        raise RuntimeError(f"Timed out after {timeout}s: {args}") from error
    output = result.stdout + result.stderr
    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_path.write_text(output)
    print(output, end="")
    if result.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output:
        raise RuntimeError(f"Command failed: {args}")
    if marker and marker not in output:
        raise RuntimeError(f"Missing completion marker: {marker}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["doctor", "import", "smoke", "export", "unit", "integration", "content", "physics", "shell", "e2e", "experiment", "slice"])
    parser.add_argument("--journey", choices=sorted(JOURNEYS), default="J01")
    parser.add_argument("--rendered", action="store_true", help="Use a real display; on Linux run via xvfb-run")
    parser.add_argument("--inject-failure", action="store_true", help="Exercise J01 failure artifacts")
    args = parser.parse_args()
    exe = engine()
    if args.command == "doctor":
        print(f"Godot {VERSION}; Python {sys.version.split()[0]}; project={ROOT}")
        return
    run([exe, "--headless", "--path", str(ROOT), "--editor", "--import"])
    if args.command in ("unit", "content", "integration"):
        run([exe, "--headless", "--path", str(ROOT), "--script", "res://tests/run_tests.gd", "--", args.command], "ROGUEWOOD_" + args.command.upper() + "_OK")
    elif args.command == "physics":
        artifact_dir = ROOT / "artifacts/e04"
        artifact_dir.mkdir(parents=True, exist_ok=True)
        report = artifact_dir / "physics-report.json"
        report.unlink(missing_ok=True)
        run([exe, "--headless", "--fixed-fps", "60", "--path", str(ROOT), "--script", "res://tests/run_tests.gd", "--", "physics",
             "--report=" + str(report)], "ROGUEWOOD_PHYSICS_OK", artifact_dir / "physics.log", timeout=600)
    elif args.command == "experiment":
        artifact_dir = ROOT / "artifacts/e07"
        artifact_dir.mkdir(parents=True, exist_ok=True)
        report = artifact_dir / "deck-experiment.json"
        report.unlink(missing_ok=True)
        run([exe, "--headless", "--path", str(ROOT), "--script", "res://tools/deck_experiment.gd", "--", "--runs=1000",
             "--out=" + str(report)], "ROGUEWOOD_EXPERIMENT_OK", artifact_dir / "experiment.log", timeout=600)
    elif args.command == "slice":
        # E13 seeded build-strategy simulation of the vertical slice (ADR 008), with a
        # fresh Career and with both rival unlocks.
        artifact_dir = ROOT / "artifacts/e13"
        artifact_dir.mkdir(parents=True, exist_ok=True)
        for label, flags in [("locked", []), ("unlocked", ["--unlocked"])]:
            report = artifact_dir / ("slice-strategies-%s.json" % label)
            report.unlink(missing_ok=True)
            run([exe, "--headless", "--path", str(ROOT), "--script", "res://tools/slice_strategies.gd", "--", "--runs=400",
                 "--out=" + str(report), *flags], "ROGUEWOOD_SLICE_SIM_OK", artifact_dir / ("slice-%s.log" % label), timeout=900)
    elif args.command == "e2e":
        script, marker, artifacts, captures, timeout, engine_flags = JOURNEYS[args.journey]
        flags = ["--audio-driver", "Dummy", *engine_flags]
        if not args.rendered:
            flags.append("--headless")
        mode = "rendered" if args.rendered else "headless"
        if args.inject_failure:
            mode += "-failure"
        artifact_dir = ROOT / artifacts / mode
        artifact_dir.mkdir(parents=True, exist_ok=True)
        for old in artifact_dir.glob("*.png"):
            old.unlink()
        # Every journey saves into its own fresh directory, never the user's saves.
        save_dir = artifact_dir / "saves"
        shutil.rmtree(save_dir, ignore_errors=True)
        save_dir.mkdir(parents=True)
        extra = ["--artifact-dir=" + str(artifact_dir), "--save-dir=" + str(save_dir),
                 "--content=" + CONTENT.get(args.journey, "slice")]
        stages = STAGES.get(args.journey, 0) or len(STAGE_RUNS.get(args.journey, []))
        if not stages:
            if args.inject_failure:
                extra.append("--inject-failure")
            run([exe, *flags, "--path", str(ROOT), "--script", script, "--", *extra],
                marker, artifact_dir / "journey.log", timeout=timeout)
        else:
            logs = []
            for stage in range(1, stages + 1):
                stage_script, stage_extra = script, extra + ["--stage=%d" % stage]
                if args.journey in STAGE_RUNS:
                    stage_script, content = STAGE_RUNS[args.journey][stage - 1]
                    stage_dir = save_dir / ("stage%d" % stage)
                    stage_dir.mkdir()
                    stage_extra = ["--artifact-dir=" + str(artifact_dir), "--save-dir=" + str(stage_dir), "--content=" + content, "--stage=%d" % stage]
                if args.inject_failure and stage == stages:
                    stage_extra.append("--inject-failure")
                stage_marker = marker if stage == stages else marker.replace("_OK", "_STAGE%d_OK" % stage)
                log = artifact_dir / ("journey-stage%d.log" % stage)
                try:
                    run([exe, *flags, "--path", str(ROOT), "--script", stage_script, "--", *stage_extra], stage_marker, log, timeout=timeout)
                finally:
                    if log.is_file():
                        logs.append(log.read_text())
                    (artifact_dir / "journey.log").write_text("".join(logs))
        if args.rendered and not all((artifact_dir / (name + ".png")).is_file() for name in captures):
            raise RuntimeError(f"Rendered {args.journey} missing required screenshots")
    elif args.command == "shell":
        run([exe, "--headless", "--path", str(ROOT), "--script", "res://tests/shell_smoke.gd"], "ROGUEWOOD_SHELL_OK", ROOT / "artifacts/e03/shell.log")
    elif args.command == "smoke":
        run([exe, "--headless", "--path", str(ROOT), "--", "--bootstrap-smoke"], "ROGUEWOOD_BOOT_OK")
    elif args.command == "export":
        target = ROOT / "build/linux/roguewood.x86_64"
        target.parent.mkdir(parents=True, exist_ok=True)
        run([exe, "--headless", "--path", str(ROOT), "--export-debug", "Linux", str(target)])
        run([str(target), "--headless", "--", "--bootstrap-smoke"], "ROGUEWOOD_BOOT_OK")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.SubprocessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
