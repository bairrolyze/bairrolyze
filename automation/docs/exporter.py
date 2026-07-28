"""
HomeScope Tutorial Exporter
-----------------------------
Converts Markdown tutorials to HTML and Mintlify-compatible MDX structures.

Requires:
    pip install markdown2
"""

import json
import os
import shutil
from pathlib import Path

import markdown2


# ---------------------------------------------------------------------------
# HTML template
# ---------------------------------------------------------------------------

_HTML_TEMPLATE = """\
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{title}</title>
  <style>
    *, *::before, *::after {{ box-sizing: border-box; }}

    :root {{
      --bg:        #060B14;
      --surface:   #0D1526;
      --border:    #1E2D47;
      --accent:    #3B82F6;
      --accent-lt: #60A5FA;
      --text:      #F0F4FF;
      --muted:     #8B9CC8;
      --code-bg:   #101C30;
    }}

    body {{
      margin: 0;
      padding: 0;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
                   "Helvetica Neue", Arial, sans-serif;
      font-size: 16px;
      line-height: 1.7;
    }}

    .page-wrap {{
      max-width: 820px;
      margin: 0 auto;
      padding: 48px 24px 96px;
    }}

    /* Typography */
    h1 {{ font-size: 2rem; color: var(--text); margin-bottom: 0.25em; }}
    h2 {{ font-size: 1.35rem; color: var(--accent-lt); margin-top: 2.5em; }}
    h3 {{ font-size: 1.1rem; color: var(--muted); margin-top: 1.5em; }}
    p  {{ margin: 0.75em 0; }}

    a {{ color: var(--accent); text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}

    /* Callout (blockquote) */
    blockquote {{
      margin: 1.5em 0;
      padding: 14px 20px;
      border-left: 4px solid var(--accent);
      background: var(--surface);
      border-radius: 6px;
      color: var(--muted);
      font-style: italic;
    }}
    blockquote p {{ margin: 0; }}

    /* Code */
    code {{
      background: var(--code-bg);
      color: var(--accent-lt);
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 0.88em;
      font-family: "JetBrains Mono", "Fira Code", "Cascadia Code",
                   "Courier New", monospace;
    }}
    pre {{
      background: var(--code-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 20px;
      overflow-x: auto;
    }}
    pre code {{ background: none; padding: 0; color: var(--text); }}

    /* Tables */
    table {{
      border-collapse: collapse;
      width: 100%;
      margin: 1.5em 0;
    }}
    th, td {{
      text-align: left;
      padding: 10px 14px;
      border: 1px solid var(--border);
    }}
    th {{ background: var(--surface); color: var(--accent-lt); }}
    tr:nth-child(even) {{ background: var(--surface); }}

    /* Screenshots */
    img {{
      max-width: 100%;
      height: auto;
      border-radius: 12px;
      border: 1px solid var(--border);
      display: block;
      margin: 1.5em 0;
    }}

    /* Divider */
    hr {{
      border: none;
      border-top: 1px solid var(--border);
      margin: 2.5em 0;
    }}

    /* Lists */
    ul, ol {{ padding-left: 1.5em; }}
    li {{ margin: 0.35em 0; }}

    /* Step header badge */
    h2 span.step-badge {{
      display: inline-block;
      background: var(--accent);
      color: #fff;
      font-size: 0.7rem;
      font-weight: 700;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      padding: 2px 8px;
      border-radius: 999px;
      margin-right: 8px;
      vertical-align: middle;
    }}

    /* Footer */
    footer {{
      margin-top: 64px;
      padding-top: 24px;
      border-top: 1px solid var(--border);
      color: var(--muted);
      font-size: 0.85em;
    }}
  </style>
</head>
<body>
  <div class="page-wrap">
    {body}
    <footer>
      <p>HomeScope · Auto-generated tutorial</p>
    </footer>
  </div>
</body>
</html>
"""


def _extract_title(md_content: str) -> str:
    """Pull the first H1 from the markdown as the HTML title."""
    for line in md_content.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped[2:].strip()
    return "HomeScope Tutorial"


