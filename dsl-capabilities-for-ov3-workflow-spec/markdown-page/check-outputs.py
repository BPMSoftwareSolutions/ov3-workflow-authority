"""Independent checks for the two acceptance artifacts. Uses only Python's stdlib."""
from collections import Counter
from html.parser import HTMLParser
import hashlib
import json
from pathlib import Path
import re
import sys


class Article(HTMLParser):
    def __init__(self):
        super().__init__()
        self.inside = False
        self.heading = self.code = None
        self.headings, self.blocks, self.links = [], [], []
        self.counts = Counter()

    def handle_starttag(self, tag, attrs):
        if tag == "article":
            self.inside = True
        if not self.inside:
            return
        self.counts[tag] += 1
        if tag in {"h1", "h2"}:
            self.heading = []
        if tag == "pre":
            self.code = []
        if tag == "a" and "href" in dict(attrs):
            self.links.append(dict(attrs)["href"])

    def handle_data(self, data):
        if self.heading is not None:
            self.heading.append(data)
        if self.code is not None:
            self.code.append(data)

    def handle_endtag(self, tag):
        if tag in {"h1", "h2"} and self.heading is not None:
            self.headings.append("".join(self.heading))
            self.heading = None
        if tag == "pre" and self.code is not None:
            self.blocks.append("".join(self.code))
            self.code = None
        if tag == "article":
            self.inside = False


here = Path(__file__).parent
artifacts = Path(sys.argv[1])
fixtures = json.loads((here/"acceptance.json").read_text(encoding="utf-8"))
sources = [here.parent.parent/"outputs/python-library-provider-report.md", here/"harbor-log.md"]
for f, source in zip(fixtures, sources):
    raw = source.read_bytes()
    page = (artifacts/f["filename"]).read_bytes()
    assert "sha256:" + hashlib.sha256(raw).hexdigest() == f["sourceDigest"]
    assert "sha256:" + hashlib.sha256(page).hexdigest() == f["outputDigest"]
    text = raw.decode("utf-8").replace("\r\n", "\n")
    parser = Article()
    parser.feed(page.decode("utf-8"))
    parser.close()
    headings = re.findall(r"^#{1,2} (.+)$", text, re.M)
    assert headings == parser.headings, "Markdown and HTML heading text differ"
    blocks = re.findall(r"^```[^\n]*\n(.*?)^```\s*$", text, re.M | re.S)
    assert blocks == parser.blocks, "Fenced code or contract bytes differ"
    links = re.findall(r"\[[^\]\n]+\]\((https?://[^)\s]+)\)", text)
    assert Counter(links) == Counter(parser.links), "Document links differ"
    if source.name.startswith("python-library"):
        assert len(headings) == 322 and len(blocks) == 594
    else:
        assert parser.counts["table"] == 1 and b"alert(1)" not in page
        assert "Zoë" in page.decode() and "Crew notes for Δ." in page.decode()
    print(f["filename"],len(headings),"headings,",len(blocks),"unaltered fences,",len(links),"links")
