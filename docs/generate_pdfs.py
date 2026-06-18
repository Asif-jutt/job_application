#!/usr/bin/env python3
"""Convert Rozgar markdown docs to PDF using only Python standard library."""

import re
import textwrap
import zlib
from pathlib import Path

DOCS_DIR = Path(__file__).parent

FILES = [
    ("01_Rozgar_Rubric_Implementation_Guide.md", "01_Rozgar_Rubric_Implementation_Guide.pdf"),
    ("02_Rozgar_System_Overview_Viva_Guide.md", "02_Rozgar_System_Overview_Viva_Guide.pdf"),
]

PAGE_WIDTH = 612
PAGE_HEIGHT = 792
MARGIN_LEFT = 50
MARGIN_RIGHT = 50
MARGIN_TOP = 50
MARGIN_BOTTOM = 50
LINE_HEIGHT = 12
FONT_SIZE = 9
MAX_WIDTH_CHARS = 95


def escape_pdf(text: str) -> str:
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def wrap_line(text: str, width: int = MAX_WIDTH_CHARS) -> list[str]:
    if not text.strip():
        return [""]
    return textwrap.wrap(text, width=width) or [""]


class SimplePDF:
    def __init__(self):
        self.pages: list[list[str]] = [[]]
        self.y = PAGE_HEIGHT - MARGIN_TOP

    def _new_page(self):
        self.pages.append([])
        self.y = PAGE_HEIGHT - MARGIN_TOP

    def add_line(self, text: str, bold: bool = False, size: int = FONT_SIZE):
        prefix = ""
        if bold:
            prefix = ""
        for part in wrap_line(text):
            if self.y < MARGIN_BOTTOM:
                self._new_page()
            line = escape_pdf(part)
            if bold:
                self.pages[-1].append(
                    f"BT /F2 {size} Tf {MARGIN_LEFT} {self.y} Td ({line}) Tj ET"
                )
            else:
                self.pages[-1].append(
                    f"BT /F1 {size} Tf {MARGIN_LEFT} {self.y} Td ({line}) Tj ET"
                )
            self.y -= LINE_HEIGHT + (2 if bold else 0)

    def add_gap(self, h: int = 6):
        self.y -= h
        if self.y < MARGIN_BOTTOM:
            self._new_page()

    def save(self, path: Path):
        objects = []
        page_objs = []

        # Font objects
        objects.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
        objects.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")

        # Page content objects
        for page_lines in self.pages:
            stream = "\n".join(page_lines).encode("latin-1", errors="replace")
            compressed = zlib.compress(stream)
            content = (
                f"<< /Length {len(compressed)} /Filter /FlateDecode >>\n"
                f"stream\n".encode() + compressed + b"\nendstream"
            )
            objects.append(content)
            page_objs.append(len(objects))

        # Page tree objects
        page_refs = []
        for i, content_id in enumerate(page_objs):
            page_id = len(objects) + 1 + i
            page_refs.append(page_id)

        kids = " ".join(f"{r} 0 R" for r in page_refs)
        pages_id = len(objects) + 1 + len(page_objs)
        catalog_id = pages_id + 1

        for i, content_id in enumerate(page_objs):
            page_obj = (
                f"<< /Type /Page /Parent {pages_id} 0 R "
                f"/MediaBox [0 0 {PAGE_WIDTH} {PAGE_HEIGHT}] "
                f"/Contents {content_id} 0 R "
                f"/Resources << /Font << /F1 1 0 R /F2 2 0 R >> >> >>"
            )
            objects.append(page_obj)

        objects.append(f"<< /Type /Pages /Kids [{kids}] /Count {len(page_refs)} >>")
        objects.append(f"<< /Type /Catalog /Pages {pages_id} 0 R >>")

        # Build PDF file
        pdf = b"%PDF-1.4\n"
        offsets = [0]
        for i, obj in enumerate(objects, 1):
            offsets.append(len(pdf))
            if isinstance(obj, bytes):
                pdf += f"{i} 0 obj\n".encode() + obj + b"\nendobj\n"
            else:
                pdf += f"{i} 0 obj\n{obj}\nendobj\n".encode()

        xref_pos = len(pdf)
        pdf += f"xref\n0 {len(objects) + 1}\n".encode()
        pdf += b"0000000000 65535 f \n"
        for off in offsets[1:]:
            pdf += f"{off:010d} 00000 n \n".encode()
        pdf += f"trailer\n<< /Size {len(objects) + 1} /Root {catalog_id} 0 R >>\n".encode()
        pdf += f"startxref\n{xref_pos}\n%%EOF\n".encode()

        path.write_bytes(pdf)


def clean_text(text: str) -> str:
    text = text.replace("**", "")
    text = text.replace("`", "")
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return text.strip()


def md_to_pdf(md_path: Path, pdf_path: Path):
    pdf = SimplePDF()
    lines = md_path.read_text(encoding="utf-8").split("\n")
    in_code = False
    code_buffer = []

    for line in lines:
        stripped = line.strip()

        if stripped.startswith("```"):
            if in_code:
                pdf.add_gap(2)
                for cl in code_buffer:
                    pdf.add_line(cl, size=8)
                code_buffer = []
                in_code = False
            else:
                in_code = True
            continue

        if in_code:
            code_buffer.append(line)
            continue

        if not stripped:
            pdf.add_gap(4)
            continue

        if stripped.startswith("---"):
            pdf.add_gap(4)
            continue

        if stripped.startswith("# ") and not stripped.startswith("## "):
            pdf.add_gap(6)
            pdf.add_line(clean_text(stripped[2:]), bold=True, size=14)
            pdf.add_gap(4)
            continue

        if stripped.startswith("## "):
            pdf.add_gap(6)
            pdf.add_line(clean_text(stripped[3:]), bold=True, size=12)
            pdf.add_gap(2)
            continue

        if stripped.startswith("### "):
            pdf.add_gap(4)
            pdf.add_line(clean_text(stripped[4:]), bold=True, size=10)
            pdf.add_gap(2)
            continue

        if stripped.startswith("|") and "---" not in stripped:
            cells = [clean_text(c) for c in stripped.split("|")[1:-1]]
            pdf.add_line(" | ".join(cells), size=8)
            continue

        if stripped.startswith("- "):
            pdf.add_line("  - " + clean_text(stripped[2:]))
            continue

        if len(stripped) > 2 and stripped[0].isdigit() and ". " in stripped[:4]:
            pdf.add_line(clean_text(stripped))
            continue

        pdf.add_line(clean_text(stripped))

    pdf.save(pdf_path)
    print(f"Created: {pdf_path}")


def main():
    for md_name, pdf_name in FILES:
        md_path = DOCS_DIR / md_name
        pdf_path = DOCS_DIR / pdf_name
        if md_path.exists():
            md_to_pdf(md_path, pdf_path)
        else:
            print(f"Missing: {md_path}")
    print("\nDone! PDF files saved in docs/ folder.")


if __name__ == "__main__":
    main()
