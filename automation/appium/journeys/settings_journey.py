"""
HomeScope — Settings / You journey.

Covers the You tab:
  tap You tab → scroll to help section → tap "How to use HomeScope"
  → swipe through tutorial pages
"""

import json
import os
import time

from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException, WebDriverException

from appium.helpers.actions import (
    screenshot,
    tap_tab,
    scroll_down,
    swipe_left,
    tap_by_text,
    wait_for_text,
)

JOURNEY_NAME = "settings"


def run(driver, screenshots_dir: str) -> list[dict]:
    """
    Execute the Settings/You journey and return a list of step metadata dicts.

    Each dict has the shape:
        {
            "step": int,
            "action": str,
            "screenshot": str,
            "description": str,
        }

    A journey.json is saved to screenshots_dir/settings/.
    """
    out_dir = os.path.join(screenshots_dir, JOURNEY_NAME)
    os.makedirs(out_dir, exist_ok=True)

    steps: list[dict] = []

    def record(step_num: int, action: str, description: str) -> None:
        path = screenshot(driver, action, out_dir)
        filename = os.path.basename(path) if path else f"{action}.png"
        steps.append(
            {
                "step": step_num,
                "action": action,
                "screenshot": filename,
                "description": description,
            }
        )
        print(f"[settings_journey] Step {step_num} '{action}' recorded → {filename}")

    # ------------------------------------------------------------------
    # Step 1 — settings_home: tap the You/Settings tab (index 3)
    # ------------------------------------------------------------------
    tap_tab(driver, 3)
    time.sleep(1.5)
    record(1, "settings_home", "You/Settings tab (index 3) tapped; settings screen visible.")

    # ------------------------------------------------------------------
    # Step 2 — help_section: scroll down to find "How to use HomeScope"
    # ------------------------------------------------------------------
    help_label = "How to use HomeScope"
    found_help = False

    # Try scrolling up to 4 times to find the element
    for attempt in range(4):
        if wait_for_text(driver, help_label, timeout=4):
            found_help = True
            break
        scroll_down(driver, distance=250)
        time.sleep(0.5)

    time.sleep(0.5)
    record(
        2,
        "help_section",
        f"'{help_label}' section found after scrolling." if found_help
        else f"'{help_label}' not found after scrolling (check screenshot).",
    )

    # ------------------------------------------------------------------
    # Step 3 — tutorial_opened: tap "How to use HomeScope"
    # ------------------------------------------------------------------
    tapped = tap_by_text(driver, help_label, timeout=8)

    # Some builds may use an accessibility ID instead
    if not tapped:
        try:
            el = WebDriverWait(driver, 6).until(
                EC.presence_of_element_located(
                    (
                        AppiumBy.IOS_PREDICATE,
                        f'label CONTAINS "How to use" OR label CONTAINS "Tutorial"',
                    )
                )
            )
            el.click()
            tapped = True
        except (TimeoutException, WebDriverException) as exc:
            print(f"[settings_journey] tutorial_opened: fallback tap failed — {exc}")

    time.sleep(1.5)
    record(
        3,
        "tutorial_opened",
        "Tutorial / 'How to use HomeScope' screen opened." if tapped
        else "Could not open tutorial (check screenshot).",
    )

    # ------------------------------------------------------------------
    # Step 4 — tutorial_page2: swipe left to advance to page 2
    # ------------------------------------------------------------------
    swipe_left(driver)
    time.sleep(1)
    record(4, "tutorial_page2", "Swiped left; tutorial page 2 is visible.")

    # ------------------------------------------------------------------
    # Step 5 — tutorial_page3: swipe left again to advance to page 3
    # ------------------------------------------------------------------
    swipe_left(driver)
    time.sleep(1)
    record(5, "tutorial_page3", "Swiped left again; tutorial page 3 is visible.")

    # ------------------------------------------------------------------
    # Persist journey metadata
    # ------------------------------------------------------------------
    journey_json_path = os.path.join(out_dir, "journey.json")
    with open(journey_json_path, "w") as fh:
        json.dump({"journey": JOURNEY_NAME, "steps": steps}, fh, indent=2)
    print(f"[settings_journey] Journey metadata saved → {journey_json_path}")

    return steps
