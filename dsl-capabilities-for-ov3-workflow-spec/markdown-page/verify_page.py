"""Verify the retrieved publication independently of the renderer's receipt."""
from collections import Counter
import hashlib
import html
from html.parser import HTMLParser
import re

from page_provider import allowed_link, fragment


def require(test, code):
    if not test:
        raise ValueError(code)


class Inspect(HTMLParser):
    def __init__(self, profile):
        super().__init__()
        self.profile = profile
        self.tags = Counter()
        self.stack = []
        self.anchors = []
        self.navigation = []
        self.title = []
        self.style = []
        self.charset = self.csp = self.declarations = 0
        self.language = None
        self.heading_labels = []
        self.nav_labels = []

    def handle_decl(self, decl):
        require(decl.lower() == "doctype html" and not self.stack, "UNEXPECTED_DECLARATION")
        self.declarations += 1

    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        require(len(attr) == len(attrs), "DUPLICATE_ATTRIBUTE")
        parent = self.stack[-1] if self.stack else None
        inside = "article" in self.stack
        wrappers = {"html": None, "head": "html", "meta": "head", "title": "head", "style": "head",
                    "body": "html", "header": "body", "main": "body", "nav": "main", "article": "main"}
        if tag in wrappers:
            require(parent == wrappers[tag], "DOCUMENT_STRUCTURE")
        elif inside:
            require(tag in self.profile["allowedTags"], "UNSAFE_ELEMENT")
        else:
            require((parent, tag) in {("header", "strong"), ("nav", "strong"), ("nav", "ol"),
                                      ("ol", "li"), ("li", "a")}, "UNEXPECTED_CHROME")
        allowed = {"html": {"lang"}, "meta": {"charset", "name", "content", "http-equiv"},
                   "nav": {"aria-label"}, "a": {"href", "rel"}, "code": {"class"}}
        heading = bool(re.fullmatch("h[1-6]", tag))
        require(set(attr) <= ({"id"} if heading else allowed.get(tag, set())), "UNSAFE_ATTRIBUTE")
        if tag == "meta":
            if attr == {"charset": "utf-8"}:
                self.charset += 1
            elif attr == {"http-equiv": "Content-Security-Policy", "content": self.profile["csp"]}:
                self.csp += 1
            else:
                require(attr == {"name": "viewport", "content": "width=device-width, initial-scale=1"}, "UNSAFE_META")
        if tag == "html":
            self.language = attr.get("lang")
        if heading:
            expected = "section-" + str(len(self.anchors) + 1)
            require(attr.get("id") == expected, "HEADING_ANCHOR")
            self.anchors.append("#" + expected)
            self.heading_labels.append([])
        if tag == "a" and "href" in attr:
            require(allowed_link(attr["href"]), "UNSAFE_LINK")
            if "nav" in self.stack:
                self.navigation.append(attr["href"])
                self.nav_labels.append([])
        if tag == "code" and "class" in attr:
            require(attr["class"] in self.profile["codeClasses"], "UNAPPROVED_CODE_CLASS")
        self.tags[tag] += 1
        if tag not in {"br", "hr", "meta"}:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        require(self.stack and self.stack.pop() == tag, "UNBALANCED_DOCUMENT")

    def handle_data(self, data):
        if "title" in self.stack:
            self.title.append(data)
        if "style" in self.stack:
            self.style.append(data)
        if "article" in self.stack and any(re.fullmatch("h[1-6]", s) for s in self.stack):
            self.heading_labels[-1].append(data)
        if "nav" in self.stack and "a" in self.stack:
            self.nav_labels[-1].append(data)


def verify(request, page, receipt, profile):
    def sha(text):
        return "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()
    require(sha(request["markdown"]) == receipt["sourceDigest"], "SOURCE_DIGEST_MISMATCH")
    require(sha(page) == receipt["outputDigest"], "OUTPUT_DIGEST_MISMATCH")
    parser = Inspect(profile)
    parser.feed(page)
    parser.close()
    require(not parser.stack and parser.declarations == parser.charset == parser.csp == 1, "DOCUMENT_STRUCTURE")
    require(all(parser.tags[t] == 1 for t in ("html","head","body","header","main","nav","article","style","title")), "DOCUMENT_STRUCTURE")
    require(parser.language == request["lang"] and "".join(parser.title) == request["title"], "METADATA")
    require(parser.anchors == parser.navigation and parser.heading_labels == parser.nav_labels, "NAVIGATION")
    require("".join(parser.style) == profile["css"], "PRESENTATION_PROFILE")
    match = re.search(r"<article>(.*?)</article>", page, re.S)
    require(match is not None, "ARTICLE_MISSING")
    unanchored = re.sub(r'<(h[1-6]) id="section-[0-9]+">', r'<\1>', match[1])
    require(unanchored == fragment(request["markdown"], profile), "SOURCE_CONTENT_MISMATCH")
    return {"status":"VERIFIED", "sourceDigest":sha(request["markdown"]), "outputDigest":sha(page),
            "utf8Bytes":len(page.encode()), "headings":len(parser.anchors), "paragraphs":parser.tags["p"],
            "tables":parser.tags["table"], "codeBlocks":parser.tags["pre"], "articleLinks":parser.tags["a"]-len(parser.navigation)}
