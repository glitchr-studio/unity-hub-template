# A Unity package hub on GitHub Pages

Your own Unity package registry, with no server, no database, no account:
**Use this template**, list your packages in `hub.yaml`, push. A GitHub
Action publishes on GitHub Pages:

- a **UPM scoped registry** as static files - what Unity's Package Manager
  reads (`/<package>`, `/-/v1/search`, `/-/all`); the tarballs stay as the
  GitHub Release assets of each package's repository;
- the **hub manifest** (`/-/hub.json`) that hub clients read: Forge Store,
  the window in the Unity editor (`io.glitchr.store`), and Forge Hub, the
  desktop app;
- a **page** that lists the packages and how to add the hub to a project.

Free and open: a static hub lists, installs and updates. It has no checkout
of its own; it can still sell, with licences you sign offline (see
[Selling with licences](#selling-with-licences)).

## Set up

1. **Use this template** (top right), then in your copy: Settings > Pages >
   Build and deployment > Source: **GitHub Actions**.
2. Edit `hub.yaml`: your hub's name, look and packages (`github: owner/repository`).
3. Push. The **Publish the hub** workflow builds and deploys; your hub is at
   `https://<owner>.github.io/<repository>/`.
4. In each package's repository, attach the package's tarball to its releases:
   copy [docs/package-release.yml](docs/package-release.yml) - see
   [docs/packages.md](docs/packages.md).

## In Unity

```json
"scopedRegistries": [
  {"name": "My Studio", "url": "https://<owner>.github.io/<repository>", "scopes": ["com.mystudio"]}
]
```

Then Window > Package Manager > My Registries. Or, in Forge Store
(Window > Forge Store): Sources > Add > Hub (manifest URL) >
`https://<owner>.github.io/<repository>/-/hub.json`.

## Its look: `theme`

```yaml
theme:
  accent: "#336699"       # Unity's light skin
  accentDark: "#6699cc"   # its dark skin
  logo: logo.png          # a file of this repository, published with the hub - or https://
  banner: banner.png
```

Data only, never code. The colours are `#rgb` or `#rrggbb` (quote them:
YAML reads `#` as a comment); the pictures are files of this repository or
`https://` addresses, 1 MB at most. The manifest carries them as
`"theme": {"accent", "accentDark", "logo", "banner"}` - the files' addresses
made absolute - and also as the older `color` and `logo` keys. Forge Store
draws the accent and the logo; the banner is for the clients with room for
one, and heads the hub's page.

## A GitHub owner as a source

```yaml
sources:
  - { name: Acme on GitHub, type: github, owner: acme, pattern: "unity-*", install: false }
```

Every repository of the organisation or user `owner` whose name matches
`pattern` (`*` any run of characters, `?` one, several patterns separated by
commas, case ignored) and whose root holds a `package.json` naming a
package. `install: true` marks them as packages every project of the team
gets (Forge Hub's Prepare writes them in).

By default the source is written into `hub.json` as it is, and each hub
client resolves it through GitHub's REST API with the user's own GitHub
token: a team's members see its private repositories too, and a new
repository shows without publishing the hub again.

To resolve it when the hub is built instead - for clients without GitHub
support, or to freeze the list - set the repository variable
`HUB_RESOLVE_GITHUB` to `true` (Settings > Secrets and variables > Actions >
Variables). The build then lists the owner's **public** repositories only (a
static hub is public; a private repository is never read, even with a token
that could), each written as a `git` source at its newest version tag. The
answers' ETags are kept in the Actions cache between builds and the API's
rate limit is respected; a source that cannot be resolved is left as it is.
Nothing is scraped: the REST API only.

## Selling with licences

A static hub has no server: it counts no seats and revokes nothing. It can
still sell - a "get" link to any shop (Gumroad, a Stripe Payment Link...),
and a licence key you sign on your own machine and send to the buyer, who
pastes it into Forge Store or Forge Hub. Light protection, not DRM: an
offline key can be shared.

1. **Make a key pair**, on your machine, **outside this repository**:

   ```sh
   composer install
   vendor/bin/omnihub key generate ~/.config/omnihub/my-studio.key
   ```

   The private key is written to that file only (readable by you only, never
   over an existing file; a warning if the path is inside a git work tree).
   Keep a copy in a password manager. It must never be committed, put in
   `hub.yaml`, or stored as an Actions secret: the build never needs it.
2. **Publish the public key**: uncomment `licensing` in `hub.yaml` and paste
   the `publicKey` that `key generate` printed. Forge Store pins it the first
   time a user adds your hub, and checks your licences against the pinned key.
3. **Sign a licence** for each sale, in this repository's folder (the
   commands read `./hub.yaml`; give it `url: https://<owner>.github.io/<repository>`,
   the address the workflow publishes at):

   ```sh
   token=$(vendor/bin/omnihub licence sign ~/.config/omnihub/my-studio.key \
       --package com.mystudio.tool --licensee "Ada <ada@example.org>" \
       --days 365 --log ~/.config/omnihub/sales.jsonl)
   vendor/bin/omnihub licence verify hub.yaml "$token" --package com.mystudio.tool
   echo "$token"   # the line to send to the buyer
   ```

   The registry the licence names and the key it is checked against come
   from `hub.yaml`: `licence sign` refuses a key that is not the one
   `licensing.publicKey` publishes. The token is one line on stdout (a
   summary goes to stderr); `licence verify` says what Forge Store will say
   ("Forge Store opens it.", or why it refuses it). Send that line to the
   buyer (nothing is written into this repository), who pastes it under the
   package's **Enter a licence** in Forge Store. Without `--days` (or `--valid-until <YYYY-MM-DD>`) it has no end;
   without `--machine` or `--machine-hash` it opens on any machine. To bind it
   to one machine, ask the buyer for **This machine's licence id** (Forge
   Store shows it under Enter a licence, with Copy) and sign with
   `--machine-hash <that id>`.
