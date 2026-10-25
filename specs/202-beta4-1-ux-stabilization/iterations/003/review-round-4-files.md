# Iteration 003 review round 4: the files to read

The reviewer may not be able to run `git diff`, so the files are listed here. The task text is in
`specs/202-beta4-1-ux-stabilization/tasks.md` (T030, "Review round 3").

## Round 3's fix: commit `8aa15c19`

Round 3 found that the typed-authority router let a message through when the approval form could not be read. The
form was read in a `try` whose `catch` kept the raw message and refused nothing, and the form was skipped when its
function was not loaded. A condition typed below the partial sign-off line then reached that writer again. A form
failure, or a missing form function, now refuses every writer that records authority. The withdrawal still runs.

Files:

- `scripts/internal/bootstrap/HandoverStore.ps1`: `Invoke-SpecrewTypedAuthorityCapture`, the `$formRefused` block
- `tests/unit/approval-form.tests.ps1`: the Describe "An approval form that cannot be read records no authority",
  and the two fixture helpers moved to the file's `BeforeAll`
