"""Bounded Python library provider. Public requests cannot supply policy or code."""
import hashlib
import html
from html.parser import HTMLParser
from importlib.metadata import version
import json
import platform
import re
from urllib.parse import urlsplit

import markdown
from markdown.extensions import Extension
from markdown.inlinepatterns import InlineProcessor
from markdown.preprocessors import Preprocessor
from markdown.util import AtomicString
import nh3


def digest(data):
    return "sha256:" + hashlib.sha256(data).hexdigest()


def allowed_link(value):
    if any(ord(char) < 33 or char == "\\" for char in value):
        return False
    if value.startswith("#"):
        return bool(re.fullmatch(r"#[\w.-]+", value))
    try:
        url = urlsplit(value)
        return url.scheme.lower() in {"http", "https"} and bool(url.hostname)
    except ValueError:
        return False


class LiteralIdentifier(InlineProcessor):
    def handleMatch(self, match, data):
        return AtomicString(match.group(0)), match.start(0), match.end(0)


class LabelledList(Preprocessor):
    def run(self, lines):
        output = []
        for line in lines:
            if (output and re.fullmatch(r"\*\*[^*]+\*\*", output[-1].strip())
                    and re.match(r"^ {0,3}(?:[-*+] |[0-9]+\. )", line)):
                output.append("")
            output.append(line)
        return output


class TechnicalMarkdown(Extension):
    def extendMarkdown(self, md):
        # Code spans and links retain their normal higher priority.
        md.inlinePatterns.register(LiteralIdentifier(r"(?<!\w)__[A-Za-z][A-Za-z0-9_]*?__(?!\w)", md), "literal-dunder", 75)
        md.preprocessors.register(LabelledList(md), "labelled-list", 15)


def fragment(source, profile):
    raw = markdown.markdown(source, extensions=["tables", "fenced_code", "sane_lists", TechnicalMarkdown()], output_format="html5")
    return nh3.clean(raw, tags=set(profile["allowedTags"]), attributes={"a": {"href"}},
                     allowed_classes={"code": set(profile["codeClasses"])},
                     attribute_filter=lambda tag, key, value: None if key == "href" and not allowed_link(value) else value,
                     url_schemes={"https", "http"}, url_relative="pass_through", link_rel="noopener noreferrer",
                     clean_content_tags={"script", "style", "iframe", "object", "template"})


class Headings(HTMLParser):
    def __init__(self):
        super().__init__()
        self.labels = []
        self.parts = None

    def handle_starttag(self, tag, attrs):
        if re.fullmatch("h[1-6]", tag):
            self.parts = []

    def handle_data(self, data):
        if self.parts is not None:
            self.parts.append(data)

    def handle_endtag(self, tag):
        if re.fullmatch("h[1-6]", tag) and self.parts is not None:
            self.labels.append("".join(self.parts))
            self.parts = None


def render(request, profile):
    source, title, lang = request["markdown"], request["title"], request["lang"]
    if not (isinstance(source, str) and 0 < len(source.encode("utf-8")) <= 2_097_152
            and isinstance(title, str) and 0 < len(title.strip()) <= 200
            and re.fullmatch(r"[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*", lang)
            and request["profile"] == profile["id"]
            and re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]{0,95}\.html", request["filename"])):
        raise ValueError("INVALID_MARKDOWN_PAGE_REQUEST")
    clean = fragment(source, profile)
    headings = Headings()
    headings.feed(clean)
    headings.close()
    ids = iter(range(1, len(headings.labels) + 1))
    article = re.sub(r"<(h[1-6])>", lambda m: f'<{m[1]} id="section-{next(ids)}">', clean)
    links = "".join(f'<li><a href="#section-{i}">{html.escape(label)}</a></li>'
                    for i, label in enumerate(headings.labels, 1))
    escaped_title = html.escape(title)
    page = (f'<!doctype html>\n<html lang="{lang}"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width, initial-scale=1">'
            f'<meta http-equiv="Content-Security-Policy" content="{html.escape(profile["csp"], quote=True)}">'
            f'<title>{escaped_title}</title><style>{profile["css"]}</style></head>'
            f'<body><header><strong>{escaped_title}</strong></header><main>'
            f'<nav aria-label="Contents"><strong>Contents</strong><ol>{links}</ol></nav>'
            f'<article>{article}</article></main></body></html>\n')
    return {"html": page, "sourceDigest": digest(source.encode()), "outputDigest": digest(page.encode()),
            "renderer": {"python": platform.python_version(), "Markdown": version("Markdown"), "nh3": version("nh3")}}
