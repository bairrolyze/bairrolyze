#!/usr/bin/env python3
"""
HomeScope Tutorial Generator
Runs Appium journeys → Vision AI analysis → Markdown tutorials

Usage:
  python generate_tutorials.py                    # full pipeline
  python generate_tutorials.py --skip-capture     # skip Appium, re-analyze existing screenshots
  python generate_tutorials.py --skip-vision      # skip AI, regenerate docs from cached analysis
  python generate_tutorials.py --journey home     # run only one journey
  python generate_tutorials.py --export html      # also export HTML
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).parent
AUTOMATION_DIR = ROOT / "automation"
SCREENSHOTS_DIR = AUTOMATION_DIR / "screenshots"
DOCS_DIR = ROOT / "docs" / "tutorials"
HTML_DIR = ROOT / "docs" / "html"

sys.path.insert(0, str(AUTOMATION_DIR))


# ── Colour helpers ─────────────────────────────────────────────────────────────

def _green(s):  return f"\033[92m{s}\033[0m"
def _blue(s):   return f"\033[94m{s}\033[0m"
def _yellow(s): return f"\033[93m{s}\033[0m"
def _red(s):    return f"\033[91m{s}\033[0m"
def _bold(s):   return f"\033[1m{s}\033[0m"

def _header(msg):
    print(f"\n{_bold(_blue('═' * 60))}")
    print(f"  {_bold(msg)}")
    print(f"{_bold(_blue('═' * 60))}\n")

def _step(n, total, msg):
    print(f"  {_blue(f'[{n}/{total}]')} {msg}")

def _ok(msg):   print(f"  {_green('✓')} {msg}")
def _warn(msg): print(f"  {_yellow('⚠')} {msg}")
def _err(msg):  print(f"  {_red('✗')} {msg}")


# ── Pre-flight checks ──────────────────────────────────────────────────────────

def check_appium_server():
    """Return True if Appium server is reachable on port 4723."""
    import urllib.request
    try:
        urllib.request.urlopen("http://127.0.0.1:4723/status", timeout=3)
        return True
    except Exception:
        return False


def ensure_appium_running():
    """Start Appium server if not already running."""
    if check_appium_server():
        _ok("Appium server already running")
        return None

    _step("", "", "Starting Appium server…")
    node_modules = AUTOMATION_DIR / "node_modules" / ".bin" / "appium"
    if not node_modules.exists():
        _warn("Appium not installed. Run: cd automation && npm install")
        _warn("Then: npm run install-drivers")
        return None

    proc = subprocess.Popen(
        [str(node_modules), "server", "--port", "4723", "--log-level", "error"],
        cwd=str(AUTOMATION_DIR),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    # Wait up to 10s for server to be ready
    for _ in range(20):
        time.sleep(0.5)
        if check_appium_server():
            _ok("Appium server started")
            return proc
    _warn("Appium server didn't start — continuing anyway")
    return proc


def check_env():
    key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not key:
        _warn("ANTHROPIC_API_KEY not set — Vision AI step will be skipped")
        return False
    return True


# ── Phase 1 + 2: Capture screenshots via Appium ───────────────────────────────

def run_capture(journey_filter):
    _header("Phase 1+2 — Appium Journey Capture")

    SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)
    (AUTOMATION_DIR / "logs").mkdir(exist_ok=True)

    try:
        from appium.appium.helpers.driver import get_driver
        from appium.appium import journeys
    except ImportError:
        # Path adjustment for running from repo root
        sys.path.insert(0, str(AUTOMATION_DIR / "appium"))
        try:
            from helpers.driver import get_driver
        except ImportError as e:
            _err(f"Cannot import Appium helpers: {e}")
            _warn("Make sure Appium Python client is installed: pip install -r automation/requirements.txt")
            return False

    sys.path.insert(0, str(AUTOMATION_DIR / "appium"))
    from helpers.driver import get_driver
    from journeys import home_journey, explore_journey, settings_journey

    journey_map = {
        "home":     (home_journey,     "search-property"),
        "explore":  (explore_journey,  "explore"),
        "settings": (settings_journey, "settings"),
    }

    if journey_filter != "all" and journey_filter not in journey_map:
        _err(f"Unknown journey '{journey_filter}'. Choose: all, home, explore, settings")
        return False

    to_run = journey_map if journey_filter == "all" else {journey_filter: journey_map[journey_filter]}

    driver = None
    try:
        _step("", "", "Connecting to simulator via Appium…")
        driver = get_driver()
        _ok("Connected to HomeScope on iPhone 17 Pro simulator")

        for key, (module, folder) in to_run.items():
            out_dir = SCREENSHOTS_DIR / folder
            out_dir.mkdir(parents=True, exist_ok=True)
            _step("", "", f"Running '{key}' journey → {out_dir.relative_to(ROOT)}")
            try:
                steps = module.run(driver, str(SCREENSHOTS_DIR))
                _ok(f"  {len(steps)} steps captured")
                for s in steps:
                    print(f"    {_green('→')} step {s['step']:02d}: {s['action']} — {s.get('screenshot', '')}")
            except Exception as e:
                _err(f"  Journey '{key}' failed: {e}")

        return True

    except Exception as e:
        _err(f"Driver connection failed: {e}")
        _warn("Is the Appium server running? Is the app installed on the simulator?")
        _warn("Start server: cd automation && npm run appium")
        return False

    finally:
        if driver:
            try:
                driver.quit()
            except Exception:
                pass


# ── Phase 3: Vision AI analysis ───────────────────────────────────────────────

def run_vision_analysis(journey_filter):
    _header("Phase 3 — Vision AI Screen Analysis")

    if not check_env():
        _warn("Skipping Vision AI — no API key")
        return False

    sys.path.insert(0, str(AUTOMATION_DIR))
    try:
        from vision.analyzer import analyze_journey
    except ImportError as e:
        _err(f"Cannot import vision analyzer: {e}")
        return False

    journey_dirs = []
    if journey_filter == "all":
        journey_dirs = [d for d in SCREENSHOTS_DIR.iterdir() if d.is_dir() and (d / "journey.json").exists()]
    else:
        folder_map = {"home": "search-property", "explore": "explore", "settings": "settings"}
        d = SCREENSHOTS_DIR / folder_map.get(journey_filter, journey_filter)
        if d.exists():
            journey_dirs = [d]

    if not journey_dirs:
        _warn("No journey.json files found — run capture phase first")
        return False

    for journey_dir in journey_dirs:
        _step("", "", f"Analyzing {journey_dir.name}…")
        try:
            analysis = analyze_journey(str(journey_dir))
            _ok(f"  {len(analysis)} screenshots analyzed → analysis.json")
        except Exception as e:
            _err(f"  Analysis failed for {journey_dir.name}: {e}")

    return True


# ── Phase 4: Generate tutorials ───────────────────────────────────────────────

def run_generate(journey_filter):
    _header("Phase 4 — Generate Markdown Tutorials")

    DOCS_DIR.mkdir(parents=True, exist_ok=True)

    sys.path.insert(0, str(AUTOMATION_DIR))
    try:
        from docs.generator import generate_tutorial, generate_index
    except ImportError as e:
        _err(f"Cannot import doc generator: {e}")
        return []

    folder_map = {
        "home":     "search-property",
        "explore":  "explore",
        "settings": "settings",
    }

    if journey_filter == "all":
        dirs = [d for d in SCREENSHOTS_DIR.iterdir() if d.is_dir()]
    else:
        dirs = [SCREENSHOTS_DIR / folder_map.get(journey_filter, journey_filter)]

    generated = []
    for journey_dir in dirs:
        if not journey_dir.exists():
            continue
        analysis_file = journey_dir / "analysis.json"
        journey_file  = journey_dir / "journey.json"

        if analysis_file.exists():
            with open(analysis_file) as f:
                analysis = json.load(f)
        elif journey_file.exists():
            _warn(f"  No analysis.json for {journey_dir.name} — using journey metadata only")
            with open(journey_file) as f:
                analysis = json.load(f).get("steps", [])
        else:
            _warn(f"  Skipping {journey_dir.name} — no data found")
            continue

        try:
            path = generate_tutorial(
                journey_name=journey_dir.name,
                analysis=analysis,
                screenshots_dir=str(SCREENSHOTS_DIR),
                output_dir=str(DOCS_DIR),
            )
            generated.append(path)
            _ok(f"  Generated: docs/tutorials/{Path(path).name}")
        except Exception as e:
            _err(f"  Generation failed for {journey_dir.name}: {e}")

    if generated and journey_filter == "all":
        try:
            generate_index(generated, str(ROOT / "docs"))
            _ok("  Updated docs/README.md index")
        except Exception as e:
            _warn(f"  Index update failed: {e}")

    return generated


# ── Phase 5: Export ───────────────────────────────────────────────────────────

def run_export(export_format):
    _header(f"Phase 5 — Export ({export_format.upper()})")

    sys.path.insert(0, str(AUTOMATION_DIR))
    try:
        from docs.exporter import export_all, to_mintlify_structure
    except ImportError as e:
        _err(f"Cannot import exporter: {e}")
        return

    if export_format in ("html", "all"):
        HTML_DIR.mkdir(parents=True, exist_ok=True)
        try:
            paths = export_all(str(DOCS_DIR), str(HTML_DIR))
            for p in paths:
                _ok(f"  HTML: {Path(p).relative_to(ROOT)}")
        except Exception as e:
            _err(f"  HTML export failed: {e}")

    if export_format in ("mintlify", "all"):
        try:
            mint = to_mintlify_structure(str(ROOT / "docs"), str(ROOT / "docs" / "mintlify"))
            _ok(f"  Mintlify: {Path(mint).relative_to(ROOT)}")
        except Exception as e:
            _err(f"  Mintlify export failed: {e}")


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="HomeScope Tutorial Generator")
    parser.add_argument("--journey", default="all",
                        choices=["all", "home", "explore", "settings"],
                        help="Which journey to run (default: all)")
    parser.add_argument("--skip-capture", action="store_true",
                        help="Skip Appium capture, use existing screenshots")
    parser.add_argument("--skip-vision",  action="store_true",
                        help="Skip Vision AI, regenerate docs from cached analysis")
    parser.add_argument("--export", default="none",
                        choices=["none", "html", "mintlify", "all"],
                        help="Export format (default: none)")
    args = parser.parse_args()

    print(_bold("\n🏠  HomeScope Tutorial Generator"))
    print(f"   Journey: {args.journey}  |  Export: {args.export}\n")

    appium_proc = None

    # Phase 1+2 — Capture
    if not args.skip_capture:
        appium_proc = ensure_appium_running()
        success = run_capture(args.journey)
        if not success:
            _warn("Capture failed or skipped — continuing with existing screenshots")
    else:
        _warn("Skipping capture (--skip-capture)")

    # Phase 3 — Vision AI
    if not args.skip_vision:
        run_vision_analysis(args.journey)
    else:
        _warn("Skipping Vision AI (--skip-vision)")

    # Phase 4 — Generate
    generated = run_generate(args.journey)

    # Phase 5 — Export
    if args.export != "none":
        run_export(args.export)

    # Summary
    _header("Done")
    if generated:
        print(f"  {_green(str(len(generated)))} tutorial(s) written to docs/tutorials/\n")
        for p in generated:
            print(f"    {_green('→')} {Path(p).relative_to(ROOT)}")
    else:
        _warn("No tutorials generated. Run capture phase and ensure screenshots exist.")

    print(f"\n  {_blue('Next steps:')}")
    print(f"    • Set ANTHROPIC_API_KEY to enable Vision AI analysis")
    print(f"    • Run with --export html to generate HTML docs")
    print(f"    • Run with --skip-capture to regenerate docs without re-running journeys")
    print()

    if appium_proc:
        appium_proc.terminate()


if __name__ == "__main__":
    main()