4. **Change the key** (a new machine, a key you fear was seen) with a
   rotation the old key signs, so your users' Forge Store moves its pin
   without asking them:

   ```sh
   vendor/bin/omnihub key generate ~/.config/omnihub/my-studio-2.key
   vendor/bin/omnihub key rotate ~/.config/omnihub/my-studio.key ~/.config/omnihub/my-studio-2.key [--previous-until 2026-12-31]
   ```

   Paste the `licensing` section it prints (`publicKey`, `previousKey`,
   `rotation`, `previousKeyValidUntil`), push, and sign with the new key from
   then on. `omnihub check` verifies the rotation before anything is
   published. Forge Store keeps opening the licences the old key signed
   until `previousKeyValidUntil` (30 days after `key rotate` unless
   `--previous-until`), and never longer than 30 days after a user sees the
   rotation: **licences signed with the old key, those without an end too,
   stop opening by then.** Sign them again with the new key from your sales
   log and send each buyer their new line:

   ```sh
   vendor/bin/omnihub licence resign ~/.config/omnihub/my-studio-2.key ~/.config/omnihub/sales.jsonl --log ~/.config/omnihub/sales.jsonl
   ```

   It prints `licensee<TAB>package<TAB>token`, one licence per line, each as
   it was sold (those that ran out, and those the new key already signed,
   are left); `--log` adds the new ones to the log for the next rotation.
   A leaked key is rotated at once all the same: the shorter
   `--previous-until`, the sooner what it signs stops opening.

**What you sell: `licensed`.** A static hub has no catalogue, so list the
packages that take a licence, each with the address where one is bought
(`get`, https, optional):

```yaml
licensed:
  - { package: com.mystudio.tool, get: "https://mystudio.example/buy/tool" }
```

The build writes it into `hub.json` (only beside `licensing`) and the hub's
page links each `get`. Forge Store then shows **Get** and **Enter a
licence** on those packages only; your other packages are free. Without
`licensed`, it offers the licence field on every package of a hub that
publishes a key.

**The sales log.** `--log` appends one line per licence: its payload and the
key's fingerprint - never the key, the token only with `--log-token`;
created readable by you only. It names your buyers: like the private key,
**keep it out of this repository** (a path such as `~/.config/omnihub/`, as
above; omnihub warns when either is inside a git work tree). It is what
`licence resign` reads after a rotation.

What a static hub's licence checks: the store, the package, an end, and one
machine when you asked for it. What it cannot: seats and revocation - a
copied line opens wherever it is pasted. A light protection, not DRM.

The template ships no key: without a `licensing` section the hub sells
nothing and builds as before.

## The commands and their flags

