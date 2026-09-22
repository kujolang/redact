# Synthetic Kujo 1.4.0 performance check

Local macOS x64 measurements on the released Kujo 1.4.0 runtime, commit
`266a8902068a14c3d17f803bef467dc28f1fe162`. These are observations,
not service-level guarantees or a cross-platform benchmark. The existing
[`performance.json`](performance.json) records a historical Kujo 1.0.0 run;
its timings are not a like-for-like comparison with this runtime.

| Synthetic workload | Previously committed code on 1.4.0 | Hardened candidate on 1.4.0 |
| --- | --- | --- |
| Small dictionary, three samples | 1.717 s median; 20.7 MB peak child RSS | 0.553 s median; 18.0 MB peak child RSS |
| 1 MiB text, 253,125-byte policy, 1,050 absent terms | Exceeded 30-second timeout | 9.922 s; 35.9 MB peak child RSS |
| 1 MiB text, 65,536 repeats of one ASCII term | 17.361 s; 492.7 MB peak child RSS | 1.398 s; 77.5 MB peak child RSS |
| 1 MiB Unicode text, one absent Greek term | Not measured in the previous run | 14.348 s; 269.6 MB peak child RSS |
| Sixteen 64 KiB synthetic files in a 1 MiB pack | Not measured in the previous run | 5.320 s; 19.4 MB peak child RSS |

For the small and repeated dictionaries, the before and after SHA-256 of output matched.
The upper-bound fixture contains only synthetic, absent ASCII terms; it is
not representative of all dictionaries. The previous implementation timed
out before producing a comparable output hash or peak-memory sample. Peak
RSS is the operating system's cumulative child-process high-water mark, not
an allocation profile. Run `KUJO_BIN=/path/to/kujo python3
scripts/benchmark.py --workload max-dictionary --samples 1 --timeout 30` to
repeat the new case. For contextual Unicode term matching, a 2,000,000
scalar-candidate admission budget returns an error for larger combinations;
this is not a total wall-clock or memory bound for every valid input.

Neither a low verifier score nor these timings establish complete detection,
enterprise readiness, or fitness for an unreviewed data domain.
The repeated-term result uses native, literal ASCII matching to avoid copying
the entire input for each occurrence. Unicode matching deliberately retains
context-sensitive candidate evaluation. Its observed 269.6 MB peak is a
meaningful cost for a 1 MiB document, not a memory ceiling or a guarantee for
other combinations. The hosted install-smoke matrix logs these four workloads
on supported platforms without treating timings as universal thresholds;
Windows reports time but no peak RSS when the Python `resource` module is
unavailable.
