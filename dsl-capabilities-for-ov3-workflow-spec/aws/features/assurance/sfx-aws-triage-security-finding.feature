# sfx-aws-triage-security-finding: SideFX canonical feature candidate for cloud operations, curated 2026-11-03.
# Curated from sidefx-aws-cloud-operations (another pack, read only) against the AWS documentation in
#   aws/source/aws-documentation-manifest.json and the SideFX case format. Changes per case are in its comments; see aws/CURATION.md.
# Status: FEATURE CANDIDATE; NOT DECLARED, NOT BOUND, NOT LIVE-EXECUTED, NOT ESTATE-CONFORMANT.
# The ONE circuit scenario is declared by Feature-level tags; Scenario entries below are independent acceptance cases.
# Every case uses the EXACT same Given / When / Then primary steps, an own JSON request, and own result assertions.
# AWS calls of this circuit: none: EventBridge delivers Findings Imported V2 events to the SideFX intake.
# Each fixture records the SideFX records a case relies on and its AWS calls in the documented request and response shapes.
#   They are synthetic: built from the documentation, never captured from an AWS account.
# No @provider tag: the estate has no AWS-capable provider (688 capabilities read 2026-11-03, run 10c94fc9). http-exchange
#   carries a vault credential as a header and cannot sign AWS Signature Version 4. Decision A1 in aws/CURATION.md.
# Outcome variants (proposed): TRIAGED, DUPLICATE, NOT_OBSERVABLE, REFUSED.
# Source reference IDs: AWS-SH-01, AWS-SH-02, AWS-SH-03, AWS-IAM-01.
# Priority: P1.

