---
proposal: 163
title: Code & Implementation Lens (implementation-craft decisions in the design workshop)
status: candidate
phase: phase-2
estimated-sp: 6-9 (record-only V1; analyzer-backed enforcement deferred)
priority-tier: 2
discussion: surfaced 2026-06-05 by the maintainer during the testLenses8 / testLenses11 cross-host workshop dogfooding (the wrong-keyboard-layout .NET 10 utility). The 9 design lenses cover WHAT the system is; none covers HOW the code is written. Research update 2026-06-08 completed the stack/tooling baseline and recommends a record-only V1: workshop records implementation-craft rules as grouped baseline defaults, decision prompts, applicability-filtered rules, and enforcement modes; the rule manifest feeds Proposal 156's broader workshop-decisions.yml producer artifact; plan/implement/review consume it; and ecosystem analyzers/formatters plus Proposal 145 verify every selected rule rather than Specrew inventing a parallel quality gate.
---

# Code & Implementation Lens (implementation-craft decisions in the design workshop)

## Why

The design-workshop lens catalog has 9 lenses — architecture-core, component-design, requirements-nfr, ui-ux,
data-storage, security-compliance, integration-api, devops-operations, observability-resilience. Every one of
them is about **what the system is**: its structure, its decomposition, its quality attributes, its data, its
trust boundaries, its surfaces. **None covers *how the code is written* — the implementation craft.** Those
decisions (language version, how util code is packaged, whether DI is used, file and function size discipline,
comment policy) are real, consequential, and stack-specific, and today they are made ad-hoc during `implement`
rather than decided with the human up front like every other design dimension.

The maintainer named the gap concretely (testLenses8/11 intake of a .NET 10 utility): the use of programming-
language constructs; the length of files / functions / lines; the amount of comments in code; the use of
dependency injection, builder, and other design patterns; using the latest version of the language; how to
package a utility class (NuGet package vs. a referenced project); and the fact that **each language and
platform has different dilemmas**.

2026-06-06 refinement: this is also the right home for **refactor-prevention by design**. Specrew
should not wait until a project needs a large refactor to ask maintainability questions. The lens
should surface implementation-architecture choices early enough to bind the plan and review:

- **OCP / extension posture**: should this change be added through a plugin, rule file, adapter,
  configuration row, or helper module instead of editing a central dispatcher?
- **Cohesion and coupling norms**: what module boundaries, dependency direction, and public API
  shape are expected for this stack and project size?
- **Size and complexity discipline**: file, class, function, method, line-length, and cognitive
  complexity thresholds, preferably mapped to ecosystem tools rather than invented checks.
- **Pattern posture**: when DI, builder, strategy, factory, middleware, command, or pipeline
  patterns are expected, optional, or discouraged.
- **Analyzer/tool binding**: which existing tools (`.editorconfig`, Roslyn analyzers, ESLint,
  ruff, mypy, gofmt/golangci-lint, etc.) should enforce the chosen conventions.
- **Review evidence**: how the reviewer proves the code followed the recorded conventions instead
  of accepting an agent's report at face value.

## What (research conclusion)

A 10th design lens, `code-implementation` (working name), that the workshop surfaces alongside the others and
that captures implementation-craft decisions as **binding constraints for the implement phase** — the same way
architecture-core captures the decomposition style.

The V1 shape should be **record-only, tool-aware**:

- the lens asks only design-time implementation-craft questions that materially affect plan/implementation;
- the answers are recorded in `lens-applicability.json`, the per-lens workshop
  file, and the Proposal 156 `workshop-decisions.yml` manifest;
- `plan.md` converts the answers into implement constraints and review obligations;
- implementation follows those constraints using the project's normal stack tooling;
- review validates conformance through Proposal 145 Phase 4, analyzer/test evidence, and design/code trace;
- Specrew does **not** add a new deterministic code-quality gate in V1.

V1 decision points:

- Target language **version** and which modern constructs are in/out (e.g., C# records / file-scoped namespaces;
  TS strictness; Python typing).
- **Dependency injection** and **design-pattern** posture (DI container vs. manual composition; where builder /
  factory / strategy patterns are expected vs. discouraged).
- **Size discipline**: file / function / method length norms and the cognitive-complexity bar.
- **Comment policy**: how much, what kind (intent vs. narration), per [074 commentary standards](074-code-commentary-standards.md).
- **Packaging** of shared/util code: NuGet package vs. project reference vs. internal shared assembly — and the
  equivalent decision in other ecosystems.
- **Per-stack / per-platform dilemmas**: the right defaults differ by C#/.NET, TS/JS, Python, Go, Java, etc.
- **Refactor-prevention posture**: central-hub edit vs helper-module extraction, OCP/default
  extension seam, explicit cohesion/coupling expectations, and when a local change must become a
  reusable module.
- **Public API / reusable-code design posture**: naming, member shape,
  extensibility, exception behavior, and versioning compatibility for any code
  meant to be consumed by other modules, projects, or users.
- **Maintainer default implementation posture**: naming, short methods,
  low-nesting flow, dependency injection, DTO/ACL boundaries, object invariants,
  encapsulation/copy semantics, immutability, configuration, observability,
  robustness, testing, and performance posture.
- **Source-backed cross-language craft defaults**: call-site API clarity,
  stronger domain types, invariant-preserving object models, explicit extension
  points, normalized state, pure render code, event-loop discipline, secure
  defaults, code-level authorization, security-context propagation, and
  documentation/examples as an API design test.
- **Client/service interaction posture**: validation placement, write-conflict
  semantics, collection query ownership and pagination, protocol choice,
  messaging/event-processing style, caching/state-sharing boundaries,
  cloud-native project maturity, technology-enabler shortlist, and
  rendering/hosting model.

