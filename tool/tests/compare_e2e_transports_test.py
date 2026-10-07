import importlib.util
import pathlib
import sys
import unittest


SPEC = importlib.util.spec_from_file_location(
    "compare_e2e_transports", pathlib.Path(__file__).parents[1] / "compare_e2e_transports.py",
)
benchmark = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = benchmark
SPEC.loader.exec_module(benchmark)


class RequestBenchmarkTest(unittest.TestCase):
    def records(self):
        return [{"kind": "request", "route": "rest", "scenario": "small", "cache": False,
                 "phase": "sample", "index": index, "success": True, "digest": "same",
                 "rows": 1, "completionMs": 100 + index, "rssBytes": 1000,
                 "rssGrowthBytes": 10, "diagnostics": {"phasesMs": {"first_rows": 50}, "transport": "rest", "cacheHit": False}}
                for index in range(100)]

    def test_bootstrap_time_is_not_sql_latency(self):
        rows = self.records()
        rows.insert(0, {"kind": "bootstrap", "ms": 999999})
        rows.insert(0, {"kind": "process", "ms": 9999999})
        summary = benchmark.summarize_requests(rows, 100)[0]
        self.assertEqual(summary["p50Ms"], 149.5)
        self.assertEqual(summary["firstRowP95Ms"], 50)

    def test_missing_duplicate_and_failed_samples_are_rejected(self):
        for mutate in (lambda rows: rows.pop(), lambda rows: rows.append(rows[0]),
                       lambda rows: rows[0].update(success=False)):
            rows = self.records()
            mutate(rows)
            with self.assertRaises(ValueError):
                benchmark.summarize_requests(rows, 100)

    def test_transport_data_mismatch_is_rejected(self):
        rows = self.records()
        other = dict(rows[0], route="relay", digest="different")
        with self.assertRaises(ValueError):
            benchmark.summarize_requests(rows + [other], 100)

    def test_fallback_is_not_a_successful_sample_of_the_requested_transport(self):
        rows = self.records()
        rows[0]["diagnostics"]["transport"] = "relay"
        with self.assertRaises(ValueError):
            benchmark.summarize_requests(rows, 100)

    def test_empty_measurements_never_approve_performance(self):
        self.assertFalse(benchmark.approve_against_baseline([], []))

    def test_failed_requests_count_timeouts_without_counting_bootstrap(self):
        rows = self.records()
        rows[0].update(success=False, timeout=True)
        rows[1].update(success=False, timeout=False)
        rows.insert(0, {"kind": "bootstrap", "ms": 1000})
        summary = benchmark.summarize_failures(rows)[0]
        self.assertEqual(summary["observedRequests"], 100)
        self.assertEqual(summary["errors"], 2)
        self.assertEqual(summary["timeouts"], 1)

    def test_performance_gate_checks_latency_throughput_and_equivalence(self):
        baseline = benchmark.summarize_requests(self.records(), 100)
        self.assertTrue(benchmark.approve_against_baseline(baseline, baseline))
        for changes in ({"p95Ms": baseline[0]["p95Ms"] * 1.051},
                        {"throughput": baseline[0]["throughput"] * .849},
                        {"digest": "different"}, {"errors": 1}, {"timeouts": 1}):
            candidate = [dict(baseline[0], **changes)]
            self.assertFalse(benchmark.approve_against_baseline(candidate, baseline))


if __name__ == "__main__":
    unittest.main()
