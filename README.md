# gakudan_metrics

Prometheus exporter and Grafana dashboard for [`gakudan`](https://github.com/Taure/gakudan).

Subscribes to every event in the gakudan telemetry surface ([ADR 0001](https://github.com/Taure/gakudan/blob/main/docs/adr/0001-telemetry-events.md))
and exposes them as canonical Prometheus metrics. A ready-to-import Grafana
dashboard lives in [`priv/grafana/gakudan.json`](priv/grafana/gakudan.json).

## Quickstart

```erlang
{ok, _} = application:ensure_all_started(gakudan_metrics),
{ok, _} = gakudan_metrics:start_listener(9568).
```

Point Prometheus at `:9568/metrics`. Import `priv/grafana/gakudan.json`.

## Mounting on your own Cowboy listener

```erlang
Routes = [
    {"/metrics", gakudan_metrics_handler, []}
    %% your other routes
],
Dispatch = cowboy_router:compile([{'_', Routes}]),
cowboy:start_clear(http, [{port, 8080}], #{env => #{dispatch => Dispatch}}).
```

## What gets exported

| Metric | Type | Labels |
| --- | --- | --- |
| `gakudan_runs_started_total` | counter | `router`, `llm_backend` |
| `gakudan_runs_stopped_total` | counter | `reason` |
| `gakudan_run_duration_seconds` | histogram | `reason` |
| `gakudan_run_turns_count` | histogram | `reason` |
| `gakudan_turns_total` | counter | `agent_id`, `outcome` |
| `gakudan_turn_duration_seconds` | histogram | `agent_id`, `outcome` |
| `gakudan_llm_requests_total` | counter | `backend`, `model`, `outcome` |
| `gakudan_llm_request_duration_seconds` | histogram | `backend`, `model`, `outcome` |
| `gakudan_llm_tokens_input_total` | counter | `backend`, `model` |
| `gakudan_llm_tokens_output_total` | counter | `backend`, `model` |
| `gakudan_llm_exceptions_total` | counter | `backend`, `model` |
| `gakudan_tool_runs_total` | counter | `tool`, `outcome` |
| `gakudan_tool_run_duration_seconds` | histogram | `tool`, `outcome` |
| `gakudan_tool_exceptions_total` | counter | `tool` |
| `gakudan_router_decisions_total` | counter | `router`, `decision_type` |
| `gakudan_router_decide_duration_seconds` | histogram | `router` |

High-cardinality keys (`run_id`, `turn`) deliberately stay out of metric
labels. They are still on the raw telemetry events for tracing or audit
sinks.

## Grafana dashboard

The starter dashboard ships four rows:

1. **Throughput.** Active runs gauge, runs/min, turns/min by agent.
2. **Cost.** Tokens/sec by model (input + output), top models by output tokens.
3. **Latency.** LLM request p50/p95/p99 by model, tool p50/p95 by tool.
4. **Errors.** LLM error rate, tool error rate, failed turns by agent.

Import `priv/grafana/gakudan.json` and pick your Prometheus datasource at
import time.

## Configuration

The application starts handlers automatically. To opt out:

```erlang
[{gakudan_metrics, [{auto_setup, false}]}].
```

Then call `gakudan_metrics:setup/0` yourself when you want them attached.

## License

MIT.
