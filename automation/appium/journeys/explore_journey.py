"""
HomeScope — Explore journey.

Covers the Explore tab:
  tap Explore tab → view grid → scroll down → tap first neighbourhood card
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
)

JOURNEY_NAME = "explore"


def run(driver, screenshots_dir: str) -> list[dict]:
    """
    Execute the Explore journey and return a list of step metadata dicts.

    Each dict has the shape:
        {
            "step": int,
            "action": str,
            "screenshot": str,
            "description": str,
        }

    A journey.json is saved to screenshots_dir/explore/.
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
        print(f"[explore_journey] Step {step_num} '{action}' recorded → {filename}")

    # ------------------------------------------------------------------
    # Step 1 — explore_tab: tap the Explore tab (index 2)
    # ------------------------------------------------------------------
    tap_tab(driver, 2)
    time.sleep(1.5)  # allow tab transition animation to complete
    record(1, "explore_tab", "Explore tab (index 2) tapped; Explore screen is visible.")

    # ------------------------------------------------------------------
    # Step 2 — explore_grid: screenshot the neighbourhood grid/list
    # ------------------------------------------------------------------
    time.sleep(1)
    record(2, "explore_grid", "Explore grid/list of neighbourhoods is rendered.")

    # ------------------------------------------------------------------
    # Step 3 — explore_scrolled: scroll down to reveal more cards
    # ------------------------------------------------------------------
    scroll_down(driver, distance=300)
    time.sleep(0.8)
    record(3, "explore_scrolled", "Scrolled down; additional neighbourhood cards visible.")

    # ------------------------------------------------------------------
    # Step 4 — neighborhood_detail: tap the first visible cell/card
    # ------------------------------------------------------------------
    tapped_card = False

    # Strategy 1: XCUIElementTypeCell (UIKit table/collection view cells,
    #             also exposed by Flutter's list semantics)
    try:
        cells = WebDriverWait(driver, 8).until(
            EC.presence_of_all_elements_located(
                (AppiumBy.CLASS_NAME, "XCUIElementTypeCell")
            )
        )
        if cells:
            cells[0].click()
            tapped_card = True
            print("[explore_journey] neighborhood_detail: tapped first XCUIElementTypeCell")
    except (TimeoutException, WebDriverException) as exc:
        print(f"[explore_journey] neighborhood_detail: XCUIElementTypeCell not found — {exc}")

    # Strategy 2: any tappable / button element
    if not tapped_card:
        try:
            buttons = WebDriverWait(driver, 8).until(
                EC.presence_of_all_elements_located(
                    (AppiumBy.CLASS_NAME, "XCUIElementTypeButton")
                )
            )
            # Filter to visible, non-nav buttons (rough heuristic: y > 100)
            candidates = [b for b in buttons if b.location.get("y", 0) > 100]
            if candidates:
                candidates[0].click()
                tapped_card = True
                print("[explore_journey] neighborhood_detail: tapped first XCUIElementTypeButton")
        except (TimeoutException, WebDriverException) as exc:
            print(f"[explore_journey] neighborhood_detail: XCUIElementTypeButton not found — {exc}")

    # Strategy 3: any element with type "Other" (Flutter custom widgets)
    if not tapped_card:
        try:
            others = driver.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeOther")
            # Take the first element that is below the tab bar and nav bar
            candidates = [
                e for e in others
                if e.location.get("y", 0) > 150 and e.size.get("height", 0) > 60
            ]
            if candidates:
                candidates[0].click()
                tapped_card = True
                print("[explore_journey] neighborhood_detail: tapped first XCUIElementTypeOther card")
        except WebDriverException as exc:
            print(f"[explore_journey] neighborhood_detail: fallback tap failed — {exc}")

    time.sleep(1.5)
    record(
        4,
        "neighborhood_detail",
        "First neighbourhood card tapped; detail view is visible." if tapped_card
        else "Could not tap a card automatically (check screenshot).",
    )

    # ------------------------------------------------------------------
    # Persist journey metadata
    # ------------------------------------------------------------------
    journey_json_path = os.path.join(out_dir, "journey.json")
    with open(journey_json_path, "w") as fh:
        json.dump({"journey": JOURNEY_NAME, "steps": steps}, fh, indent=2)
    print(f"[explore_journey] Journey metadata saved → {journey_json_path}")

    return steps
