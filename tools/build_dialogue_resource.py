#!/usr/bin/env python3
"""Regenerate time_paradoxes_10_hours.tres from the source .txt file.

Non-resource files (*.txt) are not reliably included in exports, so the text is
baked into a Godot Resource that is always exported. Run this after editing the
source text:  python3 tools/build_dialogue_resource.py
"""

import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "time_paradoxes_10_hours.txt"
DST = ROOT / "time_paradoxes_10_hours.tres"


def escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    raw = SRC.read_text(encoding="utf-8")
    paragraphs = [block.strip() for block in raw.split("\n\n")]
    paragraphs = [p for p in paragraphs if p]

    entries = ",\n".join('"%s"' % escape(p) for p in paragraphs)
    content = (
        '[gd_resource type="Resource" script_class="DialogueText" load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" path="res://scripts/data/dialogue_text.gd" id="1_text"]\n\n'
        "[resource]\n"
        'script = ExtResource("1_text")\n'
        "paragraphs = PackedStringArray(\n%s\n)\n" % entries
    )
    DST.write_text(content, encoding="utf-8")
    print("wrote %s (%d paragraphs)" % (DST.name, len(paragraphs)))


if __name__ == "__main__":
    main()
