"""
HomeScope Vision Analyzer
-------------------------
Uses Claude claude-sonnet-4-6 to analyze Flutter app screenshots and generate
structured UX analysis for tutorial generation.
"""

import base64
import json
import os
from pathlib import Path

import anthropic


def analyze_screenshot(image_path: str, step_metadata: dict) -> dict:
    """
    Analyze a single screenshot using Claude Vision.

    Args:
        image_path: Absolute or relative path to the screenshot file.
        step_metadata: Dict with keys like step, action, description from
                       the Appium journey runner.

    Returns:
        A dict with keys: screen_name, purpose, visible_components,
        user_action, tutorial_text, ux_notes.
        On parse failure, returns a fallback dict with raw_text included.
    """
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    image_path = Path(image_path)
    if not image_path.exists():
        return _fallback(f"Image not found: {image_path}", step_metadata)

    with open(image_path, "rb") as f:
        image_data = base64.standard_b64encode(f.read()).decode("utf-8")

    # Infer media type from extension
    suffix = image_path.suffix.lower()
    media_type_map = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
        ".gif": "image/gif",
    }
    media_type = media_type_map.get(suffix, "image/png")

    system_prompt = (
        "You are a mobile UX analyst. Analyze this Flutter app screenshot "
        "and return ONLY valid JSON."
    )

    user_prompt = (
        "Analyze this HomeScope Flutter app screenshot and return ONLY a "
        "valid JSON object (no markdown, no code fences) with exactly these keys:\n\n"
        '{\n'
        '  "screen_name": "Short name for this screen (e.g. Home Screen)",\n'
        '  "purpose": "One sentence describing what this screen does for the user",\n'
        '  "visible_components": ["List", "of", "visible", "UI", "elements"],\n'
        '  "user_action": "What the user is doing or should do on this screen",\n'
        '  "tutorial_text": "2-3 sentence human-friendly tutorial instruction for this step",\n'
        '  "ux_notes": ["Any UX observations or accessibility notes"]\n'
        '}\n\n'
        f"Step context: action={step_metadata.get('action', 'unknown')}, "
        f"description={step_metadata.get('description', '')}"
    )

    try:
        response = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            system=system_prompt,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": image_data,
                            },
                        },
                        {
                            "type": "text",
                            "text": user_prompt,
                        },
                    ],
                }
            ],
        )

        raw_text = ""
        for block in response.content:
            if block.type == "text":
                raw_text = block.text.strip()
                break

        # Strip markdown code fences if Claude added them despite instructions
        if raw_text.startswith("```"):
            lines = raw_text.splitlines()
            # Remove opening fence (```json or ```)
            lines = lines[1:] if lines[0].startswith("```") else lines
            # Remove closing fence
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            raw_text = "\n".join(lines).strip()

        return json.loads(raw_text)

    except json.JSONDecodeError as exc:
        print(f"[analyzer] JSON parse error for {image_path}: {exc}")
        return _fallback(raw_text if "raw_text" in dir() else str(exc), step_metadata)
    except anthropic.APIError as exc:
        print(f"[analyzer] Anthropic API error for {image_path}: {exc}")
        return _fallback(str(exc), step_metadata)


def _fallback(raw_text: str, step_metadata: dict) -> dict:
    """Return a safe fallback dict when analysis fails."""
    return {
        "screen_name": step_metadata.get("action", "Unknown Screen").replace("_", " ").title(),
        "purpose": step_metadata.get("description", ""),
        "visible_components": [],
        "user_action": step_metadata.get("action", ""),
        "tutorial_text": step_metadata.get("description", ""),
        "ux_notes": ["Vision analysis unavailable"],
        "_raw_text": raw_text,
        "_error": True,
    }


def analyze_journey(journey_dir: str) -> list[dict]:
    """
    Analyze all steps in a recorded Appium journey.

    Args:
        journey_dir: Path to the directory containing journey.json and
                     the screenshot files referenced within it.

    Returns:
        List of merged dicts (step metadata + vision analysis).
        Also writes the list to journey_dir/analysis.json.
    """
    journey_dir = Path(journey_dir)
    journey_file = journey_dir / "journey.json"

    if not journey_file.exists():
        raise FileNotFoundError(f"journey.json not found in {journey_dir}")

    with open(journey_file) as f:
        steps: list[dict] = json.load(f)

    results: list[dict] = []

    for step in steps:
        screenshot_filename = step.get("screenshot", "")
        screenshot_path = journey_dir / screenshot_filename

        print(
            f"[analyzer] Analyzing step {step.get('step')} "
            f"'{step.get('action')}' → {screenshot_filename}"
        )

        vision = analyze_screenshot(str(screenshot_path), step)

        merged = {**step, **vision}
        results.append(merged)

    output_path = journey_dir / "analysis.json"
    with open(output_path, "w") as f:
        json.dump(results, f, indent=2)

    print(f"[analyzer] Analysis saved → {output_path}")
    return results