## Decision: record-only V1, analyzer-backed enforcement later

The research answer is **record-only V1**.

The lens decides the conventions with the human. It does not itself enforce
them mechanically. Enforcement belongs to the stack's own tooling and to review:

- C#/.NET: `.editorconfig`, .NET code style/quality analyzers, compiler
  language-version settings, nullable/implicit-usings settings, and DI guidance.
- C/C++: language standard/toolchain posture, Google/C++ Core Guidelines/LLVM or
  domain style baseline, clang-format/clang-tidy/analyzer, compiler warnings,
  sanitizers, CERT/MISRA safety posture when relevant, and ABI/header boundary
  discipline.
- TypeScript/JavaScript: `tsconfig`, ESLint, `typescript-eslint`, Prettier, and
  package/workspace policy.
- Python: `pyproject.toml` configuration for ruff, Black, mypy, and package
  layout.
- Go: `gofmt`/`go fmt`, `go vet`, `golangci-lint`, modules, and idiomatic Go
  package boundaries.
- Java: build-tool source/target or toolchain settings, formatter, Checkstyle,
  PMD, SpotBugs, and dependency/module boundaries.
- Cross-stack reusable-code/API design: use the .NET Framework Design
  Guidelines as a transferable source for naming, member design, extensibility,
  exception behavior, and versioning judgment; adapt the concepts to the local
  stack idioms instead of copying .NET names literally.
- Client/service/UI stacks: bind validation placement, protocol,
  rendering/hosting, messaging/event-processing, concurrency, pagination, and
  state-management/caching decisions through the target framework's normal
  controls, platform enablers, ecosystem maturity signals, and API guidelines.

An enforced mode can be proposed later, but it should configure and require
those ecosystem mechanisms rather than adding a Specrew-specific parallel code
quality engine.

## Research update — stack and tooling baseline (2026-06-08)

The research conclusion is that the lens should recommend **established
ecosystem control points** and avoid invented universal thresholds. Stack
defaults differ enough that the workshop should ask for the resolved stack,
then present stack-specific defaults.

### Decision-point filter

A question belongs in the lens only when the answer changes implementation
shape, planning, review evidence, or human expectations. The lens should not ask
about every lint rule.

Keep in the lens:

- language/runtime version posture (latest, LTS/current, project baseline);
- modern construct posture (prefer, allow, avoid for portability);
- typing/nullability/strictness posture;
- composition and DI posture;
- shared-code packaging posture;
- public API/reusable-code posture: naming, members, exceptions,
  extensibility, compatibility, and versioning;
- file/module/class/function size and complexity posture;
- comment/documentation posture, delegated to Proposal 074 vocabulary;
- formatter/linter/analyzer binding;
- OCP/extension posture and central-hub-edit waiver rule.

Leave to tooling/review defaults unless the project has a special need:

- individual whitespace preferences;
- exact ordering/import trivia where formatters own the answer;
- arbitrary numeric limits that are not backed by stack tooling or local
  convention;
- style preferences with no impact on maintainability, compatibility, or review
  evidence.

### Cross-stack API and reusable-code design

The Microsoft Framework Design Guidelines are .NET-specific in origin, but they
are not useful only for .NET and not useful only for libraries. They are a strong
source for the part of this lens that asks how reusable code should be shaped.

Transferable topics:

- naming consistency for things humans call from other code;
- member and parameter design: what belongs in a method, constructor, property,
  option object, builder, or factory;
- extensibility: when to design for overrides, callbacks, plugins, events,
  composition, or configuration instead of central edits;
- exception and error behavior: what errors mean, where they are raised, and how
  callers reason about them;
- versioning/compatibility: what changes are source/binary/API breaking in the
  project context;
- dependency surface hygiene: what types and packages become part of the
  consumer contract.

The cross-stack rule is: borrow the **questions and design pressure**, not the
literal .NET answers. For example, "properties vs methods" maps directly in C#,
partially in Java/TypeScript, and indirectly in Python/Go; "exceptions" maps to
error returns in Go and typed/result-style conventions in some TypeScript or
Rust-like codebases. The lens should adapt vocabulary per stack while preserving
the underlying design concern.

This also widens the lens beyond published libraries. Any internal helper,
engine, accessor, module, CLI command, plugin contract, generated-code API, or
test-support package that has more than one caller is consuming-code-facing and
should answer the reusable-code/API questions at the right depth.

Sources:

- <https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/>
- <https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/member>
- <https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/designing-for-extensibility>
- <https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/exceptions>

### C# / .NET

Design-time dilemmas:

- target framework and C# language-version posture: use the TFM default, pin an
  explicit language version, or deliberately allow preview/latest;
- nullable reference types, implicit usings, file-scoped namespaces, records,
  primary constructors, collection expressions, top-level statements, and
  minimal APIs;
- DI container vs manual composition root for small utilities;
- extension method/helper/internal project/NuGet package split for shared code;
- analyzer severity posture and whether style warnings can fail CI.

Tooling bindings:

- `.editorconfig` for style preferences and severity;
- .NET analyzers for quality rules;
- project file language-version/nullability/implicit-usings settings;
- dependency-injection guidelines when DI is part of the stack.

Research posture: the lens should **not** blindly say "latest C#". Microsoft
documents language version as tied to target framework by default, and using
`latest` can make builds sensitive to compiler updates. The design question is
therefore "TFM default vs pinned vs preview/latest", not "always latest".

Sources:

- <https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version>
- <https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview>
- <https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/code-style-rule-options>
- <https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection-guidelines>

### C / C++

