"""
HomeScope Tutorial Generator
-----------------------------
Converts vision analysis output into human-readable Markdown tutorials.
"""

import json
import os
import re
from pathlib import Path


def _journey_name_to_title(journey_name: str) -> str:
    """Convert kebab-case journey name to Title Case.

    Examples:
        "search-property"         -> "Search a Property"
        "explore-neighbourhoods"  -> "Explore Neighbourhoods"
        "settings-tour"           -> "Settings Tour"
    """
    words = journey_name.replace("-", " ").split()
    return " ".join(w.capitalize() for w in words)


def _step_intro(journey_name: str) -> str:
    """Return a one-line introductory quote for the tutorial."""
    intros = {
        "search-property": (
            "Learn how to search for any address and get neighbourhood insights in HomeScope."
        ),
        "explore-neighbourhoods": (
            "Browse curated neighbourhoods and discover areas that match your lifestyle."
        ),
        "settings-tour": (
            "Customise HomeScope to suit your preferences and unlock AI-powered features."
        ),
    }
    return intros.get(
        journey_name,
        f"A step-by-step walkthrough of {_journey_name_to_title(journey_name)} in HomeScope.",
    )


def generate_tutorial(
    journey_name: str,
    analysis: list[dict],
    screenshots_dir: str,
    output_dir: str,
) -> str:
    """
    Generate a Markdown tutorial from vision analysis steps.

    Args:
        journey_name: Kebab-case journey identifier, e.g. "search-property".
        analysis: List of merged step dicts from the vision analyzer.
        screenshots_dir: Directory where the screenshots live (used to build
                         relative image paths in the Markdown).
        output_dir: Directory where the .md file will be written.

    Returns:
        The generated Markdown string. Also writes output_dir/{journey_name}.md.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    title = _journey_name_to_title(journey_name)
    intro = _step_intro(journey_name)

    lines: list[str] = [
        f"# How to {title}",
        "",
        f"> {intro}",
        "",
        "---",
        "",
    ]

    for item in analysis:
        step_num = item.get("step", "?")
        action = item.get("action", "step")
        screenshot_filename = item.get("screenshot", "")

        # Prefer vision tutorial_text; fall back to step description
        step_text = (
            item.get("tutorial_text")
            or item.get("description")
            or f"Complete step {step_num}."
        )

        # Build the screen heading from vision data or action name
        screen_name = item.get("screen_name") or action.replace("_", " ").title()
        step_heading = f"Step {step_num}: {screen_name}"

        # Build a relative path from output_dir back to the screenshot.
        # Pattern: ../../automation/screenshots/<journey>/<filename>
        rel_screenshot = (
            f"../../automation/screenshots/{journey_name}/{screenshot_filename}"
            if screenshot_filename
            else ""
        )

        alt_text = screen_name

        lines.append(f"## {step_heading}")
        lines.append("")

        if rel_screenshot:
            lines.append(f"![{alt_text}]({rel_screenshot})")
            lines.append("")

        lines.append(step_text)
        lines.append("")
        lines.append("---")
        lines.append("")

    # Remove trailing separator
    while lines and lines[-1] in ("---", ""):
        lines.pop()

    markdown = "\n".join(lines) + "\n"

    out_path = output_dir / f"{journey_name}.md"
    with open(out_path, "w") as f:
        f.write(markdown)

    print(f"[generator] Tutorial written → {out_path}")
    return markdown


def generate_all(base_dir: str, output_dir: str) -> list[str]:
    """
    Generate tutorials for every journey that has an analysis.json.

    Scans base_dir/screenshots/ for subdirectories containing analysis.json
    and calls generate_tutorial for each.

    Args:
        base_dir: Root of the automation directory
                  (expects base_dir/screenshots/<journey>/analysis.json).
        output_dir: Directory where .md files will be written.

    Returns:
        List of absolute paths to the generated Markdown files.
    """
    base_dir = Path(base_dir)
    screenshots_root = base_dir / "screenshots"
    generated: list[str] = []

    if not screenshots_root.exists():
        print(f"[generator] screenshots directory not found: {screenshots_root}")
        return generated

    for journey_dir in sorted(screenshots_root.iterdir()):
        if not journey_dir.is_dir():
            continue

        analysis_file = journey_dir / "analysis.json"
        if not analysis_file.exists():
            continue

        journey_name = journey_dir.name
        with open(analysis_file) as f:
            analysis = json.load(f)

        generate_tutorial(
            journey_name=journey_name,
            analysis=analysis,
            screenshots_dir=str(journey_dir),
            output_dir=output_dir,
        )

        out_path = str(Path(output_dir) / f"{journey_name}.md")
        generated.append(out_path)

    return generated


def generate_index(tutorials: list[str], output_dir: str) -> str:
    """
    Create a README.md index linking all generated tutorials.

    Args:
        tutorials: List of paths to .md tutorial files (from generate_all).
        output_dir: Directory where README.md will be written (typically docs/).

    Returns:
        The path to the generated README.md file.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    lines: list[str] = [
        "# HomeScope Documentation",
        "",
        "HomeScope is a neighbourhood intelligence app for Portugal, "
        "helping you make smarter property decisions.",
        "",
        "## Tutorials",
        "",
        "| Tutorial | Description |",
        "|----------|-------------|",
    ]

    # Build a short description per tutorial
    descriptions: dict[str, str] = {
        "search-property": "Search any address and view neighbourhood insights",
        "explore-neighbourhoods": "Browse curated neighbourhoods and filter by category",
        "settings-tour": "Customise your profile, radius, appearance, and AI features",
    }

    for tutorial_path in sorted(tutorials):
        p = Path(tutorial_path)
        journey_name = p.stem  # filename without extension
        title = _journey_name_to_title(journey_name)
        desc = descriptions.get(journey_name, f"Walkthrough of {title}")

        # Relative link from output_dir to tutorial file
        try:
            rel = os.path.relpath(tutorial_path, output_dir)
        except ValueError:
            rel = tutorial_path

        lines.append(f"| [{title}]({rel}) | {desc} |")

    lines += [
        "",
        "## About",
        "",
        "Built with Flutter · Powered by OpenAI · Data from OpenStreetMap",
        "",
        "---",
        "",
        "*Auto-generated by HomeScope Tutorial Generator. "
        "Run `python generate_tutorials.py` to update.*",
        "",
    ]

    readme_path = output_dir / "README.md"
    with open(readme_path, "w") as f:
        f.write("\n".join(lines))

    print(f"[generator] Index written → {readme_path}")
    return str(readme_path)