@capability:sfx-aws-triage-security-finding
@root-scenario:sfx-aws-triage-security-finding
@scenario:sfx-aws-triage-security-finding
@input:sfx-aws-triage-security-finding-request
@input-contract:sfx-aws-triage-security-finding-request.v1
@event:sfx-aws-triage-security-finding-requested
@event-authority:sfx-aws-triage-security-finding.v1
@outcome:sfx-aws-triage-security-finding-outcome
@outcome-contract:sfx-aws-triage-security-finding-result.v1
@outcome-terminal
Feature: Triage an AWS security finding with attributable evidence
  As a security operations manager
  I want a prioritized cloud-security observation with safe next action
  So that findings are not mistaken for automatically authorized remediations

  Rule: The circuit yields an attributable outcome without assuming missing AWS proof

    # Fixture: fixtures/cases/aws-sec-high.json (sha256:f257e20fae96bf405e20e846df03c6b3e34b2e1302c5c1423dfee4268917c316).
    # AWS: One OCSF finding per Findings Imported V2 event, in detail.findings; metadata.uid is globally unique (AWS-SH-01, AWS-SH-02, AWS-SH-03).
    # Curated: The request is the delivered event, not a flattened summary, and the work item is keyed by metadata.uid.
    @case:aws-sec-high
    @status:not-built
    Scenario: A high severity finding becomes a classified security work item
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "event": {
            "version": "0",
            "id": "5c1ceba1-4b8b-4bde-bf55-2200a27700ef",
            "detail-type": "Findings Imported V2",
            "source": "aws.securityhub",
            "account": "111122223333",
            "time": "2026-11-03T00:12:00Z",
            "region": "us-east-2",
            "resources": [],
            "detail": {
              "findings": [
                {
                  "metadata": {
                    "uid": "a7ea6c99-a4fe-4852-b29c-a8c3448ac323",
                    "product": {
                      "uid": "aws-security-hub",
                      "name": "Security Hub"
                    }
                  },
                  "finding_info": {
                    "uid": "arn:aws:securityhub:us-east-2:111122223333:security-control/EC2.8/finding/0d4cf78b-cd4d-4b9e-bba2-385d1c13978a",
                    "title": "EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)",
                    "created_time_dt": "2026-11-03T00:12:00Z",
                    "modified_time_dt": "2026-11-03T00:12:00Z"
                  },
                  "cloud": {
                    "provider": "AWS",
                    "region": "us-east-2",
                    "account": {
                      "uid": "111122223333"
                    }
                  },
                  "severity": "High",
                  "severity_id": 4,
                  "status": "New",
                  "resources": [
                    {
                      "uid": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
                      "type": "AWS::EC2::Instance"
                    }
                  ]
                }
              ]
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-sec-high is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | TRIAGED |
        | sfx-aws-triage-security-finding.triage | $.workItem.findingId | a7ea6c99-a4fe-4852-b29c-a8c3448ac323 |
        | sfx-aws-triage-security-finding.triage | $.workItem.severity | HIGH |
        | sfx-aws-triage-security-finding.triage | $.automaticRemediation | false |

    # Fixture: fixtures/cases/aws-sec-duplicate.json (sha256:804758345a60a9b52f887321f065ea7fc77647d9228dc3e9261064d6703cf8ca).
    # AWS: Every update to a finding sends another Findings Imported V2 event for it (AWS-SH-01).
    @case:aws-sec-duplicate
    @status:not-built
    Scenario: A repeated finding update is not a new issue by default
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "event": {
            "version": "0",
            "id": "ef5b1bca-8756-417c-8114-8eddb1ee3af3",
            "detail-type": "Findings Imported V2",
            "source": "aws.securityhub",
            "account": "111122223333",
            "time": "2026-11-03T00:18:00Z",
            "region": "us-east-2",
            "resources": [],
            "detail": {
              "findings": [
                {
                  "metadata": {
                    "uid": "a7ea6c99-a4fe-4852-b29c-a8c3448ac323",
                    "product": {
                      "uid": "aws-security-hub",
                      "name": "Security Hub"
                    }
                  },
                  "finding_info": {
                    "uid": "arn:aws:securityhub:us-east-2:111122223333:security-control/EC2.8/finding/0d4cf78b-cd4d-4b9e-bba2-385d1c13978a",
                    "title": "EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)",
                    "created_time_dt": "2026-11-03T00:18:00Z",
                    "modified_time_dt": "2026-11-03T00:18:00Z"
                  },
                  "cloud": {
                    "provider": "AWS",
                    "region": "us-east-2",
                    "account": {
                      "uid": "111122223333"
                    }
                  },
                  "severity": "High",
                  "severity_id": 4,
                  "status": "New",
                  "resources": [
                    {
                      "uid": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
                      "type": "AWS::EC2::Instance"
                    }
                  ]
                }
              ]
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-sec-duplicate is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | DUPLICATE |
        | sfx-aws-triage-security-finding.triage | $.newWorkItem | false |

    # Fixture: fixtures/cases/aws-sec-cross-account.json (sha256:7d5e02636842c6fb86168db9e1d07a6c14fb7a721c02cd609131bbfdacabbec6).
    # AWS: An administrator's feed carries member accounts' findings; the finding's own account is cloud.account.uid (AWS-SH-01, AWS-SH-03).
    # Curated: The envelope comes from the admitted administrator account while the finding belongs to 999988887777, the realistic shape of this refusal.
    @case:aws-sec-cross-account
    @status:not-built
    Scenario: A foreign account finding cannot enter the estate
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "event": {
            "version": "0",
            "id": "e40c076a-3282-4083-baac-6a9ffe755fe3",
            "detail-type": "Findings Imported V2",
            "source": "aws.securityhub",
            "account": "111122223333",
            "time": "2026-11-03T00:12:00Z",
            "region": "us-east-2",
            "resources": [],
            "detail": {
              "findings": [
                {
                  "metadata": {
                    "uid": "b58a73d0-bbd8-4101-b404-d02f311ca11b",
                    "product": {
                      "uid": "aws-security-hub",
                      "name": "Security Hub"
                    }
                  },
                  "finding_info": {
                    "uid": "arn:aws:securityhub:us-east-2:111122223333:security-control/EC2.8/finding/30242701-a0c8-492f-807d-a66e7fb53ca8",
                    "title": "EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)",
                    "created_time_dt": "2026-11-03T00:12:00Z",
                    "modified_time_dt": "2026-11-03T00:12:00Z"
                  },
                  "cloud": {
                    "provider": "AWS",
                    "region": "us-east-2",
                    "account": {
                      "uid": "999988887777"
                    }
                  },
                  "severity": "High",
                  "severity_id": 4,
                  "status": "New",
                  "resources": [
                    {
                      "uid": "arn:aws:ec2:us-east-2:999988887777:instance/i-0123456789abcdef0",
                      "type": "AWS::EC2::Instance"
                    }
                  ]
                }
              ]
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-sec-cross-account is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | REFUSED |
        | sfx-aws-triage-security-finding.triage | $.reason | FINDING_ACCOUNT_NOT_ADMITTED |

    # Fixture: fixtures/cases/aws-sec-v1v2.json (sha256:7222aab7ed0fe042408568bb34c13061f3a49fe549e4f6d341dc045fdccc346b).
    # AWS: Security Hub and Security Hub CSPM both publish on source aws.securityhub; AWS says to match the Security Hub detail-type to avoid duplicates (AWS-SH-01).
    # Curated: The candidate's abstract 'sameCanonicalFinding' becomes the documented rule: the CSPM detail-type is a second stream, not a second finding.
    @case:aws-sec-v1v2
    @status:not-built
    Scenario: The Security Hub CSPM copy of a finding is not counted twice
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "event": {
            "version": "0",
            "id": "d6427714-bc24-4e7e-a77b-374150d1ef5d",
            "detail-type": "Security Hub Findings - Imported",
            "source": "aws.securityhub",
            "account": "111122223333",
            "time": "2026-11-03T00:12:00Z",
            "region": "us-east-2",
            "resources": [
              "arn:aws:securityhub:us-east-2:111122223333:security-control/EC2.8/finding/0d4cf78b-cd4d-4b9e-bba2-385d1c13978a"
            ],
            "detail": {
              "findings": [
                {
                  "SchemaVersion": "2018-10-08",
                  "Id": "arn:aws:securityhub:us-east-2:111122223333:security-control/EC2.8/finding/0d4cf78b-cd4d-4b9e-bba2-385d1c13978a",
                  "ProductArn": "arn:aws:securityhub:us-east-2::product/aws/securityhub",
                  "AwsAccountId": "111122223333",
                  "Severity": {
                    "Label": "HIGH"
                  },
                  "Resources": [
                    {
                      "Type": "AwsEc2Instance",
                      "Id": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0"
                    }
                  ],
                  "Workflow": {
                    "Status": "NEW"
                  },
                  "RecordState": "ACTIVE"
                }
              ]
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-sec-v1v2 is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | DUPLICATE |
        | sfx-aws-triage-security-finding.triage | $.newWorkItem | false |
        | sfx-aws-triage-security-finding.triage | $.reason | SECURITY_HUB_CSPM_STREAM |

    # Fixture: fixtures/cases/aws-sec-missing-resource.json (sha256:35aa2b2cee2940a5a035d22e2fd42abf9bc68c771e452a85390637014d4146a4).
    # AWS: The OCSF finding's resources list is empty (AWS-SH-02).
    @case:aws-sec-missing-resource
    @status:not-built
    Scenario: A finding with no attributable resource is left unobserved
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "event": {
            "version": "0",
            "id": "9c8e2d96-3ded-4ca7-b24b-60ddef713e2d",
            "detail-type": "Findings Imported V2",
            "source": "aws.securityhub",
            "account": "111122223333",
            "time": "2026-11-03T00:12:00Z",
            "region": "us-east-2",
            "resources": [],
            "detail": {
              "findings": [
                {
                  "metadata": {
                    "uid": "0894938d-f2b8-4141-8c2e-62e596aa21c1",
                    "product": {
                      "uid": "aws-security-hub",
                      "name": "Security Hub"
                    }
                  },
                  "finding_info": {
                    "uid": "arn:aws:securityhub:us-east-2:111122223333:security-control/EC2.8/finding/4a951a9e-14f6-4bcf-8b7e-78783592b417",
                    "title": "EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)",
                    "created_time_dt": "2026-11-03T00:12:00Z",
                    "modified_time_dt": "2026-11-03T00:12:00Z"
                  },
                  "cloud": {
                    "provider": "AWS",
                    "region": "us-east-2",
                    "account": {
                      "uid": "111122223333"
                    }
                  },
                  "severity": "High",
                  "severity_id": 4,
                  "status": "New",
                  "resources": []
                }
              ]
            }
          }
        }
        """
      And the pinned acceptance arrangement for aws-sec-missing-resource is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | NOT_OBSERVABLE |
        | sfx-aws-triage-security-finding.triage | $.reason | RESOURCE_BINDING_MISSING |

    # Fixture: fixtures/cases/aws-sec-no-auto-write.json (sha256:2efb60f7b33cf741c42740d56935c1d24bffe3fabb8c2aa141515bf3f39ac011).
    # AWS: severity_id 5 is Critical (AWS-SH-03).
    @case:aws-sec-no-auto-write
    @status:not-built
    Scenario: Even a critical finding cannot create a deletion without authority
      Given a supported AWS Security Hub finding and authorized security scope
        """json
        {
          "event": {
            "version": "0",
            "id": "4d281efb-8caa-49c0-be1f-5ceda666fe78",
            "detail-type": "Findings Imported V2",
            "source": "aws.securityhub",
            "account": "111122223333",
            "time": "2026-11-03T00:12:00Z",
            "region": "us-east-2",
            "resources": [],
            "detail": {
              "findings": [
                {
                  "metadata": {
                    "uid": "cce44d98-35f3-4b53-a5ef-5fdc3bb2ebb7",
                    "product": {
                      "uid": "aws-security-hub",
                      "name": "Security Hub"
                    }
                  },
                  "finding_info": {
                    "uid": "arn:aws:securityhub:us-east-2:111122223333:security-control/EC2.8/finding/7267b8aa-f5c7-4b49-953b-946fba31ca1f",
                    "title": "EC2 instances should use Instance Metadata Service Version 2 (IMDSv2)",
                    "created_time_dt": "2026-11-03T00:12:00Z",
                    "modified_time_dt": "2026-11-03T00:12:00Z"
                  },
                  "cloud": {
                    "provider": "AWS",
                    "region": "us-east-2",
                    "account": {
                      "uid": "111122223333"
                    }
                  },
                  "severity": "Critical",
                  "severity_id": 5,
                  "status": "New",
                  "resources": [
                    {
                      "uid": "arn:aws:ec2:us-east-2:111122223333:instance/i-0123456789abcdef0",
                      "type": "AWS::EC2::Instance"
                    }
                  ]
                }
              ]
            }
          },
          "proposedAction": "delete-resource"
        }
        """
      And the pinned acceptance arrangement for aws-sec-no-auto-write is established
      When the finding is deduplicated and classified against approved policy
      Then an owned security work item is available or a named non-admission explains the absence
        | operation | path | equals |
        | sfx-aws-triage-security-finding.triage | $.status | TRIAGED |
        | sfx-aws-triage-security-finding.triage | $.automaticRemediation | false |
        | sfx-aws-triage-security-finding.triage | $.workItem.requiresReview | true |