C and C++ need their own section because implementation-craft decisions are
often product-shaping: ABI stability, headers, ownership, exceptions, undefined
behavior, compiler/toolchain portability, embedded constraints, and
safety/security profiles can dominate the design.

Design-time dilemmas:

- language standard posture: C11/C17/C23 or C++17/20/23/26, and whether
  compiler extensions are allowed;
- toolchain/ABI posture: GCC/Clang/MSVC, cross-compilation, public C ABI,
  binary compatibility, exported symbols, and header hygiene;
- ownership/lifetime posture: RAII and smart pointers in C++, explicit
  allocation/freeing conventions in C, borrowing/ownership annotations where
  local standards support them;
- exceptions/RTTI/templates/macros posture: allowed, restricted, or banned for
  portability, embedded, ABI, or readability reasons;
- include and module boundaries: header-only vs compiled library, `pimpl`,
  include-what-you-use discipline, C++ modules when applicable;
- safety profile: ordinary application, systems/performance, embedded,
  safety-critical, or security-sensitive;
- warning and sanitizer posture: which warnings fail CI, which sanitizers or
  static analyzers are required locally/CI.

Tooling bindings:

- clang-format for formatting;
- clang-tidy and compiler warnings for modernize/performance/readability/safety
  checks;
- clang static analyzer, sanitizers, Cppcheck, or equivalent project tools for
  memory/UB/concurrency evidence;
- CMake/toolchain files/compile commands or the project's build system for
  standard, warning, and analyzer integration;
- CERT C/C++ and MISRA C/C++ when security, embedded, automotive, medical, or
  safety-critical posture applies.

Research posture: Google C++ Style Guide is a strong practical default for many
C++ projects, but it is not universal. The C++ Core Guidelines are broader and
more principle-driven. LLVM's standards are useful for compiler/tooling-scale
C++ and low-level library code. GNU Coding Standards matter for GNU-style C
projects. CERT and MISRA shift the lens from style to safety/security. The
workshop should pick the baseline that matches the product, not blend them
uncritically.

Sources:

- <https://google.github.io/styleguide/cppguide.html>
- <https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines>
- <https://llvm.org/docs/CodingStandards.html>
- <https://clang.llvm.org/docs/ClangFormat.html>
- <https://clang.llvm.org/extra/clang-tidy/>
- <https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard>
- <https://www.gnu.org/prep/standards/standards.html>

### TypeScript / JavaScript

Design-time dilemmas:

- TypeScript strictness (`strict`, `noImplicitAny`, null checks, optional
  property exactness) vs gradual adoption;
- ESM/CJS/module-resolution posture;
- functional/OO style expectations, class vs object/function modules;
- framework-specific patterns (React hooks, backend middleware, monorepo
  workspaces);
- Prettier-as-formatter vs ESLint style rules;
- typed linting where type-aware rules justify the cost.

Tooling bindings:

- `tsconfig.json` for compiler and strictness choices;
- ESLint flat config for JavaScript/TypeScript rules;
- `typescript-eslint` for TypeScript-aware and type-aware linting;
- Prettier for formatting;
- package/workspace manifests for packaging and shared utilities.

Research posture: V1 should recommend `strict` as the default for greenfield TS,
but still make it an explicit workshop choice for legacy migration or generated
code. Formatting belongs to Prettier or the chosen formatter; code-quality
semantics belong to ESLint/typed linting and review.

Sources:

- <https://www.typescriptlang.org/tsconfig/#strict>
- <https://typescript-eslint.io/getting-started/typed-linting/>
- <https://eslint.org/docs/latest/use/configure/configuration-files>
- <https://prettier.io/docs/en/why-prettier>

### Python

Design-time dilemmas:

- Python version floor and syntax posture (pattern matching, modern typing,
  dataclasses, `pathlib`, async);
- type-checking posture (none, gradual, strict for core modules);
- package layout (`src/` layout vs flat, internal module vs package);
- lint/format ownership split: ruff-only format/lint vs Black + ruff;
- docstring/comment posture and public API documentation level;
- complexity thresholds and dynamic-code exceptions.

Tooling bindings:

- `pyproject.toml` as the central config surface;
- ruff for linting and optionally formatting;
- Black where the project uses Black as formatter;
- mypy for type checking;
- PEP 8 as the baseline style reference, mediated by tooling.

Research posture: the lens should prefer tool-backed decisions. For example,
"typed public API and core logic, gradual elsewhere" is a useful design choice;
"exactly N comments" is not.

Sources:

- <https://docs.astral.sh/ruff/configuration/>
- <https://black.readthedocs.io/en/stable/the_black_code_style/current_style.html>
- <https://mypy.readthedocs.io/en/stable/config_file.html>
- <https://peps.python.org/pep-0008/>

### Go

Design-time dilemmas:

- minimum Go version and module/toolchain posture;
- idiomatic small interfaces and package boundaries vs over-layered DI;
- error handling and context propagation norms;
- package layout for internal/shared code;
- generated-code and concurrency conventions;
- whether extra lint beyond `go vet` is required.

Tooling bindings:

- `gofmt`/`go fmt` for formatting;
- `go vet` for suspicious constructs;
- `golangci-lint` for multi-linter policy when needed;
- Go modules and `internal/` package boundaries.

Research posture: Go is the strongest case for "do not invent style rules".
Formatting is canonicalized by `gofmt`; the design lens should focus on package
boundaries, version/toolchain, concurrency/error-handling posture, and whether
extra lint is worth the maintenance cost.

Sources:

- <https://go.dev/doc/effective_go#formatting>
- <https://pkg.go.dev/cmd/gofmt>
- <https://pkg.go.dev/cmd/vet>
- <https://golangci-lint.run/docs/configuration/file/>

