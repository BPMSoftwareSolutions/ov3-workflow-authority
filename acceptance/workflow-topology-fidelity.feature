@capability:reveal-estate-workflows
@status:proposed-acceptance-not-executed
Feature: Faithful workflow discovery and projection
  As an estate reviewer
  I want admitted workflow entry points and execution routes shown without provider or product-edge contamination
  So that the rendered workflow retains canonical meaning

  Scenario: A physical identity provider cannot be a workflow root
    Given the inspected graph contains a DNR identity provider without an incoming visual arrow
    When workflow entries are resolved
    Then the provider is excluded from admitted workflow entries

  Scenario: An admitted entry with an inbound execution edge is still an entry
    Given a scenario is independently entry-admitted and is also reachable from another workflow
    When workflow entries are resolved
    Then that scenario remains an independently addressable workflow entry

  Scenario: Catalog curation does not launch browsing
    Given a definition-catalog product is consumed by a browsing capability
    When executable routes are resolved
    Then the product-only dependency is excluded from workflow progression

  Scenario: Attribute publication does not launch scientific comparison
    Given an attribute catalog feeds reveal-animal-knowledge as data
    When executable routes are resolved
    Then compare-wildlife-properties is not reachable by execution solely from that dependency

  Scenario: UI navigation is not a workflow execution transition
    Given a user interface provides a link from browse to record
    When executable routes are resolved
    Then the UI navigation relation is excluded from the execution graph

  Scenario: Declared transition preserves semantic address and progress
    Given an admitted scenario transition has canonical identity and semantic progress
    When the workflow lens is projected
    Then the projected edge retains the exact original identity and progress

  Scenario: Exclusive branches retain declared selecting variants
    Given an outcome has APPROVED and REJECTED branch variants
    When the workflow lens is projected
    Then exactly the declared variant-selected alternatives are represented

  Scenario: Required fan-out is not an exclusive decision
    Given a result fans out to two required obligations
    When workflow readiness is inspected
    Then both required members are preserved rather than one selected member

  Scenario: Multiple inbound arrows do not establish convergence
    Given two routes enter a candidate node without an admitted convergence requirement
    When workflow readiness is inspected
    Then the node is not presented as requiring both upstream results

  Scenario: Joint convergence uses only an admitted required product set
    Given a convergence input declares two required products
    When one required product is not admitted
    Then the convergence is not ready to execute

  Scenario: Provider invocation appears only under the event descent
    Given an event has a declared identity provider slot
    When its workflow and execution-altitude views are rendered
    Then the provider appears in the execution descent and not the scenario-route set

  Scenario: External webhook signals enter through an estate ingress scenario
    Given an external provider emits a role-change signal
    When an admitted role-change ingress scenario receives the signal
    Then the ingress scenario is the workflow entry and the provider is its input source

  Scenario: Multiple workflow entries share the same downstream scenario
    Given online and offline entries can each reach the same record-encounter scenario through admitted routes
    When both workflow lenses are projected
    Then each refers to the exact same recorded scenario identity

  Scenario: A locally held route does not erase an independent workflow
    Given one route contains an untyped execution edge and another admitted workflow is independent
    When the estate is inspected
    Then only the affected route is held and the independent workflow remains inspectable

  Scenario: Graph projections preserve canonical semantics
    Given one pinned authoritative workflow graph
    When JSON, Mermaid and ASCII lenses are projected
    Then all admitted root identities, route memberships, edge kinds, and variants agree

  Scenario: Expected fixtures are not observed execution
    Given a candidate fixture predicts that encounter registration succeeds
    When execution observation is requested without an actual execution receipt
    Then the experience is marked NOT_OBSERVED rather than EXECUTED

  Scenario: Restricted provider information is not revealed
    Given a viewer lacks permission for provider configuration details
    When workflow provider overlays are requested
    Then secrets and unauthorized configuration fields are excluded

  Scenario: Offline synchronization does not invent a registration route
    Given an offline capture and synchronization capability have no admitted transition to registration
    When workflow progression is discovered
    Then the registration edge is not inferred

  Scenario: Compatible provider replacement does not rewrite workflow topology
    Given a provider slot is rebound to an equally admitted physical provider
    When workflow roots and routes are compared across the two provider profiles
    Then the canonical scenario identities and route membership remain unchanged

  Scenario: Unknown execution edge topology fails closed
    Given a candidate execution edge lacks required topology or progress semantics
    When the workflow lens is resolved
    Then the edge is held with a source-attributable finding and is not drawn as execution
