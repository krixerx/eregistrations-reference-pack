# CLAUDE.md

Guidance for Claude Code in this service pack repository. The pack is data
for the eRegistrations core: no code of its own runs. `README.md` explains
the layout.

The core is [krixerx/cib7-react-poc](https://github.com/krixerx/cib7-react-poc),
at the release `docker/core.conf` names.

## Rules

- **Spec first.** The markdown under `docs/business/services/<service>/` is
  the source of truth. Change a service by editing its spec and running the
  `/service-builder` skill (`.claude/skills/service-builder/SKILL.md`, here
  `<pack>` is this repository's root). Never hand-edit a generated file;
  commit the spec and the generated files together. If a spec is missing a
  required field, stop and ask.
- **The core is not here.** A change that needs core code (a TSX form, a new
  shared value rule, a new bean or endpoint, a new group or role) is a
  request to the core team, not something to work around in the pack.
- **Formats are the platform API** of the core release in
  `docker/core.conf` (`docs/platform-api.md` in the core repository, at that
  tag). Every format is strict: an unknown key refuses the whole file.
- **Security rules** are the core's (`docs/security.md` in the core
  repository): client-writable variables only through the generated
  variable policy and form schemas, `?json_string` / `.ftlh` escaping in
  templates, connectors only to the bus paths the platform API offers.

## Checks

`check.yml` runs the core's `scripts/pack-check.sh` against this pack at the
core release it names. Locally, from a checkout of the core at that tag
(JDK 21, Node 24):

```bash
<core>/scripts/pack-check.sh <this-repo>
```

## Updating the core

`scripts/update-core.sh <x.y.z>` sets the core release and vendors its
service-builder; never edit `.claude/skills/service-builder/` by hand.

## Publishing and deploying

A merge to `main` publishes the images (`publish.yml`, see `README.md`).
Deployment is not done from here: the core repository's Deploy to VM
workflow takes this repository's commit as `pack_ref`. Nothing in this
repository may hold a secret; the users file carries demo passwords only
for the reference instance.
