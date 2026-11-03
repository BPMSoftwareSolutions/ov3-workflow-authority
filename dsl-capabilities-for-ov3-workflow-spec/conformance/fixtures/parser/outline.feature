# Parser fixture: each Examples row is one case. Examples tags apply to their own rows, and placeholders fill the
# step text, the docstring and the table cells.

@capability:fixture-outline
@scenario:fixture-outline
Feature: Each Examples row is one case

  Rule: Examples tags apply to their own rows

    @status:probe
    Scenario Outline: The request and the expected status come from the row
      Given a step for <who>
        """json
        {"who":"<who>"}
        """
      Then a result
        | operation | path     | equals   |
        | op        | $.status | <status> |

      @provider:sql-database-reader
      Examples: Read rows
        | case    | who   | status |
        | row-one | alpha | READ   |
        | row-two | beta  | READ   |

      Examples: Plain rows
        | case      | who   | status |
        | row-three | gamma | DONE   |
