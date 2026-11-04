@capability:read-python-library-sources
@root-scenario:read-python-library-sources
@scenario:read-python-library-sources
@input:read-python-library-sources-request
@input-contract:read-python-library-sources-request.v1
@event:read-python-library-sources-requested
@event-authority:read-python-library-sources.v1
@outcome:read-python-library-sources-outcome
@outcome-contract:python-library-sources.v1
@outcome-terminal
Feature: OV3 can enumerate Python library sources and resume a report from the same index
  As the estate owner
  I want OV3 to read the current library inventory in bounded pages
  So that every report entry can be traced to Python's documentation

  @case:py-inventory-first
  @provider:http-exchange-public
  @provider:sql-database-reader
  Scenario: Return a bounded first page with a continuation cursor
    Given the official Python standard library and module indexes and a bounded inventory request
      """json
      {"url":"https://docs.python.org/3/library/index.html","limit":1}
      """
    When OV3 reads both indexes and joins module entries to their library sections
    Then OV3 returns source-linked module rows and coverage counts or a named source finding
      | operation | path | equals |
      | read-python-library-sources.finish | $.status | LISTED |
      | read-python-library-sources.finish | $.modules[0].module | __future__ |
      | read-python-library-sources.finish | $.nextOffset | 1 |

  @case:py-inventory-removed
  @provider:http-exchange-public
  @provider:sql-database-reader
  Scenario: Identify a removed module from its own index entry
    Given the official Python standard library and module indexes and a bounded inventory request
      """json
      {"module":"aifc"}
      """
    When OV3 reads both indexes and joins module entries to their library sections
    Then OV3 returns source-linked module rows and coverage counts or a named source finding
      | operation | path | equals |
      | read-python-library-sources.finish | $.status | LISTED |
      | read-python-library-sources.finish | $.modules[0].removed | true |

  @case:py-inventory-missing
  @provider:http-exchange-public
  @provider:sql-database-reader
  Scenario: Return an empty result for an unknown module
    Given the official Python standard library and module indexes and a bounded inventory request
      """json
      {"module":"no_such_ov3_library"}
      """
    When OV3 reads both indexes and joins module entries to their library sections
    Then OV3 returns source-linked module rows and coverage counts or a named source finding
      | operation | path | equals |
      | read-python-library-sources.finish | $.status | NOT_FOUND |
      | read-python-library-sources.finish | $.matchingCount | 0 |

  @case:py-inventory-stale
  @provider:http-exchange-public
  @provider:sql-database-reader
  Scenario: Refuse to mix pages from different versions of the module index
    Given the official Python standard library and module indexes and a bounded inventory request
      """json
      {"expectedIndexHash":"sha256:0000000000000000000000000000000000000000000000000000000000000000"}
      """
    When OV3 reads both indexes and joins module entries to their library sections
    Then OV3 returns source-linked module rows and coverage counts or a named source finding
      | operation | path | equals |
      | read-python-library-sources.finish | $.status | SOURCE_CHANGED |
