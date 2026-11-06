@capability:render-markdown-html-page
@root-scenario:render-markdown-html-page
@scenario:render-markdown-html-page
@input:render-markdown-html-page-request
@input-contract:render-markdown-html-page-request.v1
@event:render-markdown-html-page-requested
@event-authority:render-markdown-html-page.v1
@outcome:render-markdown-html-page-outcome
@outcome-contract:markdown-page-publication.v1
@outcome-terminal
Feature: Render a Markdown document as a standalone HTML page

  @case:retained-library-report
  @provider:sql-database-reader
  @provider:apply-declared-change
  @provider:python-markdown-page-operation
  Scenario: Publish a page using its admitted Python renderer and presentation profile
    Given a UTF-8 Markdown source or retained digest, page metadata and an approved presentation profile
      """json
      {"sourceDigest":"sha256:94a77a826d7822419a8fe8c2d00275048a541c1a1d6aff4f753835abcad0c966","title":"Python standard library provider proposals","lang":"en","profile":"technical-report-v1","filename":"python-library-provider-report.html"}
      """
    When SideFX resolves the pinned Python parser and sanitizer, assembles the page and publishes its UTF-8 bytes
    Then the receipt binds the source, renderer, presentation profile and independently verified published page
      | operation | path | equals |
      | render-markdown-html-page.finish | $.status | COMPLETE |
      | render-markdown-html-page.finish | $.filename | python-library-provider-report.html |

  @case:unrelated-markdown
  @provider:sql-database-reader
  @provider:apply-declared-change
  @provider:python-markdown-page-operation
  Scenario: Publish a page using its admitted Python renderer and presentation profile
    Given a UTF-8 Markdown source or retained digest, page metadata and an approved presentation profile
      """json
      {"markdown":"# Harbor café\n\nCrew notes for Δ.\n\n| Watch | Lead |\n| --- | --- |\n| Dawn | Zoë |\n\n```python\nprint('<safe>')\n```\n\n[Weather](https://example.org/weather)\n\n<script>alert(1)</script>","title":"Harbor log","lang":"en","profile":"technical-report-v1","filename":"harbor-log.html"}
      """
    When SideFX resolves the pinned Python parser and sanitizer, assembles the page and publishes its UTF-8 bytes
    Then the receipt binds the source, renderer, presentation profile and independently verified published page
      | operation | path | equals |
      | render-markdown-html-page.finish | $.status | COMPLETE |
      | render-markdown-html-page.finish | $.filename | harbor-log.html |
