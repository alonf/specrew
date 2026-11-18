# Requirements and NFR Lens: 001-nightly-appointment-export

**Depth**: Light
**Confirmation**: human-confirmed, lens-question
**Answers relayed by**: reviewer session specrewreviewer-98, on behalf of the maintainer
**Date**: 2026-11-14

## Quality-attribute priorities (agreed)

When two of these pull against each other, the higher one wins.

```text
  #  Quality                    What it means here                                Drives design?
  1  Confidentiality            Patient data reaches only the accountant          yes
  2  Correctness, completeness  Every qualifying appointment, exact values        yes
  3  Dependability              File is there each morning, or its absence        yes
                                is noticed
  4  Operability                The IT contractor can install, run, repair it     yes, lightly
  5  Performance                One clinic, one day of rows                       no
  6  Scalability                One clinic, one consumer                          no
```

Consequence agreed with the order: if the file cannot be delivered safely, it is not delivered, and that
is reported.

## Decisions

| # | Question | Decision | Source |
| --- | --- | --- | --- |
| 1 | Priority order of qualities | As in the table above; confidentiality ahead of dependability | human, "as proposed" |
| 2 | Which appointments are "the day's appointments" | Every appointment dated that day that carries a price. Includes a charged no-show; excludes cancellations without a charge. "The day" is the calendar day in Munich local time; a run after midnight exports the day before; a manual run exports the date it is given | human, "as proposed" |
| 3 | A day with no appointments | A file is still written, containing only the header line | human, "as proposed" |
| 4 | Manual run for a past date when that date's file already exists | Refuse and say the file exists; replace it only when the person running it explicitly asks for a replacement | human, option 1 |
| 5 | Measurable threshold | The file for a given day is in the folder by 06:00 the next morning. The accountant collects at about 07:00 | human, "as proposed" plus the collection time |
| 6 | Acceptance checks beyond the normal night | (a) to (f) below | human, "as proposed" plus (f) |

## Acceptance checks beyond the normal night

- (a) An empty day gives the header-only file.
- (b) A missed night made up by the manual run gives the same file the nightly run would have given.
- (c) Names with umlauts, commas or quotation marks arrive unchanged.
- (d) Prices arrive exact to the cent.
- (e) A run that fails part-way never leaves a file that looks complete.
- (f) Running the export twice for the same day never duplicates rows and never silently replaces the
  file. (added by the human)

Crew reading of (f) together with decision 4, to be checked in later lenses: the no-silent-replace rule
holds for any run, nightly or manual, that finds a file for its day already present.

## Recommendation block (accepted as shown)

| Line | Answer | Source | Goes to |
| --- | --- | --- | --- |
| Regulatory obligations that become requirements | Those that follow from the regime named in product-domain; specifics in the security lens | accepted | spec.md Problem Context: Regulation and compliance |
| Service level and alerting expected (`slo_alerting`) | none stated | accepted | spec.md Problem Context: Operating needs |
| Failures the domain expects (`expected_failures`) | not stated | accepted | spec.md Problem Context: Operating needs |
| Handed forward, product-domain `compliance_regime` | GDPR (DSGVO) and the German BDSG; health data under Article 9; professional secrecy under section 203 StGB applies to the clinic | accepted | spec.md Problem Context: Regulation and compliance |

## Out of scope for this iteration

Unchanged from product-domain: no interactive use, no email or upload, no import into the accountant's
software, no changes to data in the database, no reports or totals.
