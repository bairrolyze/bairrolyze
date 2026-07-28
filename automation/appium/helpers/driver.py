"""
Appium driver factory for HomeScope iOS automation.
Reads server and capability config from appium/config.json.
"""

import json
import os

from appium import webdriver
from appium.options import AppiumOptions


_CONFIG_PATH = os.path.join(os.path.dirname(__file__), "..", "config.json")


def get_driver() -> webdriver.Remote:
    """
    Load config.json, build AppiumOptions, and connect to the Appium server.

    Returns:
        An initialised Appium WebDriver session.

    Raises:
        FileNotFoundError: If config.json cannot be found.
        ConnectionError: If the Appium server cannot be reached or session creation fails.
    """
    config_path = os.path.abspath(_CONFIG_PATH)
    if not os.path.exists(config_path):
        raise FileNotFoundError(
            f"Appium config not found at: {config_path}. "
            "Make sure config.json exists under automation/appium/."
        )

    with open(config_path, "r") as fh:
        config = json.load(fh)

    server_cfg = config["server"]
    server_url = f"http://{server_cfg['host']}:{server_cfg['port']}"

    options = AppiumOptions()
    for key, value in config["capabilities"].items():
        options.set_capability(key, value)

    print(f"[driver] Connecting to Appium server at {server_url} ...")
    try:
        driver = webdriver.Remote(server_url, options=options)
    except Exception as exc:
        raise ConnectionError(
            f"Failed to connect to Appium server at {server_url}.\n"
            f"  Make sure `appium server --port 4723` is running and the XCUITest driver is installed.\n"
            f"  Original error: {exc}"
        ) from exc

    print(f"[driver] Session started — session ID: {driver.session_id}")
    return driver