### Java

Design-time dilemmas:

- Java version/LTS baseline and preview-feature posture;
- module system vs conventional packages;
- DI/framework posture (Spring/CDI/manual), builder/factory usage, records and
  sealed classes where available;
- package boundaries for shared utilities and public APIs;
- formatting and static-analysis stack;
- nullness and immutability posture where project tooling supports it.

Tooling bindings:

- build tool source/target/toolchain settings;
- formatter such as google-java-format where adopted;
- Checkstyle for style/convention rules;
- PMD and SpotBugs for static analysis / bug patterns;
- framework-specific analyzers where relevant.

Research posture: Java varies strongly by framework and organization. V1 should
offer a small baseline (version, package/module posture, DI/pattern posture,
formatter/static-analysis binding) and avoid pretending there is a universal
Java style gate.

Sources:

- <https://checkstyle.org/config.html>
- <https://spotbugs.readthedocs.io/en/stable/introduction.html>
- <https://pmd.github.io/pmd/pmd_userdocs_getting_started.html>
- <https://github.com/google/google-java-format>

### Cross-stack conclusion

The lens should have one common question spine and stack-specific prompts:

1. What language/runtime baseline are we binding?
2. What modern constructs are preferred, allowed, or avoided?
3. What typing/nullability/strictness posture applies?
4. What composition/pattern posture applies?
5. How should shared code be packaged?
6. What reusable-code/API design posture applies?
7. What object-model invariant, encapsulation, and copy semantics apply?
8. What size/complexity/comment policy applies?
9. What formatter/linter/analyzer owns enforcement?
10. What OCP/extension posture prevents future refactor pressure?
11. What code-level authorization and security-context posture applies?
12. What client/service interaction posture applies?
13. What messaging/event-processing and coordination posture applies?
14. What cache/state-sharing posture applies, and what must not use cache/DB?
15. Which stack/platform enablers should be considered, and which are ruled out?
16. What observability, robustness, testing, and performance posture applies?

The proposal is now ready for spec conversion as a record-only lens. Enforced
mode remains a follow-up once the lens has real dogfood data.

### Rule grouping and consumption model

The rule set is intentionally larger than what the workshop should ask directly.
The lens should classify rules before presentation so humans see only material
choices, while implementation and review still receive a complete manifest:

- **Baseline defaults**: best-practice rules that normally apply without a
  dilemma. Examples: intent-revealing names, short functions, low nesting,
  guarding invariants, not leaking mutable internals, bounded retries, no magic
  numbers, and idiomatic error handling. The workshop should state these as the
  project baseline and ask only for exceptions.
- **Decision prompts**: rules whose answer changes performance, complexity,
  maintainability, user experience, operational behavior, or coupling. Examples:
  lock-free vs. lock-based concurrency, deep copy vs. shallow copy, client/server
  pagination semantics, REST vs. gRPC vs. GraphQL vs. events, cache posture,
  TDD posture, and analyzer severity. These are surfaced to the human.
- **Applicability-filtered rules**: stack, framework, domain, or platform rules
  that are irrelevant unless the feature uses that context. Examples:
  C++ ownership/safety profiles, React render purity, ASP.NET authorization
  attributes, WebAssembly rendering, CNCF maturity disclosure, or provider cloud
  architecture packs.
- **Enforcement mode**: the evidence mechanism selected for each rule. Examples:
  compiler/language version, formatter, analyzer/linter, unit/integration tests,
  approval tests, design artifact, runtime policy, review-only judgment, or
  documented exception.

The lens output should therefore include a machine-readable
`implementation-rules.yml` (or equivalent section in the lens record), not only
prose. That output is a feed into Proposal 156's broader
`workshop-decisions.yml` producer manifest; it is not a standalone verification
universe. `plan.md` consumes the selected rules as implement constraints,
implementation follows them, and Proposal 145 validates them as part of
`workshop-decision-conformance.yml` at review-signoff.

Example shape:

```yaml
rules:
  - id: object-invariants
    group: baseline-default
    applies: true
    default: "Class owns invariants; guard mutation; do not leak mutable internals."
    decision_needed: false
    enforcement: [review, unit-tests]
  - id: copy-semantics
    group: decision-prompt
    applies: true
    decision: "Use DTO projection across service boundaries; shallow copy internally."
    tradeoffs: [performance, decoupling, identity, versioning]
    enforcement: [plan, review]
  - id: react-render-purity
    group: applicability-filtered
    applies: false
    applicability_reason: "Feature has no React/client render surface."
    enforcement: [n/a]
```

The review-side status vocabulary is `satisfied`, `violated`, `n/a-with-reason`,
or `accepted-exception`. An accepted exception must point to the artifact that
records the new decision or variance, so rule drift is visible instead of
silently becoming the new plan.

The code-lens rule IDs must be stable enough to survive from workshop through
plan, tasks, implementation, and review. For example,
`code-rule.object-invariants` in `workshop-decisions.yml` should be the same
decision key that appears in plan obligations, task notes, analyzer evidence,
and `workshop-decision-conformance.yml`.

### Maintainer default implementation posture

These are the maintainer's default code rules. The future lens should present
them as the starting baseline and ask only where the stack, product, or
constraint justifies an exception.

1. **Names carry design intent.** Find the best descriptive name for files,
   types, methods, properties, and variables. Do not append the kind of symbol
   to the name (`PenClass`, `DrawFunction`). Do not name an abstract base as
   `AbstractBrush`, `BrushBase`, or `Brush` when `Brush` is the natural concrete
   instantiable concept. Prefer a true generalized base name and concrete
   derived names, for example `Painter` or `Marker` as the abstraction when
   those names better describe the role.
