# A Unity package hub on GitHub Pages

Your own Unity package registry, with no server, no database, no account:
**Use this template**, list your packages in `hub.yaml`, push. A GitHub
Action publishes on GitHub Pages:

- a **UPM scoped registry** as static files - what Unity's Package Manager
  reads (`/<package>`, `/-/v1/search`, `/-/all`); the tarballs stay as the
  GitHub Release assets of each package's repository;
- the **hub manifest** (`/-/hub.json`) that hub clients read: the Glitch Art
  Hub window in the Unity editor (`com.glitchr.hub`) and the desktop hub;
- a **page** that lists the packages and how to add the hub to a project.

Free and open: a static hub lists, installs and updates; it sells nothing
(its manifest declares no checkout).

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

Then Window > Package Manager > My Registries. Or, with the Glitch Art Hub
window: Sources > Add > Hub (manifest URL) >
`https://<owner>.github.io/<repository>/-/hub.json`.

## How it is built

`vendor/bin/omnihub build hub.yaml _site` (omnisense/omnihub): the packages
read through omnihub/github, the registry's documents written once by the
same code a forge serves them with, the folder exported by omnibridge/static.
Unity reads documents GitHub Pages serves as `application/octet-stream` at
paths without extension, and a search whose query string the host ignores (it
holds every package; Unity filters by its scopes).

MIT.
