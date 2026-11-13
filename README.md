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
3. **Sign a licence** for each sale:
   `vendor/bin/omnihub licence sign ~/.config/omnihub/my-studio.key payload.json`
   (Forge Seal's token form; see omnisense/omnihub's README for the payload).
4. **Change the key** (a new machine, a key you fear was seen) with a
   rotation the old key signs, so your users' Forge Store moves its pin
   without asking them:

   ```sh
   vendor/bin/omnihub key generate ~/.config/omnihub/my-studio-2.key
   vendor/bin/omnihub key rotate ~/.config/omnihub/my-studio.key ~/.config/omnihub/my-studio-2.key
   ```

   Paste the `licensing` section it prints (`publicKey`, `previousKey`,
   `rotation`), push, and sign with the new key from then on. `omnihub check`
   verifies the rotation before anything is published. Forge Store then
   checks licences against the new key only: **licences signed with the old
   key stop passing**, so sign your buyers' licences again with the new one.
   That is also why a leaked key is rotated at once.

The template ships no key: without a `licensing` section the hub sells
nothing and builds as before.

## How it is built

`vendor/bin/omnihub build hub.yaml _site` (omnisense/omnihub), after
`vendor/bin/omnihub check hub.yaml`, which lists every mistake in `hub.yaml`
at once, each with its key (`sources[1].pattern: ...`): the packages read
through omnihub/github, the registry's documents written once by the
same code a forge serves them with, the folder exported by omnibridge/static.
Unity reads documents GitHub Pages serves as `application/octet-stream` at
paths without extension, and a search whose query string the host ignores (it
holds every package; Unity filters by its scopes).

MIT.