2. **Functions and methods stay short.** Split work by intent. If a helper
   exists only to make the current flow readable, prefer a local function where
   the language supports it and the scope should remain local.
3. **Avoid deep nesting.** More than two levels of conditions/loops is a design
   smell. Avoid loop-inside-loop flows where possible; extract the inner intent
   into a method, local function, static helper, or lambda according to the
   language. A reader should not need to traverse many conditions and loops to
   understand why the program counter reached a line.
4. **Use dependency injection as a principle, not only as an IoC container.**
   Choose the idiomatic form for the stack: constructor/setter/function
   injection in OO languages, composition roots or framework containers where
   useful, function pointers or structs of function pointers in C, init
   functions, callbacks, strategies, or closures where those are the language's
   natural seams.
5. **Use DTOs between services.** The calling service defines the DTO types it
   consumes; those DTOs are part of the contract and should not leak another
   service's internal model.
6. **Avoid common/shared utility libraries by default.** Broad "common" classes
   create coupling, ownership ambiguity, and merge contention. Prefer
   caller-owned contracts, focused modules, or extracted packages only when the
   reuse boundary is real.
7. **Complex code should be stable.** Reduce coupling around complex logic. This
   is the same pressure as the IDesign Engine idea: keep volatile adapters away
   from stable, complex decision code.
8. **Use anti-corruption layers for decoupling.** Translate between external or
   upstream models and local domain/contract models instead of allowing foreign
   shapes to spread through the codebase.
9. **Check current LTS and supported versions.** At planning/workshop time, the
   Crew must check current language/library LTS and support status on the web,
   because model training data may suggest stale technology. Ask the human
   before choosing a short-lived newer version, preview feature, or non-LTS
   release, and record the reason when it is worth it.
10. **Express immutability and intent in code.** Use `const`, `readonly`,
    `init`, `final`, `val`, `constexpr`, immutable collections, non-mutating
    member markers, or equivalent language features where they clarify intent
    and reduce accidental state changes.
11. **Use type inference deliberately.** Use `var`, `auto`, or similar when the
    right type and size are obvious from the expression, or when hiding the
    concrete type is part of the abstraction. Avoid hiding a type when precision,
    numeric size, ownership, or lifetime matters to the reader.
12. **Use comments wisely.** Tell the main story with good names and structure.
    Use comments for intent, rationale, constraints, and non-obvious trade-offs,
    not narration of obvious code. Use XML docs, docstrings, JSDoc, rustdoc,
    godoc, or equivalent for public/intellisense-facing APIs.
13. **Prefer concurrency designs over locks.** Avoid locks where possible;
    prefer concurrent algorithms, immutable snapshots, channels/actors,
    lock-free or wait-free structures where appropriate, and framework-provided
    concurrent data structures. If locks are needed, make ownership and ordering
    explicit.
14. **Prefer declarative collection/query constructs when they clarify.** Use
    LINQ, streams, comprehensions, pipelines, or similar over manual loops when
    they make intent clearer. Do not turn simple control flow into over-composed
    query code.
15. **Use language-idiomatic error handling.** Exceptions, result types, error
    returns, panic boundaries, typed errors, and cancellation should follow the
    stack's best practices and be decided explicitly for service/API boundaries.
16. **Use retries carefully.** Transient operations should use bounded retries
    with exponential backoff and a maximum delay, plus jitter where appropriate.
    Retry only operations that are safe or explicitly idempotent.
17. **Avoid magic numbers and hidden constants.** Use configuration mechanisms,
    named constants, option objects, or settings classes. Provide safe in-code
    defaults where appropriate. Log when a default is used for a value that
    normally should come from configuration. Choose files, environment
    variables, secret stores, service config, or remote config according to the
    product need, and offer that decision in the workshop.
18. **Make logging and traceability first-class.** Use the target
    language/framework capabilities and consider OpenTelemetry by default for
    services or distributed workflows. Decide what must be logged, traced,
    correlated, and redacted.
19. **Design for robustness and state boundaries.** Understand failure modes,
    transactions, sagas, outbox/inbox, circuit breakers, idempotency,
    concurrency control such as ETags or locks, lifecycle scope (singleton,
    session, transient), and eventual consistency. Choose explicitly rather than
    discovering the state model during implementation.
20. **Decide the testing posture up front.** Decide whether to use TDD. Use
    decoupling to enable tests. Pick mocking/faking/approval/snapshot tools
    deliberately. Group tests by subject and decide which run in CI, which run
    locally, and which require special environment or long-running credentials.
21. **Treat performance as evidence-driven.** When performance matters, use
    profilers, benchmarks, PGO where the stack supports it, and focused research
    on performance implications. Make speed vs memory, GC pressure, cache
    behavior, page faults, allocation strategy, and advanced mechanisms such as
    C# `ref` explicit trade-offs rather than folklore.
22. **Optimize APIs for the call site.** Evaluate names, parameter order,
    defaults, overloads/options objects, and examples from the caller's point of
    view. Readability at the use site is design evidence, not cosmetic polish.
23. **Prefer stronger domain types over primitive obsession.** Use domain
    records, value objects, discriminated unions, enums, newtypes, branded types,
    or small structs/classes where they prevent invalid states or clarify units.
    Keep primitives only where they are genuinely the clearest contract.
