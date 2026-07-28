#!/usr/bin/env python3
"""
HomeScope Appium journey runner.

Usage (from automation/):
    python appium/run_journeys.py                    # run all journeys
    python appium/run_journeys.py --journey home
    python appium/run_journeys.py --journey explore
    python appium/run_journeys.py --journey settings
    python appium/run_journeys.py --journey all

Screenshots are saved under:
    automation/screenshots/<journey-name>/

Prerequisites:
    1. pip install -r requirements.txt
    2. npm install  (inside automation/)
    3. npm run install-drivers
    4. npm run appium          (in a separate terminal)
    5. The HomeScope app must already be installed on the target simulator.
"""

import argparse
import os
import sys
import traceback

# Make sure imports from appium/ package work when running from automation/
_HERE = os.path.dirname(os.path.abspath(__file__))
_AUTOMATION_ROOT = os.path.dirname(_HERE)
if _AUTOMATION_ROOT not in sys.path:
    sys.path.insert(0, _AUTOMATION_ROOT)

from appium.helpers.driver import get_driver
from appium.journeys import home_journey, explore_journey, settings_journey

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SCREENSHOTS_BASE = os.path.join(_AUTOMATION_ROOT, "screenshots")

JOURNEY_MAP = {
    "home": home_journey,
    "explore": explore_journey,
    "settings": settings_journey,
}


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Appium journeys for the HomeScope iOS app.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--journey",
        choices=["all", "home", "explore", "settings"],
        default="all",
        help="Which journey to run (default: all)",
    )
    return parser.parse_args()


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

def run_journey(name: str, module, driver, screenshots_dir: str) -> list[dict]:
    """Run a single journey module and return its step list."""
    print(f"\n{'='*60}")
    print(f"  Starting journey: {name.upper()}")
    print(f"{'='*60}")
    try:
        steps = module.run(driver, screenshots_dir)
        print(f"\n[runner] Journey '{name}' completed — {len(steps)} step(s) recorded.")
        return steps
    except Exception:
        print(f"\n[runner] Journey '{name}' FAILED with an unhandled exception:")
        traceback.print_exc()
        return []


def print_summary(results: dict[str, list[dict]]) -> None:
    """Pretty-print a summary table of all journeys and their steps."""
    print(f"\n{'='*60}")
    print("  JOURNEY SUMMARY")
    print(f"{'='*60}")
    total_steps = 0
    for journey_name, steps in results.items():
        print(f"\n  Journey: {journey_name}")
        if not steps:
            print("    (no steps recorded — journey may have failed)")
            continue
        for s in steps:
            screenshot_path = os.path.join(
                SCREENSHOTS_BASE, journey_name, s["screenshot"]
            )
            status = "OK" if os.path.exists(screenshot_path) else "MISSING"
            print(
                f"    [{status}] Step {s['step']:>2}  {s['action']:<25}  "
                f"{s['description'][:55]}"
            )
            print(f"            -> {screenshot_path}")
        total_steps += len(steps)
    print(f"\n  Total steps recorded: {total_steps}")
    print(f"  Screenshots root:     {SCREENSHOTS_BASE}")
    print(f"{'='*60}\n")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_args()

    # Select which journeys to run
    if args.journey == "all":
        selected = list(JOURNEY_MAP.items())
    else:
        selected = [(args.journey, JOURNEY_MAP[args.journey])]

    # Create output directories up front
    for name, _ in selected:
        os.makedirs(os.path.join(SCREENSHOTS_BASE, name), exist_ok=True)

    # Start the Appium driver (raises ConnectionError if server is not running)
    print("[runner] Initialising Appium driver …")
    try:
        driver = get_driver()
    except (FileNotFoundError, ConnectionError) as exc:
        print(f"\n[runner] ERROR: {exc}")
        sys.exit(1)

    results: dict[str, list[dict]] = {}

    try:
        for name, module in selected:
            results[name] = run_journey(name, module, driver, SCREENSHOTS_BASE)
    finally:
        print("\n[runner] Closing Appium session …")
        try:
            driver.quit()
            print("[runner] Driver closed.")
        except Exception as exc:
            print(f"[runner] Warning: error while closing driver — {exc}")

    print_summary(results)


if __name__ == "__main__":
    main()
