# Packages

A package of the hub is a GitHub repository whose root is a Unity package -
`package.json` with its `name` (`com.mystudio.tool`) and `version`, its files
and their `.meta` files - and whose releases carry the package's tarball.

## The tarball

npm's own: `npm pack` in the repository writes `<name>-<version>.tgz`, every
file under `package/`, which is what Unity's Package Manager installs. Attach
it to the release; the hub's build reads every published release, downloads
its `.tgz` once, reads its `package.json`, takes its sha1 and sha512, and points
Unity at the asset itself - the tarball stays on GitHub.

[package-release.yml](package-release.yml), copied into the package's
`.github/workflows/`, does it on each published release. Bump `version` in
`package.json`, publish a release (`v1.2.0`), done.

## Telling the hub

The hub publishes again every hour, and on each push to its own repository.
To have it publish at once when a package is released, give the package's
repository:

- a variable `HUB_REPOSITORY`: `owner/hub-repository`;
- a secret `HUB_TOKEN`: a fine-grained token of the hub's repository with
  "Contents: read and write" (repository_dispatch needs it).

## In a Unity project

The hub's page lists its packages and the lines to add to a project's
`Packages/manifest.json`; Window > Package Manager > My Registries then lists
them. A hub client - Forge Store, the Unity window (`io.glitchr.store`) -
takes the hub's manifest address, `https://<owner>.github.io/<repository>/-/hub.json`.