24. **Keep object invariants inside the object boundary.** A class should keep
    its member values in their invariant ranges instead of requiring callers to
    ask "is this valid?" before every use. Prefer guarded construction, guarded
    setters, private mutation methods, value objects, and type-level constraints
    over scattered defensive checks. Use runtime validation for untrusted input
    and public boundaries; use `Debug.Assert`, assertions, contracts, or
    invariant-check helpers to document assumptions that should already be true
    inside trusted code. Use `if` checks when a variable's invariant genuinely
    cannot be guaranteed at that point; otherwise fix the ownership/type/model so
    invalid state is not representable.
25. **Do not leak mutable internals.** Prevent side effects by preserving
    encapsulation: do not expose internal collections, arrays, buffers,
    dictionaries, or mutable reference-type members directly. Prefer read-only
    interfaces/views (`IReadOnlyList`, `ReadOnlyCollection`, immutable
    collections, const spans/views, iterator/enumerable projections, defensive
    copies, or language equivalents) when callers only need to observe. Avoid
    returning by reference, pointer, or mutable reference unless that mutation is
    the explicit contract and the invariant impact is controlled.
26. **Choose copy semantics deliberately.** Decide shallow copy, deep copy,
    copy-on-write, clone method, immutable snapshot, serialization round-trip, or
    mapping/DTO projection according to coupling, ownership, performance,
    identity, and mutation risk. Serialization/deserialization can decouple
    graphs or cross process boundaries but may be slower, lossy, version
    sensitive, and unsafe if used as a casual clone mechanism.
27. **Declare extension points explicitly.** Decide whether a type/module/API is
    open for extension, closed/internal, sealed/final, plugin-based, callback
    based, or configuration-driven. Do not leave accidental inheritance,
    monkey-patching, or central-dispatch edits as the only extension story.
28. **Normalize state.** Avoid duplicated, redundant, deeply nested, or
    derivable state. Keep canonical ownership clear, derive views from source
    state where practical, and name cache/snapshot/state boundaries explicitly.
29. **Keep render code pure.** UI/render components should compute output from
    inputs and state. Move I/O, subscriptions, timers, mutation, and imperative
    integration into effects, controllers, services, or framework-approved
    lifecycle seams.
30. **Never block an event loop.** In Node.js, browser UI threads, async Python,
    reactive runtimes, or similar event-loop systems, avoid CPU-heavy work,
    sync I/O, long loops, and blocking locks on the loop. Offload, batch, stream,
    yield, or use worker/background mechanisms.
31. **Treat API and service design as first-class implementation posture.** Pick
    resource/action shape, versioning, idempotency, error envelope, correlation,
    authentication/authorization, compatibility, and backward/forward evolution
    deliberately. Do not let the transport framework's defaults define the API
    accidentally.
32. **Make tests simple enough to trust.** Prefer small deterministic tests for
    core logic, clear fixture setup, readable assertions, and focused integration
    tests for boundaries. A clever test that nobody can debug is weak evidence.
33. **Use public docs and examples as an API design test.** If an API, CLI,
    module, package, or service contract is hard to explain in examples, the
    implementation shape probably needs another look. Examples should exercise
    the intended path, not only the mechanics.
34. **Prefer language-native constructs over unnecessary classes.** Use
    functions, records, modules, extension methods, data classes, protocols,
    traits/interfaces, algebraic/data types, closures, or declarative framework
    constructs when those are the idiomatic fit. Do not force an OO class shape
    onto a stack where a smaller native construct is clearer.
35. **Make secure coding defaults explicit.** Decide input validation,
    output encoding, secret handling, authn/authz boundaries, dependency
    hygiene, least privilege, safe defaults, and failure behavior as part of the
    implementation posture, especially for services, clients, CLIs, and
    automation that touch external systems.
36. **Decide code-level authorization and security-context flow.** Prefer the
    target framework's declarative authorization mechanisms for static access
    rules: attributes, annotations, route metadata, middleware policies,
    roles, claims, scopes, permissions, or policy names. Use explicit imperative
    checks in code when the rule depends on loaded data, ownership, tenant,
    workflow state, or other business context that an annotation cannot express
    cleanly. Keep authorization logic centralized in policy handlers,
    guards/interceptors, domain services, or stable engines; avoid scattered
    ad-hoc `if user in role` checks. Decide how security context flows:
    external hops usually carry signed tokens or security headers; in-process
    code should prefer explicit principal/security-context parameters or the
    framework request context; ambient mechanisms such as `AsyncLocal`,
    thread-local storage, or global context should be restricted to
    framework/boundary plumbing and never become hidden dependencies in stable
    core logic. Environment variables are for app identity/configuration, not
    per-user context. Record fail-closed behavior, audit/logging, test fixtures,
    and how authorization is verified in unit and integration tests.
37. **Prefer vendor-neutral observability where possible.** Use OpenTelemetry or
    equivalent portable semantic conventions for services and distributed flows
    unless a product constraint justifies vendor-specific instrumentation.
38. **Validate at every relevant boundary.** Decide which validation belongs on
    the client, on the server, and in the middle: API gateway/API Management,
    policy engine such as OPA, schema validator, service mesh, or other
    middleware. Client validation improves user experience; server validation is
    authoritative for trust. Middle validation can enforce cross-cutting policy,
    but must not hide ownership of business rules.
39. **Prefer UI controls that prevent invalid input.** Use constrained controls
    before relying on error messages: date/time pickers with the correct range,
    numeric inputs for numbers, dropdowns/comboboxes for closed sets, masks where
    appropriate, and disabled/unavailable choices when the domain already knows
    they cannot work.
40. **Use language and framework validation capabilities where suitable.** Prefer
    built-in validators, schema systems, form libraries, model binding, data
    annotations, fluent validators, JSON Schema/OpenAPI, GraphQL schema
    constraints, or policy languages where they fit. Avoid hand-rolled parallel
    validators unless the framework cannot express the rule cleanly.
