# immanip

An initial C library scaffold for image manipulation. No image operations are
implemented yet; the only API reports the library version.

## Build and test

Install a C compiler and CMake (3.16 or newer), then run:

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

The project installs a shared library, headers, a CMake package
(`find_package(immanip CONFIG REQUIRED)` and `immanip::immanip`), and pkg-config
metadata (`pkg-config --cflags --libs immanip`).

## Debian packages

On Debian or Ubuntu, install `dpkg-dev` and run the build commands above, then:

```sh
cpack --config build/CPackConfig.cmake -B dist
cpack --config build/CPackSourceConfig.cmake -B dist
sudo apt install ./dist/libimmanip0_*.deb ./dist/libimmanip-dev_*.deb
```

The runtime package contains the shared library; the development package
contains the headers and build integration. Both packages must be from the
same build and architecture. The source archive is also created in `dist/`.
GitHub Actions builds and tests these artifacts on Ubuntu 24.04 and makes them
available from each workflow run. Version tags also publish an apt repository
once the setup below is complete. GitHub releases are not created.

## Publish the apt repository

The workflow publishes a signed `stable` repository to GitHub Pages when a
`vMAJOR.MINOR.PATCH` tag is pushed. It retains all previous `.deb` files in
the `apt-repository` branch. Packages currently target **Ubuntu 24.04 amd64**;
they are not yet tested on other distributions or architectures.

One-time setup:

1. Push this project to GitHub. Under **Settings > Pages**, choose **GitHub
   Actions** as the build and deployment source. Ensure repository Actions
   settings permit GitHub Actions to create deployments and push contents.
2. On a trusted machine, create a dedicated passphrase-protected signing key:
   `gpg --full-generate-key`. Back up the private key securely. Find its full
   primary fingerprint with `gpg --list-secret-keys --fingerprint`.
3. Under **Settings > Secrets and variables > Actions**, add the repository
   variable `APT_GPG_FINGERPRINT` containing the 40-character uppercase
   fingerprint without spaces. Add the secrets `APT_GPG_PRIVATE_KEY` (the
   complete armored private key from `gpg --armor --export-secret-keys
   YOUR_FINGERPRINT`) and `APT_GPG_PASSPHRASE`. Keep the private key and
   passphrase out of the repository and logs. Delete any temporary key export
   files securely according to your environment's practices.
4. Publish the fingerprint through an independently trusted channel so users
   can verify the downloaded key. Protect release tags and the
   `apt-repository` branch from unauthorized changes; the workflow must retain
   permission to update that branch. The `github-pages` environment may need
   approval or deployment rules that permit release tags.
5. Set the version in `CMakeLists.txt`, commit it, and push a matching tag,
   for example `git tag v0.1.0` followed by `git push origin v0.1.0`. A tag
   that does not match the generated package version fails. Do not reuse
   package versions: existing package files are immutable. If a deployment
   fails after saving package history, use **Re-run failed jobs** on the same
   workflow run so it uses the original build artifact.

The first successful deployment creates the `apt-repository` branch. Do not
delete or manually rewrite it: it is the source of the retained package
history. Changing the signing key requires a separate key-rotation migration;
the workflow rejects a different key rather than silently breaking clients.

### Install from the repository

Replace `OWNER` and `REPOSITORY` with the GitHub account and repository name.
For a GitHub Pages site with a custom domain or a user/organization site,
use its actual Pages URL instead.

```sh
curl -fsSLo immanip-archive-keyring.gpg \
  https://OWNER.github.io/REPOSITORY/immanip-archive-keyring.gpg
gpg --show-keys --fingerprint immanip-archive-keyring.gpg
# Verify the fingerprint through the maintainer's independently trusted channel.
sudo install -m 0644 immanip-archive-keyring.gpg \
  /usr/share/keyrings/immanip-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/immanip-archive-keyring.gpg] https://OWNER.github.io/REPOSITORY stable main" |
  sudo tee /etc/apt/sources.list.d/immanip.list
sudo apt update
sudo apt install libimmanip-dev
```

## License

MIT; see [LICENSE](LICENSE).
