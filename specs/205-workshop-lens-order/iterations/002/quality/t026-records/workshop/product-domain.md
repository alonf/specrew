# Product and Problem Domain: 001-nightly-appointment-export

**Depth**: Light (requested and confirmed by the human)
**Confirmation**: human-confirmed, lens-question
**Answers relayed by**: reviewer session specrewreviewer-98, on behalf of the maintainer
**Date**: 2026-11-14

## Why Light is enough

One narrow internal utility with a single consumer and one fixed data flow. There is no market,
alternatives or rollout question to explore. The regulated nature of the data is captured by the named
compliance regime below and handed to the security-compliance lens.

## Who it is for

| Party | Role | Evidence |
| --- | --- | --- |
| External accountant | Uses the daily file | known |
| Practice manager | Clinic-side owner of the arrangement | known |
| External IT contractor | Looks after the server and database; installs and maintains the tool | known |
| Receptionist | Does the export by hand today | known |
| Patients | Harmed if the file is wrong or reaches the wrong person | known |

## Pain, job and current workaround

- Today the receptionist exports the day's list by hand from the practice software each evening and
  emails it to the accountant. (known)
- It takes about 15 minutes and is forgotten about twice a month. (known)
- It sends patient data by email, which the clinic wants to stop. (known)
- The accountant books daily revenue and matches payments to the invoices of privately paying patients.
  That is why patient name and date of birth are needed. The four fields are kept: patient name, date of
  birth, treatment code, price. (known)

## Outcomes

- No evening manual export by the receptionist. (assumed, derived from the pain)
- No missed days. (assumed, derived from the pain)
- Patient data no longer sent by email. (assumed, derived from the pain)

## MVP and out of scope

**In the first version** (known):

- One unattended nightly run that produces one file with that day's appointments and the four fields, in
  the shared folder, by the morning.
- A manual run for a given past date, so a missed night can be made up.
- Removal of each file 30 days after it is written. (added by the human in the security-compliance lens)

**Out of scope** (known):

- Any screen or interactive use.
- Sending the file by email or uploading it anywhere.
- Importing into the accountant's software.
- Changing or correcting data in the database.
- Reports or totals.

## Constraints

- Fixed: PostgreSQL as the source, CSV as the output, the shared network folder as the delivery point. (known)
- Preference: 22:00. Any time after closing at 20:00 and before 06:00 is acceptable. (known)
- Deadline: none. (known)

## Handed forward to later lenses

| Area | Answer | Evidence | Goes to |
| --- | --- | --- | --- |
| Compliance or regulatory regime | GDPR (DSGVO) and the German BDSG; health data under Article 9; professional secrecy under section 203 StGB applies to the clinic | known | requirements-nfr, security-compliance |
| Data residency | The data stays on the clinic's own network in Germany | known | security-compliance, data-storage |
| Systems and data carried over | The clinic's existing PostgreSQL appointment data (read) and the shared network folder (write) | known | data-storage, integration-api |
| Where it must run | The clinic's existing on-premises server, the one that hosts the database | known | devops-operations |
| Who operates it, and when | not stated (support hours and arrangement); the external IT contractor installs and maintains the tool | unknown | devops-operations, observability-resilience |
| Budget | not stated | unknown | devops-operations, observability-resilience |

## Open point carried forward

- How the external accountant reaches the shared folder while the data stays on the clinic's own network
  is not yet stated. (unknown; for the security-compliance lens)

## Skipped at Light depth

- Alternatives and competitors: the only alternative is the current manual export and email.
- Adoption and rollout: a single clinic with one consumer.
- Existing system context map: the surrounding systems are recorded under "Systems and data carried over".
