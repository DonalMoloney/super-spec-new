from link_audit.anchors import slugify_headings


def test_reports_missing_heading_anchor():
    source = "# Setup Guide\n\n## Advanced Options!\n"
    anchors = slugify_headings(source)
    slugs = [a.slug for a in anchors]
    assert slugs == ["setup-guide", "advanced-options"]


def test_duplicate_heading_slugs_get_numeric_suffix():
    source = "# Setup\n\n## Setup\n\n### Setup\n"
    anchors = slugify_headings(source)
    slugs = [a.slug for a in anchors]
    assert slugs == ["setup", "setup-1", "setup-2"]


def test_heading_like_line_inside_fenced_code_block_is_not_extracted():
    source = (
        "# Real Heading\n"
        "\n"
        "```bash\n"
        "# This is a bash comment, not a heading\n"
        "```\n"
        "\n"
        "## Another Real Heading\n"
    )
    anchors = slugify_headings(source)
    slugs = [a.slug for a in anchors]
    assert slugs == ["real-heading", "another-real-heading"]
