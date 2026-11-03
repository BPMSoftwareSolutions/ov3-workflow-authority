# Cloud operations architectural decisions and assumptions

- **D01.** All proposed AWS cloud-operation capability/contract/operation IDs and outcome variants are candidates. No live SideFX declaration is assumed.
- **D02.** Source event identity is the native EventBridge ID plus trusted routing context, with a stable idempotency identity across replay. Confirm actual identity key and retention profile.
- **D03.** Read-only cross-account inventory via scoped STS role and Config aggregator, never a blanket management-account admin role.
- **D04.** The root scenario treats a demonstrated cloud-service recovery as independent post-action state/SLI proof; SSM SUCCESS alone is never sufficient.
- **D05.** Approvals must bind action, target, actor, effective window, and policy version; native AWS runbook approval is a second independently observed state.
- **D06.** Retry/ambiguous dispatch follows provider API idempotency and actual read-back; no blind second write.
- **D07.** Root incident final variants are RESTORED/ESCALATED/HELD/REFUSED, distinct from internal operation statuses.
- **D08.** Cost comparison is read-only, limited by billing coverage, expense attribution, as-of date and currency; not savings or forecasts.
- **D09.** Recovery readiness is verified against measured restore tests; config/backup completion alone is not restoration proof.
- **D10.** Security Hub V2 and legacy event streams are normalized by canonical finding identity, avoiding duplicate work items.
- **D11.** No deployment topology is declared by a feature name. AWS suppliers are proposed through provider requirements, not hard-coded kernel logic.
- **D12.** All cases and requests are synthetic fixtures. An operator cannot submit trusted subject, IAM role, approval or AWS telemetry as self-authored truth.
- **D13.** P0 interview slice is an EC2 stop/start recovery example, illustrative of a broader Cloud Operations role rather than representative of all workload topologies.
- **D14.** Health API organizational data is optional: some calls depend on AWS Support plan and endpoint; absence is a coverage finding.
- **D15.** An incident can be escalated without asserting recovery. This is legitimate operational governance, not a successful restore.
- **D16.** Fixture JSON schema and result paths are proposed test-bridge contracts; no new SideFX kernel, database schema, or provider has been installed.

A decision recorded here does not become platform authority merely because this package exists. Confirm candidate decisions against the current estate and interview discussion before admission.
