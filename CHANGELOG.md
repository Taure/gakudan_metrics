# Changelog

All notable changes to gakudan_metrics are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and gakudan_metrics uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-05-23

### Added

- `SECURITY.md` documenting dependency audit ignores with rationale and
  re-evaluation triggers.
- `CHANGELOG.md` mirroring upstream gakudan's convention.

### Changed

- Bumped `cowboy` from 2.13.0 to 2.15.0.
- CI pins `Taure/erlang-ci` to `@v2.1.1` (explicit) instead of `@v2.1.0`.
  Picks up the upstream audit composite fix and unlocks the new
  `audit-ignores` workflow input.

### Security

- `cowboy` 2.15.0 bump patches **GHSA-jfc2-q6qh-g5x8** (HIGH: unbounded
  buffer accumulation in multipart header parsing leading to denial of
  service).
- Added `audit-ignores: GHSA-g2wm-735q-3f56` for the cowlib LOW Cookie
  Request Header Injection advisory. The attack surface does not apply
  to `gakudan_metrics`, which serves only a Prometheus `/metrics`
  scrape endpoint and never parses, sets, or validates cookies.
  Documented in [SECURITY.md](SECURITY.md) with the re-evaluation
  trigger.

## [0.1.0] - 2026-05-23

### Added

- Initial public release. Pins against
  [gakudan v0.1.0](https://github.com/Taure/gakudan/releases/tag/v0.1.0)'s
  telemetry event surface (ADR 0001).
- **10 Prometheus counters** covering runs started/stopped, turns, LLM
  requests (with `tokens_in` / `tokens_out` as first-class sums), LLM
  exceptions, tool invocations, tool exceptions, and router decisions.
- **6 Prometheus histograms** for run duration, run turn count, turn
  duration, LLM request duration, tool run duration, and router decide
  duration. Each with reasonable starter buckets.
- `gakudan_metrics:setup/0` declares the metrics and attaches a single
  fan-out telemetry handler. Idempotent.
- `gakudan_metrics:start_listener/1,2` brings up a standalone Cowboy
  listener serving `/metrics`. Or mount `prometheus_cowboy2_handler` on
  your existing Cowboy / Nova listener.
- `priv/grafana/gakudan.json` - starter Grafana dashboard with
  Throughput / Cost / Latency / Errors rows.
- 6-case CT suite asserting every counter increments and every histogram
  observes from the right telemetry event shape, plus that
  `prometheus_text_format:format/0` exposes our metrics.

### Notes

- Metric names and labels are part of the public API and follow semver
  from v0.1.0 onward.
- High-cardinality keys (`run_id`, `turn`) deliberately stay off labels.
  They are still on the raw telemetry events for tracing / audit sinks.
- Pure Erlang stack: `prometheus.erl` 6.1.2 + `prometheus_cowboy` 0.2.0 +
  `cowboy` 2.13.0. No Elixir/mix toolchain required.

[Unreleased]: https://github.com/Taure/gakudan_metrics/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/Taure/gakudan_metrics/releases/tag/v0.1.1
[0.1.0]: https://github.com/Taure/gakudan_metrics/releases/tag/v0.1.0
