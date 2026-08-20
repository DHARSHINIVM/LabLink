import io
import re
from typing import Dict, List, Optional, Tuple

import pdfplumber

from ..schemas.inventory_import import ExtractedResource


HEADER_ALIASES = {
    "name": {
        "name",
        "resource",
        "resource_name",
        "item",
        "item_name",
        "equipment",
        "equipment_name",
        "asset",
        "asset_name",
    },
    "category": {
        "category",
        "type",
        "resource_type",
        "equipment_type",
    },
    "quantity": {
        "quantity",
        "qty",
        "total",
        "total_quantity",
        "count",
        "units",
        "no_of_units",
        "number",
    },
    "location": {
        "location",
        "lab",
        "laboratory",
        "room",
        "storage_location",
    },
    "department": {
        "department",
        "dept",
        "branch",
        "academic_department",
    },
    "description": {
        "description",
        "details",
        "remarks",
        "specification",
        "specifications",
    },
}


def normalize_header(value: str) -> str:
    value = value.strip().lower()

    value = re.sub(
        r"[^a-z0-9]+",
        "_",
        value,
    )

    return value.strip("_")


def clean_cell(value: Optional[str]) -> str:
    if value is None:
        return ""

    value = str(value)

    value = value.replace("\n", " ")

    value = re.sub(
        r"\s+",
        " ",
        value,
    )

    return value.strip()


def extract_integer(
    value: str,
) -> Optional[int]:

    if not value:
        return None

    match = re.search(
        r"\d+",
        value,
    )

    if not match:
        return None

    return int(match.group())


def map_headers(
    headers: List[str],
) -> Dict[int, str]:

    mapping: Dict[int, str] = {}

    for index, header in enumerate(headers):

        if header is None:
            continue

        normalized = normalize_header(
            str(header)
        )

        for field, aliases in HEADER_ALIASES.items():

            if normalized in aliases:

                mapping[index] = field

                break

    return mapping


def build_resource_from_row(
    row: List[str],
    header_mapping: Dict[int, str],
) -> Optional[ExtractedResource]:

    values: Dict[str, str] = {}

    for index, value in enumerate(row):

        if index not in header_mapping:
            continue

        field = header_mapping[index]

        values[field] = clean_cell(value)

    name = values.get("name", "")

    if not name:
        return None

    return ExtractedResource(
        name=name,

        category=(
            values.get("category")
            or None
        ),

        quantity=extract_integer(
            values.get("quantity", "")
        ),

        location=(
            values.get("location")
            or None
        ),

        department=(
            values.get("department")
            or None
        ),

        description=(
            values.get("description")
            or None
        ),
    )


# ============================================================================
# TABLE EXTRACTION
# ============================================================================

def extract_digital_tables(
    pdf_bytes: bytes,
) -> Tuple[
    List[ExtractedResource],
    List[str],
    int,
]:

    resources = []
    warnings = []
    pages_processed = 0

    with pdfplumber.open(
        io.BytesIO(pdf_bytes)
    ) as pdf:

        pages_processed = len(pdf.pages)

        for page_number, page in enumerate(
            pdf.pages,
            start=1,
        ):

            tables = page.extract_tables()

            if not tables:
                continue

            for table in tables:

                if not table:
                    continue

                headers = table[0]

                if not headers:
                    continue

                header_mapping = map_headers(
                    headers
                )

                if "name" not in header_mapping.values():
                    continue

                for row in table[1:]:

                    resource = (
                        build_resource_from_row(
                            row,
                            header_mapping,
                        )
                    )

                    if resource:
                        resources.append(
                            resource
                        )

    return (
        resources,
        warnings,
        pages_processed,
    )


# ============================================================================
# TEXT EXTRACTION
# ============================================================================

def extract_text_lines(
    pdf_bytes: bytes,
) -> Tuple[
    List[str],
    int,
]:

    lines = []
    pages_processed = 0

    with pdfplumber.open(
        io.BytesIO(pdf_bytes)
    ) as pdf:

        pages_processed = len(pdf.pages)

        for page in pdf.pages:

            text = page.extract_text()

            if not text:
                continue

            for line in text.splitlines():

                line = clean_cell(line)

                if line:
                    lines.append(line)

    return (
        lines,
        pages_processed,
    )


# ============================================================================
# TEXT FIELD EXTRACTION
# ============================================================================

