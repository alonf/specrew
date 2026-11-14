# Security and Compliance Lens: 001-nightly-appointment-export

**Depth**: Light
**Confirmation**: human-confirmed, lens-question
**Answers relayed by**: reviewer session specrewreviewer-98, on behalf of the maintainer
**Date**: 2026-11-14

## Trust boundaries and crossings (agreed)

```text
   CLINIC NETWORK (on premises, Germany)                              OUTSIDE
  +---------------------------------------------------------------+
  |  Database server                                              |
  |                                                               |
  |  +----------------+   (1) read    +----------------------+    |
  |  | PostgreSQL     |<--------------| Export tool          |    |
  |  | appointments   |   DB login    | started by scheduler |    |
  |  +----------------+               | or by IT contractor  |    |
  |                                   +----------+-----------+    |
  |   (4) left behind by the tool:               |                |
  |       run record, settings,           (2) write file          |
  |       the DB login                           v                |
  |                                   +----------------------+    |  (3) clinic VPN,  +------------+
  |                                   | Shared folder        |<------ personal ------| Accountant |
  |                                   | one CSV per day,     |    |     account      | (external) |
  |                                   | removed after 30 days|    |                  +------------+
  |                                   +----------------------+    |
  |                                     also read by:             |
  |                                     practice manager          |
  +---------------------------------------------------------------+
```

- (1) Tool to database: the tool's own read-only database login.
- (2) Tool to folder: the tool writes the file and, after 30 days, removes it.
- (3) Accountant to folder: the accountant's office connects into the clinic network over the clinic's
  existing VPN with a personal account and reads the folder from there.
- (4) Left on the server by the tool: the run record, its settings, the database login.
- Only outside input: the date given to a manual run; it is checked before use.

## Decisions

| # | Question | Decision | Source |
| --- | --- | --- | --- |
| 1 | What is sensitive | Every row. Name, date of birth and treatment code together are health data; the whole file is treated as Article 9 data wherever it exists (folder, temporary copies, backups of the folder). The database login is a secret | human, "as proposed" |
| 2 | How the accountant reaches the folder; who may read it | Over the clinic's existing VPN with a personal account, reading the folder from inside the clinic network. Readers: the accountant and the practice manager, nobody else. The tool can only write there; named readers can only read; the IT contractor sets those rights; the tool does not manage them | human |
| 3 | The tool's identity and database login | The tool runs under its own account on the server and uses its own database login that can only read what the export needs, with no writing. The password is kept outside the program, readable only by that account. Where exactly is decided in the operations lens | human, "as proposed" |
| 4 | Protecting the file in the folder | No encryption of the file itself; it is protected by the folder's access rights on the clinic network. The file stays a plain CSV | human, option 1 |
| 5 | How long files stay | Files are removed 30 days after they are written. This is the tool's job and is added to the first version | human |
| 6 | What is recorded about each run | The date exported, when it ran, whether scheduled or manual and under which account, how many rows, and the outcome (written, refused because a file existed, replaced on explicit request, or failed). Never any patient data | human, "as proposed" |

Confirmed reading carried from the requirements lens: any run, nightly or manual, that finds a file for
its day already present refuses rather than replaces it.

## Scope change recorded here

Removal of files 30 days after they are written is added to the first version (decision 5). The
product-domain record's MVP list is updated to match. Crew note for later lenses: the run record should
also show removals, without patient data.

## Recommendation block

| Line | Answer | Source | Goes to |
| --- | --- | --- | --- |
| Threat actors | A staff member with network access who is curious or careless; a lost or compromised accountant laptop or VPN account | changed by the human | spec.md Problem Context: Threat actors |
| What must never be logged (`never_logged`) | The database login and any other secret, and all patient data: names, dates of birth, treatment codes, and prices tied to a patient | accepted | spec.md Problem Context: Operating needs |
| Handed forward, product-domain `compliance_regime` | GDPR (DSGVO) and the German BDSG; health data under Article 9; professional secrecy under section 203 StGB applies to the clinic | accepted | spec.md Problem Context: Regulation and compliance |
| Handed forward, product-domain `data_residency` | The data stays on the clinic's own network in Germany | accepted | spec.md Problem Context: Data residency |

## Outside the tool (recorded, not designed)

What the accountant does with the file after collecting it is governed by the clinic's arrangement with
the accountant, not by this tool. It is the clinic's responsibility and was not verified in this workshop.
The human did not comment on this point.

## Controls that follow from the named threat actors (for plan)

- Curious or careless staff member with network access: folder rights limited to the two named readers;
  the tool's account and database login are not shared; no patient data in the run record.
- Lost or compromised accountant laptop or VPN account: exposure in the folder is bounded to 30 days of
  files by the removal rule; VPN and account management belong to the clinic and its IT contractor, not
  to this tool.
