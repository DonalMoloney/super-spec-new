from pathlib import Path

from link_audit.links import extract_links


def test_extracts_inline_link_targets():
    source = (
        "# Title\n"
        "See [docs](guide.md) for more.\n"
        "\n"
        "Also [anchor link](guide.md#setup) and [ext](https://example.com).\n"
    )
    links = extract_links(Path("readme.md"), source)
    assert len(links) == 3

    assert links[0].source_file == Path("readme.md")
    assert links[0].line_number == 2
    assert links[0].text == "docs"
    assert links[0].target_raw == "guide.md"

    assert links[1].line_number == 4
    assert links[1].target_raw == "guide.md#setup"

    assert links[2].target_raw == "https://example.com"


def test_extract_links_returns_empty_list_for_no_links():
    assert extract_links(Path("readme.md"), "# Title\nNo links here.\n") == []
