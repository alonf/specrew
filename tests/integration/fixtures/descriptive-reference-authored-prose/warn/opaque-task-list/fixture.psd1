@{
    FixtureId         = 'opaque-task-list'
    FixtureClass      = 'warn'
    ReplayPath        = 'extensions\specrew-speckit\validators\handoff-governance-validator.ps1'
    ExpectedFinding   = @('soft-warning.opaque-numeric-references')
    SeedStatus        = 'seeded'
    ResponseFile      = 'response.md'
    RequiredPatterns  = @(
        'status: warn'
        'soft-warning\.opaque-numeric-references'
        'Add descriptive scope when three or more feature, iteration, task, requirement, corpus, or commit references appear in authored prose\.'
    )
    ForbiddenPatterns = @(
        'soft-warning\.jargon-first-lead'
        'soft-warning\.review-file-reference-format'
        'soft-warning\.missing-progress-status'
        'soft-warning\.missing-next-step'
    )
}
