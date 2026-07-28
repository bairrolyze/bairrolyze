"""
HomeScope — Home / Search journey.

Covers the primary search flow:
  open app → tap search field → type address → wait for suggestions
  → tap "Get Insights" → wait for analysis → view results
"""

import json
import os
import time

from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException

from appium.helpers.actions import (
    screenshot,
    tap_by_text,
    tap_by_accessibility_id,
    type_text,
    wait_for_text,
)

JOURNEY_NAME = "search-property"


def run(driver, screenshots_dir: str) -> list[dict]:
    """
    Execute the home/search journey and return a list of step metadata dicts.

    Each dict has the shape:
        {
            "step": int,
            "action": str,
            "screenshot": str,   # filename only, e.g. "open_app.png"
            "description": str,
        }

    A journey.json file is also written to screenshots_dir/<JOURNEY_NAME>/.
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
        print(f"[home_journey] Step {step_num} '{action}' recorded → {filename}")

    # ------------------------------------------------------------------
    # Step 1 — open_app: capture the home screen as the app launches
    # ------------------------------------------------------------------
    time.sleep(2)  # allow the app to settle after driver connection
    record(1, "open_app", "App launched; home screen (Search tab) is visible.")

    # ------------------------------------------------------------------
    # Step 2 — search_field: tap the search text field
    # ------------------------------------------------------------------
    tapped = False

    # Try accessibility ID first (Flutter may expose this)
    tapped = tap_by_accessibility_id(driver, "search_field", timeout=5)

    # Fall back to finding any TextField / SearchField
    if not tapped:
        try:
            field = WebDriverWait(driver, 8).until(
                EC.presence_of_element_located(
                    (AppiumBy.CLASS_NAME, "XCUIElementTypeTextField")
                )
            )
            field.click()
            tapped = True
        except TimeoutException:
            pass

    # Last resort: search bar / search field via predicate
    if not tapped:
        try:
            field = WebDriverWait(driver, 8).until(
                EC.presence_of_element_located(
                    (
                        AppiumBy.IOS_PREDICATE,
                        'type == "XCUIElementTypeTextField" OR type == "XCUIElementTypeSearchField"',
                    )
                )
            )
            field.click()
            tapped = True
        except TimeoutException:
            print("[home_journey] search_field: could not find text field — screenshotting anyway")

    time.sleep(0.5)
    record(2, "search_field", "Search field tapped; keyboard should be visible.")

    # ------------------------------------------------------------------
    # Step 3 — type_address: enter the neighbourhood name
    # ------------------------------------------------------------------
    address = "Bairro Alto, Lisbon"
    type_text(driver, address)
    time.sleep(1)
    record(3, "type_address", f"Typed address: '{address}'.")

    # ------------------------------------------------------------------
    # Step 4 — suggestions: wait for autocomplete suggestions to appear
    # ------------------------------------------------------------------
    # Suggestions typically appear as list cells or a StaticText containing
    # part of the typed text; we wait generically for any cell to appear.
    suggestions_visible = False
    try:
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located(
                (AppiumBy.CLASS_NAME, "XCUIElementTypeCell")
            )
        )
        suggestions_visible = True
    except TimeoutException:
        # Suggestions might render as plain text rows, not cells
        suggestions_visible = wait_for_text(driver, "Bairro Alto", timeout=8)

    time.sleep(0.5)
    record(
        4,
        "suggestions",
        "Autocomplete suggestions appeared." if suggestions_visible else "Suggestions may not have appeared (check screenshot).",
    )

    # ------------------------------------------------------------------
    # Step 5 — get_insights: tap the "Get Insights" button
    # ------------------------------------------------------------------
    tapped = tap_by_text(driver, "Get Insights", timeout=10)
    if not tapped:
        # Some builds label it differently
        tapped = tap_by_accessibility_id(driver, "get_insights_button", timeout=5)
    time.sleep(0.5)
    record(5, "get_insights", "'Get Insights' button tapped; analysis request sent.")

    # ------------------------------------------------------------------
    # Step 6 — loading: wait 3 s while the backend analyses the location
    # ------------------------------------------------------------------
    time.sleep(3)
    record(6, "loading", "Waiting for AI analysis to complete (3 s pause).")

    # ------------------------------------------------------------------
    # Step 7 — results_overview: wait for score / results to render
    # ------------------------------------------------------------------
    # Look for the word "Score" or any numeric score text
    found_results = wait_for_text(driver, "Score", timeout=20)
    if not found_results:
        # Broader fallback: wait for any number that looks like a percentage/score
        try:
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located(
                    (
                        AppiumBy.IOS_PREDICATE,
                        'value MATCHES "\\d+" OR label MATCHES "\\d+"',
                    )
                )
            )
            found_results = True
        except TimeoutException:
            print("[home_journey] results_overview: score not detected — screenshotting anyway")

    time.sleep(0.5)
    record(
        7,
        "results_overview",
        "Results / score overview visible." if found_results else "Results screen reached (score element not detected — check screenshot).",
    )

    # ------------------------------------------------------------------
    # Persist journey metadata
    # ------------------------------------------------------------------
    journey_json_path = os.path.join(out_dir, "journey.json")
    with open(journey_json_path, "w") as fh:
        json.dump({"journey": JOURNEY_NAME, "steps": steps}, fh, indent=2)
    print(f"[home_journey] Journey metadata saved → {journey_json_path}")

    return steps