def extract_field(
    line: str,
    labels: List[str],
) -> Optional[str]:

    label_pattern = "|".join(
        re.escape(label)
        for label in labels
    )

    pattern = (
        rf"(?:{label_pattern})"
        rf"\s*[:\-]\s*(.+)"
    )

    match = re.search(
        pattern,
        line,
        flags=re.IGNORECASE,
    )

    if not match:
        return None

    return clean_cell(
        match.group(1)
    )


# ============================================================================
# STRUCTURED TEXT EXTRACTION
# ============================================================================

def extract_structured_text(
    pdf_bytes: bytes,
) -> Tuple[
    List[ExtractedResource],
    List[str],
    int,
]:

    lines, pages_processed = (
        extract_text_lines(
            pdf_bytes
        )
    )

    resources = []
    warnings = []

    current: Dict[str, str] = {}

    def flush_current():

        nonlocal current

        if not current.get("name"):
            current = {}
            return

        resource = ExtractedResource(
            name=current["name"],

            category=(
                current.get("category")
                or None
            ),

            quantity=extract_integer(
                current.get(
                    "quantity",
                    "",
                )
            ),

            location=(
                current.get("location")
                or None
            ),

            department=(
                current.get("department")
                or None
            ),

            description=(
                current.get("description")
                or None
            ),
        )

        resources.append(resource)

        current = {}

    for line in lines:

        # ------------------------------------------------------------
        # NAME
        # ------------------------------------------------------------

        value = extract_field(
            line,
            [
                "name",
                "resource",
                "resource name",
                "item",
                "equipment",
            ],
        )

        if value:

            flush_current()

            current["name"] = value
            continue

        # ------------------------------------------------------------
        # CATEGORY
        # ------------------------------------------------------------

        value = extract_field(
            line,
            [
                "category",
                "type",
                "resource type",
            ],
        )

        if value:

            current["category"] = value
            continue

        # ------------------------------------------------------------
        # QUANTITY
        # ------------------------------------------------------------

        value = extract_field(
            line,
            [
                "quantity",
                "qty",
                "total",
                "count",
                "units",
            ],
        )

        if value:

            current["quantity"] = value
            continue

        # ------------------------------------------------------------
        # LOCATION
        # ------------------------------------------------------------

        value = extract_field(
            line,
            [
                "location",
                "lab",
                "laboratory",
                "room",
            ],
        )

        if value:

            current["location"] = value
            continue

        # ------------------------------------------------------------
        # DEPARTMENT
        # ------------------------------------------------------------

        value = extract_field(
            line,
            [
                "department",
                "dept",
                "branch",
            ],
        )

        if value:

            current["department"] = value
            continue

        # ------------------------------------------------------------
        # DESCRIPTION
        # ------------------------------------------------------------

        value = extract_field(
            line,
            [
                "description",
                "details",
                "remarks",
            ],
        )

        if value:

            current["description"] = value
            continue

    flush_current()

    return (
        resources,
        warnings,
        pages_processed,
    )


# ============================================================================
# DETECT DIGITAL TEXT
# ============================================================================

def has_extractable_text(
    pdf_bytes: bytes,
) -> bool:

    try:

        with pdfplumber.open(
            io.BytesIO(pdf_bytes)
        ) as pdf:

            for page in pdf.pages:

                text = page.extract_text()

                if text and text.strip():
                    return True

    except Exception:

        return False

    return False


# ============================================================================
# MAIN EXTRACTION
# ============================================================================

def extract_inventory(
    pdf_bytes: bytes,
):

    # ------------------------------------------------------------
    # DIGITAL PDF
    # ------------------------------------------------------------

    if has_extractable_text(
        pdf_bytes
    ):

        # First try actual tables.
        (
            resources,
            warnings,
            pages,
        ) = extract_digital_tables(
            pdf_bytes
        )

        if resources:

            return (
                resources,
                warnings,
                pages,
                "digital_table",
            )

        # --------------------------------------------------------
        # FALLBACK: STRUCTURED TEXT
        # --------------------------------------------------------

        (
            text_resources,
            text_warnings,
            text_pages,
        ) = extract_structured_text(
            pdf_bytes
        )

        warnings.extend(
            text_warnings
        )

        if text_resources:

            return (
                text_resources,
                warnings,
                text_pages,
                "digital_text",
            )

        return (
            [],
            [
                "Digital text was detected, "
                "but no structured resource "
                "records could be identified."
            ],
            text_pages,
            "digital_text",
        )

    # ------------------------------------------------------------
    # SCANNED / HANDWRITTEN
    # ------------------------------------------------------------

    return (
        [],
        [
            "No extractable digital text "
            "was detected. OCR/handwriting "
            "processing is required."
        ],
        0,
        "ocr_required",
    )