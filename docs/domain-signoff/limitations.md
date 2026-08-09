# Accepted Synthetic Limitations

The evidence intentionally demonstrates these false-negative boundaries:

- invalid-Luhn card-like values are not payment detections;
- Unicode confusables and normalization variants are not resolved generally;
- unconfigured people, organizations, products, customers, and strategies are
  not semantically inferred;
- phone, domain, date, money, and token patterns are not globally exhaustive;
- a low verifier score covers supported rules only; and
- retained context may allow inference or re-identification.

Expected false positives include phone-like numeric strings, common-domain
patterns in benign prose, and configured terms used in a non-sensitive sense.
Transformations may reduce document utility or grammar.

An authorized domain reviewer must decide whether these boundaries and the
organization's manual review process are acceptable. This file records no such
approval.