def to_html(md_path: str, output_dir: str) -> str:
    """
    Convert a single Markdown tutorial to a styled HTML file.

    Args:
        md_path: Path to the .md file.
        output_dir: Directory where the .html file will be written.

    Returns:
        Absolute path to the generated HTML file.
    """
    md_path = Path(md_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    md_content = md_path.read_text(encoding="utf-8")
    title = _extract_title(md_content)

    body_html = markdown2.markdown(
        md_content,
        extras=["fenced-code-blocks", "tables"],
    )

    full_html = _HTML_TEMPLATE.format(title=title, body=body_html)

    out_name = md_path.stem + ".html"
    out_path = output_dir / out_name
    out_path.write_text(full_html, encoding="utf-8")

    print(f"[exporter] HTML written → {out_path}")
    return str(out_path)


def export_all(tutorials_dir: str, html_output_dir: str) -> list[str]:
    """
    Convert every .md file in tutorials_dir to HTML.

    Args:
        tutorials_dir: Directory containing .md tutorial files.
        html_output_dir: Directory where HTML files will be written.

    Returns:
        List of absolute paths to generated HTML files.
    """
    tutorials_dir = Path(tutorials_dir)
    generated: list[str] = []

    for md_file in sorted(tutorials_dir.glob("*.md")):
        if md_file.name.lower() == "readme.md":
            continue  # skip index
        path = to_html(str(md_file), html_output_dir)
        generated.append(path)

    return generated


def to_mintlify_structure(docs_dir: str, output_dir: str) -> str:
    """
    Create a Mintlify-compatible docs structure from the tutorials directory.

    Layout produced:
        output_dir/
            mint.json
            docs/
                tutorials/
                    <journey-name>.mdx
                    ...

    Args:
        docs_dir: Directory containing the source .md tutorial files
                  (and optionally a README.md).
        output_dir: Root directory for the Mintlify output.

    Returns:
        Absolute path to the generated mint.json file.
    """
    docs_dir = Path(docs_dir)
    output_dir = Path(output_dir)

    tutorials_out = output_dir / "docs" / "tutorials"
    tutorials_out.mkdir(parents=True, exist_ok=True)

    tutorial_nav_items: list[str] = []

    for md_file in sorted(docs_dir.glob("*.md")):
        if md_file.name.lower() == "readme.md":
            continue

        dest = tutorials_out / (md_file.stem + ".mdx")
        shutil.copy2(md_file, dest)

        # Mintlify nav paths are relative to the output root without extension
        nav_path = f"docs/tutorials/{md_file.stem}"
        tutorial_nav_items.append(nav_path)
        print(f"[exporter] MDX copied → {dest}")

    # Build mint.json
    mint_config = {
        "name": "HomeScope",
        "logo": {
            "light": "/logo/light.svg",
            "dark": "/logo/dark.svg",
        },
        "favicon": "/favicon.png",
        "colors": {
            "primary": "#3B82F6",
            "light": "#60A5FA",
            "dark": "#060B14",
        },
        "topbarLinks": [
            {"name": "App Store", "url": "https://homescope.app"},
        ],
        "navigation": [
            {
                "group": "Getting Started",
                "pages": ["docs/index"] if (docs_dir / "README.md").exists() else [],
            },
            {
                "group": "Tutorials",
                "pages": tutorial_nav_items,
            },
        ],
        "footerSocials": {
            "website": "https://homescope.app",
        },
    }

    # Copy README as docs/index.mdx if it exists
    readme = docs_dir / "README.md"
    if readme.exists():
        index_out = output_dir / "docs" / "index.mdx"
        index_out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(readme, index_out)
        print(f"[exporter] Index MDX → {index_out}")

    mint_path = output_dir / "mint.json"
    with open(mint_path, "w") as f:
        json.dump(mint_config, f, indent=2)

    print(f"[exporter] mint.json written → {mint_path}")
    return str(mint_path)
