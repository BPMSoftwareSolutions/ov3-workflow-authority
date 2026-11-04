@capability:publish-python-reuse-result
@root-scenario:publish-python-reuse-result
@scenario:publish-python-reuse-result
@input:publish-python-reuse-result-request
@input-contract:publish-python-reuse-result-request.v1
@event:publish-python-reuse-result-requested
@event-authority:publish-python-reuse-result.v1
@outcome:publish-python-reuse-result-outcome
@outcome-contract:python-reuse-publication.v1
@outcome-terminal
Feature: Publish a portable JSON manifest for an OV3 Python reuse benchmark

  @case:publish-notice
  @provider:sql-database-reader
  @provider:apply-declared-change
  Scenario: Read back the content-addressed manifest
    Given a specimen identity and the manifest values obtained by executing the Python operations
      """json
      {"specimen":"notice","text":"","byteCount":0,"base64":"","crc32":"00000000","sha256":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}
      """
    When OV3 publishes the JSON manifest through the declared content artifact writer
    Then it returns the digest of the retained bytes for independent verification against the objective
      | operation | path | equals |
      | publish-python-reuse-result.finish | $.status | COMPLETE |
      | publish-python-reuse-result.finish | $.specimen | notice |
