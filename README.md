# Reference service pack

The services, texts, branding and users of one eRegistrations deployment,
as data for the eRegistrations core. This pack ships two services,
`vehicleRegistration` and `businessRegistration`. The core (engine,
backend, portal, mobile app, MCP sidecar, bus) is a separate, versioned
product: this pack names the core release it runs on in
[`docker/core.conf`](docker/core.conf), and a core update reaches it as a
version bump, not a merge.

Core and pack meet only through the formats of the core's
[platform API](https://github.com/krixerx/cib7-react-poc/blob/main/docs/platform-api.md);
`pack.yaml` says which platform API this pack is written for.

## What is here

| Path | What |
|---|---|
| `pack.yaml` | name, version, platform API |
| `docs/business/services/<service>/` | the specs, the source of everything generated below, and `build/` (MCP manifests) |
| `engine/` | BPMN, DMN, variable policies, form schemas, payload templates, PDF and email documents |
| `backend/` | registries and their migrations, co-signing, fees, document categories |
| `frontend/` | catalog, form definitions, texts in every language |
| `branding/` | logo, colours, portal name |
| `keycloak/` | the realm's users (they join the core's groups) |
| `docker/` | the pack's images, each a thin layer on a core image; `core.conf` names the core release |
| `.claude/skills/service-builder/` | the service-builder of that core release (vendored by `scripts/update-core.sh`) |
| `.github/workflows/` | `check.yml` (the core's pack-check at that release), `publish.yml` (the images) |

## Changing a service

Specs first: edit the markdown under `docs/business/services/<service>/`,
run `/service-builder` in Claude Code, and commit the spec with what it
generated. Never hand-edit a generated file. A pull request runs the core's
pack checks; a merge to `main` publishes the images.

Each spec also carries the service's tests as examples (decision and fee
examples, registry seeds, submission and behaviour examples, template
examples, flow scenarios); the core's pack checks run them, so a rule change
comes with the example that shows it.

## Publishing the images

`publish.yml` builds the five layers on the core images of the release in
`docker/core.conf`, scans each with that release's accepted findings, and
pushes them as `<IMAGE_PREFIX>-<layer>`, tagged `latest`, the commit's
7-character SHA and the `version` from `pack.yaml`. It needs, under the
repository's Settings → Secrets and variables → Actions:

| Name | Kind | Value |
|---|---|---|
| `IMAGE_PREFIX` | variable | e.g. `docker.io/krixerx/eregistrations-reference` |
| `REGISTRY` | variable, optional | registry host, default `docker.io` |
| `REGISTRY_USERNAME` | secret | the registry account |
| `REGISTRY_TOKEN` | secret | an access token with write access |

Bump `version` in `pack.yaml` when the pack changes in a way an operator
should see; the SHA tag is what deployments pin.

## Deploying

An instance runs this pack's images on the core's deploy kit (`deploy/` in
the core repository). The core's **Deploy to VM** workflow takes this
repository's commit as `pack_ref` (default `main`): it reads the core
release from `docker/core.conf`, checks that this commit's images exist,
ships `keycloak/cib7-poc-users-0.json` and `branding/` to the host's
`pack/`, and pins the image tags in the host's `.env`. Publish first, wait
for `publish.yml` to finish, then deploy. Rolling back is deploying an older
commit. The users file is imported only on Keycloak's first start, so a
change to it needs the instance's Keycloak recreated (and the engine
restarted after it).

## Moving to another core release

```bash
scripts/update-core.sh <x.y.z>   # CORE_VERSION + the matching service-builder
```

Renovate proposes new core releases by changing `docker/core.conf`; that pull
request fails `check.yml` until `scripts/update-core.sh` has run in it,
because the vendored service-builder must come from the same release. Read
the core release notes first: a new platform API major means changing the
pack.

## Building the images by hand

```bash
. docker/core.conf
docker build -f docker/engine.Dockerfile \
  --build-arg ENGINE_CORE=$CORE_IMAGES/cib7-poc-cib7-core:$CORE_VERSION .
```

The same for `frontend`, `backend`, `mcp` and `mobile` (`FRONTEND_CORE`,
`BACKEND_CORE`, `MCP_CORE`, `MOBILE_CORE`, core images
`cib7-poc-<name>-core`).