Run in this repository's folder, after `composer install`
(`vendor/bin/omnihub ...`). A misspelt flag is refused, never ignored. A day
is `YYYY-MM-DD` (its first second, UTC) or UNIX seconds. Private keys stay
outside this repository; no command prints one.

**`key generate <private-key-file>`** - a new Ed25519 pair. The private key
is written to that file only (readable by you only; never over an existing
file; a warning when the path is inside a git work tree); the `licensing`
section with its `publicKey` is printed for `hub.yaml`. No flag.

**`key public <private-key-file>`** - prints the public key of a private key
(what `licensing.publicKey` must be). No flag.

**`key rotate <old-private-key-file> <new-public-key|new-private-key-file>`**
- the old key signs the hand-over to the new one; prints the `licensing`
section to paste (`publicKey`, `previousKey`, `rotation`,
`previousKeyValidUntil`).

| Flag | |
|---|---|
| `--previous-until <day>` | until when licences the old key signed still open (`previousKeyValidUntil`); default 30 days from now |

**`licence sign <private-key-file> [payload.json|-]`** - one licence; the
token alone on stdout (one line, for the buyer), a summary on stderr.

| Flag | |
|---|---|
| `--package <upm-name>` | the package it opens (a warning when `licensed` does not list it) |
| `--software <slug>` | a game or an application instead of a package |
| `--licensee <text>` | required: who bought it (200 characters at most) |
| `--hub <hub.yaml>` | default `./hub.yaml`: the registry from its `url:`, and the key checked against its `licensing.publicKey` |
| `--registry <url>` | instead of a hub.yaml: the hub's address, https |
| `--valid-until <day>` or `--days <n>` | an end; without either, none |
| `--updates-until <day>` | the newest releases it covers; without it, every release |
| `--machine <identifier>` | one machine, hashed here (never written in clear) |
| `--machine-hash <64 hex>` | one machine, by the id the buyer copied from Forge Store (**This machine's licence id**) |
| `--issued-at <day>` | default now |
| `--log <file.jsonl>` | appends the licence's payload and the key's fingerprint (never the key) to your sales log, outside this repository |
| `--log-token` | with `--log`: the token too |

Without `--machine` or `--machine-hash` it opens on any machine. A payload
file (or `-` for stdin) is still read; the flags override it.

**`licence verify <public-key|hub.yaml|hub.json> <token|->`**, or
**`licence verify <token|-> --hub <hub.yaml|hub.json>`** /
**`--key <public-key>`** - says what Forge Store will say ("Forge Store opens
it.", exit 0; or why it refuses it, exit 1). Public keys only.

| Flag | |
|---|---|
| `--registry <url>` | the registry to compare with (otherwise the hub's) |
| `--package <upm-name>` / `--software <slug>` | the package or software it must open |
| `--machine <identifier>` / `--machine-hash <64 hex>` | the machine it must open on |
| `--at <day>` | checked as of that day instead of now |

What is not given is said not compared.

**`licence resign <new-private-key-file> <sales-log.jsonl>`** - after a
rotation, every licence of the log signed again with the new key, as it was
sold; prints `licensee<TAB>package<TAB>token` per licence (those that ran
out, and those the new key already signed, are left).

| Flag | |
|---|---|
| `--hub <hub.yaml>` / `--registry <url>` | as for `licence sign` |
| `--log <file.jsonl>` | appends the new licences to a log (the same file is fine), for the next rotation |
| `--log-token` | with `--log`: the tokens too |

**`check <hub.yaml> [--url=<address>]`** and **`build <hub.yaml> <folder>
[--url=<address>] [--strict] [--resolve-github [--github-cache=<file>]]`** -
what the workflow runs (below).

## How it is built

`vendor/bin/omnihub build hub.yaml _site` (omnisense/omnihub), after
`vendor/bin/omnihub check hub.yaml`, which lists every mistake in `hub.yaml`
at once, each with its key (`sources[1].pattern: ...`): the packages read
through omnihub/github, the registry's documents written once by the
same code a forge serves them with, the folder exported by omnibridge/static.
`--strict` fails the build on a broken link or an export error.
Unity reads documents GitHub Pages serves as `application/octet-stream` at
paths without extension, and a search whose query string the host ignores (it
holds every package; Unity filters by its scopes).

MIT.
