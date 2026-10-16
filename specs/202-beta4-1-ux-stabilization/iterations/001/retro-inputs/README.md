# Retro inputs: iteration 001

Gathered 2026-10-16 at the maintainer's request, for the iteration-001 retro. Each input carries its evidence.
They are inputs, not conclusions; the retro weighs them.

## (a) The trend of real findings per round

Six co-review rounds found 8, 5, 4, 5, 6 and 4 defects: 32 in all, and all 32 real. The engine demoted 23 of
them (8, 4, 4, 0, 4 and 3), and every demoted finding was real (B4F-055, DRIFT-033). Round 6 found nothing in
round 5's fixes: a line-by-line blame of fix `0e6a8a01` traces every changed line to T003, T006, T007 and round 3,
none to round 5's `5c56dbed`. Its findings were older code that earlier rounds had not reached.

## (b) Why the failing-first tests missed all 32

`findings-classification.md` classifies each finding, with one sentence of evidence and the commit that
introduced it.

- A case the test author did not think of: 9.
- State shared across sessions or turns: 12.
- A withheld or partial delivery: 10.
- Other: 1 (a new value never reached its real reader).

So 22 of 32 are about shared state or delivery. In 8 cases the existing test passed because it went around the
real path (a supplied value, a preseeded state, a probe provider) or its fixture had the same defect. Sixteen of the
32 are fix-related (6 introduced by a fix, 9 left by an incomplete fix, 1 made worse). Twenty-two of the 32 are in
one area, the reply-recording outage and recovery machinery (T003, T004 and their fixes), and 14 of the 16
fix-related ones are there. The file's own reading is that both explanations hold, about half each: 16 findings sit
in first-pass task code (iteration too large for four rounds), and 16 come from fixes in one area that kept adding
states no test modelled (the loop adds defects).

## (c) Runtime stores before and after 202

`state-inventory.md` lists every store, journal, flag file and per-session record that the hook and approval paths
read or write, at 202's starting tree (`24e5701a`, the parent of 202's first commit) and at the end. 202 added 12 and
removed none: 78 before, 90 after. Twenty-three of the 32 findings are in stores 202 added, and 7 more are in older
stores whose shape 202 changed. In rounds 1 to 4, each round's fix added state, and the next round found a defect in
exactly that addition. The tasks that added no state (T007, T010, T012, T014) drew 3 findings in all. The file lists
candidates to merge or remove, each with the findings it was involved in. Two of the new stores have no reader.

## (d) Live friction events

Recorded in `acceptance-evidence.md`, "Friction observed during 202's own run", and in the drift log:

- **The compaction-lost verdict** (B4F-112): a verdict typed after a context compaction was not captured.
- **The position-rejected approval** (B4F-125): a typed approval on its own line was refused because it did not
  lead the message.
- **The reset needing two approvals plus a script** (B4F-125): one decision took three messages.
- **The heading repaint** (DRIFT-030): a whole reply rendered again over two reworded headings.
- **The refused stops** (B4F-126, DRIFT-032 and DRIFT-033): twice the crew offered a stop the engine could not
  complete.
- **The Stop review check asking for rounds while a stop ran** (B4F-121): seven times in one hour.
- **The double-recorded approval** (B4F-127, DRIFT-034): critical, predates 202, open at its close.
