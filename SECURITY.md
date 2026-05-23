# Security

## Reporting a vulnerability

Open a private security advisory on GitHub or email the maintainer.

## Dependency audit ignores

`gakudan_metrics` runs `rebar3 audit` against the GitHub Advisory Database on
every CI run. The following advisories are explicitly skipped via the
`audit-ignores` workflow input:

### GHSA-g2wm-735q-3f56 — cowlib Cookie Request Header Injection

- **Severity:** LOW
- **Advisory:** https://github.com/advisories/GHSA-g2wm-735q-3f56
- **Affected:** cowlib >= 2.9.0, <= 2.16.1
- **Upstream fix:** none available at time of writing
- **Why we ignore:** `gakudan_metrics` exposes only a Prometheus
  `/metrics` scrape endpoint. It does not parse, set, or validate any
  HTTP cookies. The advisory concerns `cow_cookie:cookie/1`, which is
  never called by this library or by any code path it serves. The
  attack surface does not apply.
- **Re-evaluation trigger:** when cowlib ships a patched release, drop
  the ignore and bump cowlib here.

## Patched advisories

Fixed by bumping `cowboy` from 2.13.0 to 2.15.0:

- GHSA-jfc2-q6qh-g5x8 (CVE-2026-8466) — Unbounded buffer accumulation
  in multipart header parsing. Fixed in cowboy 2.15.0.
