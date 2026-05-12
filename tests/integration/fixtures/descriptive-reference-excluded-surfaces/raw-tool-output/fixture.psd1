@{
    FixtureId         = 'raw-tool-output'
    FixtureClass      = 'pass'
    ReplayPath        = 'extensions\specrew-speckit\validators\handoff-governance-validator.ps1'
    ExpectedFinding   = @('none')
    SeedStatus        = 'seeded'
    ResponseFile      = 'response.md'
    RequiredPatterns  = @(
        'status: pass'
        '\s+- none'
        'No soft warnings\.'
    )
    ForbiddenPatterns = @(
        'soft-warning\.opaque-numeric-references'
        'soft-warning\.jargon-first-lead'
        'soft-warning\.review-file-reference-format'
        'soft-warning\.missing-progress-status'
        'soft-warning\.missing-next-step'
    )
}
