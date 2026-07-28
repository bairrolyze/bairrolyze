"""
Reusable Appium helper actions for HomeScope iOS automation.

All functions take `driver` as their first argument and log errors clearly
rather than swallowing them silently.
"""

import os
import time

from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.common.exceptions import TimeoutException, WebDriverException


# ---------------------------------------------------------------------------
# Element interaction helpers
# ---------------------------------------------------------------------------

def tap_by_text(driver, text: str, timeout: int = 10) -> bool:
    """
    Find an element whose label or value matches `text` (case-sensitive) and tap it.

    Uses XCUITest's -ios predicate string for reliable text matching on Flutter/iOS.

    Returns True on success, False if the element was not found within `timeout`.
    """
    predicate = f'label == "{text}" OR value == "{text}" OR name == "{text}"'
    try:
        element = WebDriverWait(driver, timeout).until(
            EC.presence_of_element_located((AppiumBy.IOS_PREDICATE, predicate))
        )
        element.click()
        print(f"[actions] tap_by_text: tapped '{text}'")
        return True
    except TimeoutException:
        print(f"[actions] tap_by_text: element with text '{text}' not found within {timeout}s")
        return False
    except WebDriverException as exc:
        print(f"[actions] tap_by_text: error tapping '{text}': {exc}")
        return False


def tap_by_accessibility_id(driver, aid: str, timeout: int = 10) -> bool:
    """
    Find an element by its accessibility identifier and tap it.

    Returns True on success, False if not found within `timeout`.
    """
    try:
        element = WebDriverWait(driver, timeout).until(
            EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, aid))
        )
        element.click()
        print(f"[actions] tap_by_accessibility_id: tapped accessibility id '{aid}'")
        return True
    except TimeoutException:
        print(f"[actions] tap_by_accessibility_id: element '{aid}' not found within {timeout}s")
        return False
    except WebDriverException as exc:
        print(f"[actions] tap_by_accessibility_id: error tapping '{aid}': {exc}")
        return False


def type_text(driver, text: str) -> None:
    """
    Send `text` to the currently focused element.
    Assumes focus is already on a text field.
    """
    try:
        active = driver.switch_to.active_element
        active.send_keys(text)
        print(f"[actions] type_text: typed '{text}'")
    except WebDriverException as exc:
        print(f"[actions] type_text: error typing text: {exc}")


def clear_and_type(driver, element, text: str) -> None:
    """
    Clear the content of `element` and type `text` into it.
    """
    try:
        element.clear()
        element.send_keys(text)
        print(f"[actions] clear_and_type: cleared and typed '{text}'")
    except WebDriverException as exc:
        print(f"[actions] clear_and_type: error: {exc}")


# ---------------------------------------------------------------------------
# Gesture helpers
# ---------------------------------------------------------------------------

def scroll_down(driver, distance: int = 300) -> None:
    """
    Scroll down by swiping upward on the screen centre.

    `distance` is in logical pixels; adjust for screen size if needed.
    """
    try:
        size = driver.get_window_size()
        width = size["width"]
        height = size["height"]
        start_x = width // 2
        start_y = int(height * 0.65)
        end_y = max(0, start_y - distance)

        driver.swipe(start_x, start_y, start_x, end_y, duration=600)
        print(f"[actions] scroll_down: swiped up {distance}px")
    except WebDriverException as exc:
        print(f"[actions] scroll_down: error: {exc}")


def swipe_left(driver) -> None:
    """
    Swipe left across the screen centre (advances carousels / tutorial pages).
    """
    try:
        size = driver.get_window_size()
        width = size["width"]
        height = size["height"]
        start_x = int(width * 0.80)
        end_x = int(width * 0.20)
        y = height // 2

        driver.swipe(start_x, y, end_x, y, duration=500)
        print("[actions] swipe_left: done")
    except WebDriverException as exc:
        print(f"[actions] swipe_left: error: {exc}")


# ---------------------------------------------------------------------------
# Wait helpers
# ---------------------------------------------------------------------------

def wait_for_text(driver, text: str, timeout: int = 15) -> bool:
    """
    Wait until an element with the given text label/value is visible.

    Returns True if found, False on timeout.
    """
    predicate = f'label == "{text}" OR value == "{text}" OR name == "{text}"'
    try:
        WebDriverWait(driver, timeout).until(
            EC.visibility_of_element_located((AppiumBy.IOS_PREDICATE, predicate))
        )
        print(f"[actions] wait_for_text: '{text}' is now visible")
        return True
    except TimeoutException:
        print(f"[actions] wait_for_text: '{text}' did not appear within {timeout}s")
        return False
    except WebDriverException as exc:
        print(f"[actions] wait_for_text: error waiting for '{text}': {exc}")
        return False


# ---------------------------------------------------------------------------
# Navigation helpers
# ---------------------------------------------------------------------------

def tap_tab(driver, index: int) -> None:
    """
    Tap a bottom navigation tab by index (0 = leftmost).

    Uses coordinate-based tapping because Flutter renders the tab bar as a
    single canvas element that XCUITest cannot decompose into child elements.

    Tab layout (4 tabs, iPhone screen ~393 pt wide):
      index 0 → x ~49   (Search)
      index 1 → x ~131  (Discover)
      index 2 → x ~213  (Explore)
      index 3 → x ~295  (You / Settings)
    The tab bar sits ~34 pt above the home-indicator; its centre is ~83 pt from bottom.
    """
    try:
        size = driver.get_window_size()
        width = size["width"]
        height = size["height"]

        num_tabs = 4
        section_width = width / num_tabs
        tap_x = int(section_width * index + section_width / 2)
        # Tab bar centre: ~83 pt from bottom (accounts for safe-area / home indicator)
        tap_y = int(height - 83)

        driver.tap([(tap_x, tap_y)])
        print(f"[actions] tap_tab: tapped tab index {index} at ({tap_x}, {tap_y})")
    except WebDriverException as exc:
        print(f"[actions] tap_tab: error tapping tab {index}: {exc}")


# ---------------------------------------------------------------------------
# Screenshot helper
# ---------------------------------------------------------------------------

def screenshot(driver, name: str, folder: str) -> str:
    """
    Capture a PNG screenshot and save it to `folder/name.png`.

    Creates `folder` if it does not exist.

    Returns the absolute path of the saved file.
    """
    try:
        os.makedirs(folder, exist_ok=True)
        filename = f"{name}.png"
        filepath = os.path.join(folder, filename)
        driver.save_screenshot(filepath)
        print(f"[actions] screenshot: saved '{filepath}'")
        return filepath
    except WebDriverException as exc:
        print(f"[actions] screenshot: WebDriver error for '{name}': {exc}")
        return ""
    except OSError as exc:
        print(f"[actions] screenshot: filesystem error for '{name}': {exc}")
        return ""