41. **Decide write-conflict semantics for clients and services.** When a user
    edits data that may have changed on the server, choose the behavior:
    last-write-wins, optimistic concurrency with version/ETag and a repair UI,
    merge/rebase, pessimistic locking, or a lease. Record the user experience and
    API contract for stale submissions.
42. **Decide collection/query semantics across client and server.** For sorting,
    grouping, filtering, paging, and search, decide what runs client-side vs
    server-side, whether the result set is a frozen snapshot or live re-query,
    whether ordering can change between requests, and what stable sort keys or
    cursor guarantees are required.
43. **Choose pagination and delivery style deliberately.** Decide page numbers vs
    continuation/cursor tokens, infinite scroll vs explicit paging, synchronous
    request/response vs async jobs vs streaming, and how cancellation, partial
    failures, totals, and changing datasets are surfaced.
44. **Choose protocol by communication shape.** REST fits resource/document APIs
    and broad interoperability; GraphQL fits client-shaped graph queries when the
    server can own query governance; gRPC fits strongly typed low-latency service
    calls and streaming; WebSocket/SignalR fit interactive server push; webhooks
    fit external event delivery. Record the protocol, idempotency/retry model,
    versioning, and observability obligations.
45. **Choose messaging and event processing deliberately.** Decide when the
    design uses direct calls, queues, pub/sub, event streams, event routers, or
    event processing platforms such as Service Bus, Kafka, Event Hubs, or Event
    Grid. Choose orchestration vs choreography explicitly: a Manager, process
    manager, or saga orchestrator owns workflow order/compensation when
    correctness, audit, or central policy matters; choreography lets services
    react to events when decoupling and independent evolution matter more.
    Record delivery semantics, ordering, idempotency, retries, dead-letter
    handling, backpressure, schema/versioning, replay/retention, and tracing.
46. **Treat technology suggestions as a shortlist, not a closed menu.** The
    workshop should suggest stack-relevant enablers, but the human and Crew may
    choose something else if it fits the solution better. Examples by context:
    Dapr for cross-language microservice building blocks such as service
    invocation, pub/sub, state, actors, and workflows; Aspire for modeling,
    running, and observing distributed applications; MassTransit or NServiceBus
    for .NET messaging; Temporal, Durable Functions, Dapr Workflow, or a saga
    library for durable orchestration; Apache Camel or Spring Cloud Stream for
    Java/integration flows; Orleans or Akka for actor-oriented systems; and
    managed cloud primitives such as Service Bus, Event Hubs, Event Grid, SNS,
    SQS, EventBridge, Kinesis, or Pub/Sub where they are the better operational
    fit. These examples are prompts, not a recommendation floor and not an
    exhaustive catalog.
47. **Check CNCF projects for cloud-native requirements and explain maturity.**
    For cloud-native applications, look at relevant CNCF projects before
    defaulting to proprietary, hand-rolled, or framework-local mechanisms.
    Match projects to the actual requirement category: orchestration, service
    mesh, ingress/API gateway, observability, policy/security, secrets, runtime,
    storage, messaging/streaming, workflow, GitOps, delivery, or autoscaling.
    Explain the CNCF maturity level to the user: Sandbox for early/experimental
    or innovative projects, Incubating for projects gaining adoption and
    stability, and Graduated for highly mature projects with demonstrated
    production readiness. Maturity is one signal, not the whole decision; also
    check fit, ecosystem, operator skill, cloud/provider integration, security
    posture, release cadence, maintainership, support model, and whether a
    non-CNCF or managed platform option is better for the solution.
48. **Use cache for performance and same-service state sharing, not
    communication.** Choose local cache, distributed cache, CDN/edge cache,
    database cache, materialized view, or no cache according to latency,
    throughput, consistency, cost, and failure behavior. Distributed cache is
    appropriate for sharing cached data or ephemeral state between instances of
    the same service. Do not use a cache or database table as a service
    communication mechanism; use explicit APIs, queues, pub/sub, event streams,
    or orchestration mechanisms for communication. Record TTL, invalidation,
    consistency, stampede protection, fallback behavior, and whether cache
    failures degrade or fail the request.
49. **Choose the rendering and hosting model intentionally.** Decide client-side
    rendering, server-side rendering, static generation, hybrid/islands,
    WebAssembly, server-driven UI, or native shell based on latency, SEO,
    offline support, auth/data sensitivity, device capability, deployment model,
    and operational complexity.

Sources for rules 22-49:

