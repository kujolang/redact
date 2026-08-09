# Expected Synthetic Detections

| Synthetic case | Expected stable result |
| --- | --- |
| `morgan@example.com` | Email and overlapping documented domain pattern; email replacement wins. |
| `+1 (555) 010-1000` | Phone-like value removed. |
| `https://example.com/demo` | URL/domain placeholder. |
| `4111 1111 1111 1111` | Luhn-valid test candidate removed as payment detail. |
| `4111 1111 1111 1112` | Invalid-Luhn candidate remains for review. |
| `sk-EXAMPLE1234567890` | Fake token pattern removed. |
| `2026-10-15` | Exact date generalized. |
| `$42,000` | Money amount mapped to a magnitude bucket. |
| Configured person/company/customer/product/strategy terms | Longest-first, case-insensitive configured match and policy transform. |
| Unicode configured term | Exact configured Unicode sequence transforms. |
| Confusable near-miss | Remains; human review is required. |

Repeated exact values receive the same replacement. Pack files are processed
in sorted filename order.
