# Architecture

`gakudan_metrics` is a thin adapter between two stable contracts:

- **gakudan's telemetry event surface** (defined in [ADR 0001](https://github.com/Taure/gakudan/blob/main/docs/adr/0001-telemetry-events.md))
- **the Prometheus scrape format** (via `telemetry_metrics_prometheus_core`)

It owns no novel logic. Every metric is a direct translation of an upstream
event, declared in `gakudan_metrics_definitions:all/0`.

## Process tree

```
gakudan_metrics_sup
└── (optional) gakudan_metrics_listener (Cowboy)
```

When `auto_setup` is `true` (default), `gakudan_metrics_app:start/2` calls
`gakudan_metrics:setup/0`, which hands the definitions to
`telemetry_metrics_prometheus_core:init/1`. That call attaches one
`:telemetry` handler per event referenced in the definitions. Handlers live
in the Prometheus core's own supervision; we do not own them.

The listener supervisor is intentionally empty until the user explicitly
calls `gakudan_metrics:start_listener/1,2`. Most users mount
`prometheus_cowboy2_handler` on their existing Cowboy or Nova listener
instead.

## Why a separate library

Three reasons.

1. **Optional dependency.** Users who already export telemetry via OTel or a
   custom pipeline should not be forced into a Prometheus stack. Core
   gakudan stays metric-stack-agnostic.
2. **Stable API contract.** Metric names and labels are public API. Keeping
   them in their own library makes versioning explicit.
3. **Dashboard JSON.** A Grafana dashboard is the kind of opinionated asset
   that does not belong in a core OTP library, but does belong in a
   companion library.

## What this library is not

- Not an HTTP framework. It uses Cowboy because Cowboy is the BEAM standard,
  not because it owns its own webserver.
- Not a tracer. For per-run tracing, subscribe to the raw telemetry events
  directly and ship spans to your tracing backend.
- Not opinionated about cardinality. We refuse high-cardinality labels by
  default (run_id, turn) because Prometheus is not a tracing system.
