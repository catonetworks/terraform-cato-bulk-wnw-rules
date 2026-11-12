# Changelog

## 0.0.2 (2026-11-04)

### Features
- Added `allow_empty_policy` safety guard — planning fails when the policy
  JSON contains 0 rules unless explicitly allowed, protecting against
  truncated or wrong-tenant exports mass-destroying a live policy.
- README: brownfield import documentation now covers two options — native
  Terraform `import` blocks (recommended, declarative/previewable) and the
  `catocli import wnw_rules_to_tf` imperative alternative.

## 0.0.1 (2025-07-05)

### Features
- Initial bulk wf rule module release
