# M22 immutable authorized fixtures

Generated with `scripts/tools/export_planning_load.gd` from the unchanged M21
synchronous Rust C/D 30-day runs, seed42. Both complete source report hashes are
verified before export. Eight real decision observations (days1,3,15,30) retain
full float64/integer identity in Godot Variant bytes. `.request` contains only
M21's explicitly authorized job schema; `.proposal` is the complete original
proposal, not a substitute for computation. Manifest hashes guard all files.
No full world ledger is cached here; independent economic audits still run at
milestone acceptance. Regenerate only intentionally after specification review.

```sh
godot --headless --no-header --path . --script res://scripts/tools/export_planning_load.gd -- tests/fixtures/m22
```

Synthetic dispatcher task IDs are not additional world residents or authority.