- <https://www.swift.org/documentation/api-design-guidelines/>
- <https://dart.dev/effective-dart/design>
- <https://rust-lang.github.io/api-guidelines/>
- <https://react.dev/learn/choosing-the-state-structure>
- <https://react.dev/reference/rules/components-and-hooks-must-be-pure>
- <https://nodejs.org/en/learn/asynchronous-work/dont-block-the-event-loop>
- <https://cloud.google.com/apis/design>
- <https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices>
- <https://testing.googleblog.com/2010/12/test-sizes.html>
- <https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/>
- <https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html>
- <https://learn.microsoft.com/en-us/aspnet/core/security/authorization/policies>
- <https://docs.spring.io/spring-security/reference/servlet/authorization/method-security.html>
- <https://openid.net/specs/openid-connect-core-1_0.html>
- <https://swagger.io/docs/specification/v3_0/authentication/>
- <https://opentelemetry.io/docs/what-is-opentelemetry/>
- <https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Conditional_requests>
- <https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#constraints>
- <https://www.openpolicyagent.org/docs/latest/policy-language/>
- <https://spec.openapis.org/oas/latest.html>
- <https://graphql.org/learn/>
- <https://google.aip.dev/158>
- <https://learn.microsoft.com/en-us/azure/architecture/patterns/publisher-subscriber>
- <https://learn.microsoft.com/en-us/azure/architecture/patterns/competing-consumers>
- <https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/event-hubs/stream-processing>
- <https://docs.dapr.io/concepts/building-blocks-concept/>
- <https://aspire.dev/get-started/what-is-aspire/>
- <https://masstransit.io/documentation/>
- <https://docs.temporal.io/>
- <https://www.cncf.io/project-metrics/>
- <https://www.cncf.io/projects/>
- <https://landscape.cncf.io/>
- <https://contribute.cncf.io/projects/lifecycle/>
- <https://learn.microsoft.com/en-us/aspnet/core/performance/caching/distributed>
- <https://learn.microsoft.com/en-us/azure/architecture/patterns/cache-aside>
- <https://learn.microsoft.com/en-us/aspnet/core/grpc/comparison>
- <https://learn.microsoft.com/en-us/aspnet/core/signalr/introduction>
- <https://learn.microsoft.com/en-us/aspnet/core/blazor/hosting-models>

## Composition map

- [[074-code-commentary-standards]] — the comment-policy decision point is this; 163 decides it at design time.
- Microsoft Framework Design Guidelines — used as a cross-stack source for
  reusable-code/API design questions (naming, members, extensibility,
  exceptions, versioning), adapted to local stack idioms rather than treated as
  .NET-only or library-only.
- [[156-design-analysis-lens-knowledge-catalog]] — 163 adds a lens to the
  catalog 156 governs and contributes its selected rules into 156's canonical
  `workshop-decisions.yml` manifest; 163 is one concrete lens, not the catalog
  mechanism.
- [[145-structured-multi-phase-reviewer]] — Phase-4 code-quality is the review-time counterpart; it consumes
  163's selected implementation-rule manifest as the code subset of
  `workshop-decisions.yml` and verifies every chosen rule and enforcement mode
  through `workshop-decision-conformance.yml` rather than duplicating the
  workshop.
- [[008-nfr-governance]] — 008 owns the category-level cohesion/coupling baseline; 163 turns it
  into stack/project-specific implementation decisions.
- [[091-tech-debt-control]] — debt findings discovered later flow into the ledger; 163 tries to
  prevent avoidable debt before implementation.
- [[166-concurrent-development-hygiene]] — 166 owns volatile-file and central-hub collision
  detection; 163 owns the implementation-design question of whether a central hub should be
  modified at all.
- Stack-aware tool selection — the per-stack dilemmas reuse the stack-aware catalog + the human-approval rule.
- The lens system (Amendments A1–A3 of Feature 141) — 163 is a catalog addition built on that machinery.

## Sizing

- **As a record-only workshop lens: ~6-9 SP.** Almost all of it is *content*, not plumbing: the lens md
  (Decision Points + Question Bank + Workshop Conduct) with the per-stack dilemmas is the bulk (~4-6 SP);
  registration (selector/applicability catalog, the skill's lens map, the `$lensIds` test list), applicability
  heuristic, and tests are mechanical (~2-3 SP).
- **As an enforced lens: more**, and the increment is the research output (the implement-constraint flow + the
  review/mechanical gate or the analyzer-config integration).

## Open questions

- One lens with per-stack sections, or per-stack depth driven by the resolved stack?
- Does it gate the specify or a later boundary, or stay advisory?
- How does it interact with stack-aware tool selection (which already gates per-project tech choices)?
- How should the lens cache/present current LTS/version research without making
  stale claims in long-lived artifacts?
- Which thresholds should be universal defaults, project-profile defaults, or stack-specific
  analyzer settings?
- Should central-hub edits require an explicit OCP/decomposition waiver at plan time, or only at
  review time?

## Risks

- **Invented-not-proven conventions** if future stack sections are added without
  research — the lens must recommend the ecosystem's established defaults, not
  the Crew's opinions.
- **Per-stack scope creep** — covering every language well is large; a first version may scope to the resolved
  project stack + a small default set.
- **Overlap with the reviewer / mechanical checks** in an enforced mode — needs an explicit boundary so 163
  decides conventions and 145 / the mechanical checks verify them, without duplication.

## Status history

- 2026-06-05: Candidate drafted after maintainer observation that implementation-craft decisions
  are missing from the design-lens set and require research before spec conversion.
- 2026-06-06: Refined to include refactor-prevention by design: OCP/extension posture,
  cohesion/coupling expectations, size/complexity thresholds, analyzer binding, and review
  evidence.
- 2026-06-08: Research baseline completed for C#/.NET, C/C++,
  TypeScript/JavaScript, Python, Go, and Java; record-only V1 recommended, with
  ecosystem analyzers and Proposal 145 review owning verification. Maintainer
  default implementation posture added as the lens baseline, including
  source-backed cross-language defaults, object invariants,
  encapsulation/copy-semantics, client/service interaction posture,
  messaging/event-processing coordination posture with cache boundaries,
  code-level authorization/security-context rules, non-exclusive stack/platform
  enabler suggestions, and CNCF maturity disclosure for cloud-native choices.
- 2026-06-08: Added the rule grouping and consumption model: baseline defaults,
  decision prompts, applicability-filtered rules, and enforcement modes, emitted
  as an implementation-rule manifest consumed by plan/implement/review.
- 2026-06-08: clarified that the implementation-rule manifest feeds Proposal
  156's canonical `workshop-decisions.yml` and is verified by Proposal 145's
  `workshop-decision-conformance.yml`; it is not a separate code-only approval
  or review universe.
