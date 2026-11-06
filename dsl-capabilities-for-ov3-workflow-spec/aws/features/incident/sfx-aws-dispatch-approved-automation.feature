# sfx-aws-dispatch-approved-automation: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: ssm:StartAutomationExecution, ssm:GetAutomationExecution.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): DISPATCHED, NOT_DISPATCHED, REFUSED.
# Source reference IDs: AWS-SSM-01, AWS-SSM-02, AWS-SSM-03, AWS-SSM-04, AWS-SSM-06.
# Priority: P0.

@capability:sfx-aws-dispatch-approved-automation
@root-scenario:sfx-aws-dispatch-approved-automation
@scenario:sfx-aws-dispatch-approved-automation
@input:sfx-aws-dispatch-approved-automation-request
@input-contract:sfx-aws-dispatch-approved-automation-request.v1
@event:sfx-aws-dispatch-approved-automation-requested
@event-authority:sfx-aws-dispatch-approved-automation.v1
@outcome:sfx-aws-dispatch-approved-automation-outcome
@outcome-contract:sfx-aws-dispatch-approved-automation-result.v1
@outcome-terminal
Feature: Dispatch an approved AWS Automation runbook
  As a incident responder
  I want one attributable execution of an explicitly admitted runbook
  So that recovery is delegated to an AWS native operator under precise permission and idempotency

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Fixture: fixtures/cases/aws-dispatch-start.json (sha256:c8897136307518909299814ec68a83e6358b0e692e5f00e7726507faf4b9f674).
    # AWS: StartAutomationExecution answers only a 36-character AutomationExecutionId; the runbook's aws:approve step then holds the execution in Waiting (AWS-SSM-01, AWS-SSM-04).
    # Curated: ClientToken and execution id are UUIDs as the API requires; the status read back is Waiting, not the undocumented WaitingForApproval.
    @case:aws-dispatch-start
    @status:not-built
    Scenario: An authorized runbook is started once and returns an execution ID
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "clientToken": "b0cfbec5-3770-467c-93cc-c56a8a9b5d81"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-start is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.documentName | AWS-StartEC2InstanceWithApproval |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.executionId | 9ec30224-cda9-476e-8a45-506226b0a1d1 |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.status | Waiting |
        | sfx-aws-dispatch-approved-automation.dispatch | $.effect.completed | false |

    # Fixture: fixtures/cases/aws-dispatch-retry.json (sha256:5bb7afc2f4acb9894e35b1111c53372c1144322ff321729927161b8c1bdb7dbc).
    # AWS: A ClientToken can't be reused for another request; resending other parameters under it fails with IdempotentParameterMismatch (AWS-SSM-01).
    # Curated: SideFX answers from its own dispatch record and makes no second call.
    @case:aws-dispatch-retry
    @status:not-built
    Scenario: A repeated token does not create a second automation execution
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "clientToken": "b0cfbec5-3770-467c-93cc-c56a8a9b5d81"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-retry is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.executionId | 9ec30224-cda9-476e-8a45-506226b0a1d1 |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation.newDispatch | false |

    # Fixture: fixtures/cases/aws-dispatch-no-approval.json (sha256:f3fa78397362fbfebb4142d03966430c5d8cbbb231f13afc19c6699dce545937).
    # AWS: None.
    @case:aws-dispatch-no-approval
    @status:not-built
    Scenario: Without an approved effect identity no write is dispatched
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "clientToken": "53836648-e245-4aac-9753-258b6b0c2359"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-no-approval is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | EFFECT_NOT_AUTHORIZED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeAttempted | false |

    # Fixture: fixtures/cases/aws-dispatch-wrong-runbook.json (sha256:866533ec5a05442a8ae4d13c447625485d43af37de784aa8c926ccf101afa265).
    # AWS: AWS-StopEC2Instance is a documented AWS runbook (AWS-SSM-06).
    # Curated: AWS-StopEC2InstanceWithApproval is not on the AWS runbook pages read; the substitute is the documented AWS-StopEC2Instance.
    @case:aws-dispatch-wrong-runbook
    @status:not-built
    Scenario: The runbook cannot be substituted between approval and use
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StopEC2Instance",
          "documentVersion": "1",
          "clientToken": "94520ddf-92e4-46af-8dcf-7bddf66267ac"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-wrong-runbook is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | REFUSED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | RUNBOOK_BINDING_MISMATCH |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeAttempted | false |

    # Fixture: fixtures/cases/aws-dispatch-failure.json (sha256:c961a23fa9287e9a85081871350a91d956af8496d8b252fca2fd59e6ffa69595).
    # AWS: A caller without ssm:StartAutomationExecution gets AccessDeniedException.
    @case:aws-dispatch-failure
    @status:not-built
    Scenario: An AWS API failure is reported as not dispatched
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "clientToken": "27c4c886-c872-436e-ae2f-cc68799ee831"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-failure is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | AWS_DISPATCH_FAILED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.automation | (absent) |
        | sfx-aws-dispatch-approved-automation.dispatch | $.error.code | AccessDeniedException |

    # Fixture: fixtures/cases/aws-dispatch-unknown.json (sha256:61f3c8d27939423eb66be84c6614eaed1ebbb4fd0e61e9d4c41589ac318f1ea2).
    # AWS: A retry under the same ClientToken is the API's own idempotency (AWS-SSM-01); this case holds instead of retrying (decision A4 in CURATION.md).
    @case:aws-dispatch-unknown
    @status:not-built
    Scenario: An ambiguous timeout is reconciled before any retry write
      Given one authorized recovery effect and an immutable runbook binding
        """json
        {
          "accountId": "111122223333",
          "region": "us-east-2",
          "serviceId": "citizen-portal",
          "resourceArn": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
          "approvalId": "apr-001",
          "documentName": "AWS-StartEC2InstanceWithApproval",
          "documentVersion": "1",
          "clientToken": "3d69e34f-a8f2-4002-877c-965ad2b4e5af"
        }
        """
      And the pinned acceptance arrangement for aws-dispatch-unknown is established
      When the bounded AWS Automation dispatch is attempted
      Then the automation execution is addressable or a named non-dispatch prevents effect
        | operation | path | equals |
        | sfx-aws-dispatch-approved-automation.dispatch | $.status | NOT_DISPATCHED |
        | sfx-aws-dispatch-approved-automation.dispatch | $.reason | DISPATCH_CONFIRMATION_UNKNOWN |
        | sfx-aws-dispatch-approved-automation.dispatch | $.writeRetried | false |
