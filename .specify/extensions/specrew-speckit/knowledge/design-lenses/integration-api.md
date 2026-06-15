# Integration And API Lens

## Lens ID

`integration-api`

## Purpose

Make service boundaries, contracts, protocols, versioning, compatibility, and
message semantics explicit before implementation couples systems accidentally.

## Applicability Signals

- The feature calls or exposes an API, webhook, event, queue, file contract,
  plugin interface, generated SDK, CLI wrapper, or external dependency.
- Multiple clients, hosts, languages, or versions must interoperate.
- Backward compatibility, rate limits, retries, ordering, idempotency, or schema
  evolution matters.

## Design Decision Points

- What is the integration style: REST, GraphQL, gRPC, OData, RPC, events,
  pub/sub, queue, webhook, file contract, SDK, or direct library call?
- What owns the contract and how is it versioned?
- Are operations synchronous, asynchronous, streaming, or eventually consistent?
- Which requests are safe, idempotent, cacheable, or replayable?
- How are authentication, authorization, throttling, and API management handled?
- How are compatibility and schema evolution tested?

## Workshop Conduct

- **Diagram for this lens**: service interaction / contract sequence — render it as **console ASCII inline** so the human sees it in the conversation (a fenced mermaid block is source text, not a picture, on a terminal host); any mermaid/svg/html file is an *additional* artifact whose clickable `file:///` link you surface in the same message.
- **Facilitate, do not dictate**: raise the Design Decision Points above as a discussion, sequence the key contract interaction and agree the contract shape and error envelope, capture the human's decisions and explicit agreement, iterate until they say "move on", and record the agreement (never leave it only in the chat scrollback).
- **Re-invoke the `specrew-design-workshop` skill** before moving to the next lens.

## Question Bank

- Who are the producers and consumers?
- Is the contract data/message oriented or object/class oriented?
- What fields are required, optional, versioned, or deprecated?
- What happens on timeout, duplicate delivery, partial failure, or retry?
- Does the client need exactly-once behavior, at-least-once behavior, ordering,
  or compensation?
- Should clients generate from a contract, or should the server provide a SDK?
- What rate limits, auth scopes, and error shapes are needed?
- How does the system bridge old and new protocols during migration?

## Alternative Dimensions

- **Simplest**: direct call or local contract with documented assumptions.
- **Reasonable**: explicit schema/contract, versioning policy, compatibility
  tests, and retry/idempotency semantics.
- **By the book**: contract-first API, generated clients, API management,
  backward/forward compatibility matrix, event semantics, and migration plan.

## Plan Obligations

- Record protocol, contract owner, versioning, auth, retry, and compatibility.
- Identify producer/consumer tests and fixtures.
- Define error and timeout behavior.

## Validation Signals

- Contract tests cover both producer and consumer expectations.
- Review verifies idempotency and retry claims against implementation behavior.
- Compatibility claims are tested against old and new shapes where relevant.

## Source Notes

- Book Chapters 4 and 5.
- Course Module 5.
