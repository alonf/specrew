# Component Design - Feature 185

**Reuse-heavy**: the refocus engine, the dormant gate seat + dispatcher, 065 authorization (`Test/Add-SpecrewBoundaryAuthorization`), the Claude `specrew-gate-stop` skill, `HandoverStore` marker capture, and the per-host `host.psd1` manifests.

**Four focused additions**:
1. a host-neutral fallback renderer with `SPECREW-VERDICT-BOUNDARY` marker emission;
2. a per-host capability declaration in `host.psd1`;
3. a gate provider on the dormant seat;
4. non-Claude verdict-marker capture.

No parallel system. Confirmation: human-confirmed (lens-question).