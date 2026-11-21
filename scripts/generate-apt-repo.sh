#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 REPOSITORY_DIR PACKAGE_DIR VERSION" >&2
    exit 1
fi

repo=$(realpath "$1")
packages=$(realpath "$2")
version=$3
fingerprint=${APT_GPG_FINGERPRINT:?Set APT_GPG_FINGERPRINT to the signing key fingerprint}
: "${APT_GPG_PASSPHRASE:?Set APT_GPG_PASSPHRASE to the signing key passphrase}"

if [[ ! $fingerprint =~ ^[0-9A-F]{40}$ ]]; then
    echo "APT_GPG_FINGERPRINT must be a full uppercase 40-character fingerprint" >&2
    exit 1
fi

key_fingerprint() {
    gpg --batch --with-colons --show-keys "$1" |
        awk -F: '$1 == "fpr" && !found { print $10; found = 1 }'
}

if [[ -f "$repo/immanip-archive-keyring.gpg" ]] &&
    [[ $(key_fingerprint "$repo/immanip-archive-keyring.gpg") != "$fingerprint" ]]; then
    echo "The existing repository uses a different signing key; key rotation requires a migration" >&2
    exit 1
fi

mkdir -p "$repo/pool/main" "$repo/dists/stable/main/binary-amd64"
for name in libimmanip0 libimmanip-dev; do
    package="$packages/${name}_${version}_amd64.deb"
    if [[ ! -f $package ]] ||
        [[ $(dpkg-deb -f "$package" Package) != "$name" ]] ||
        [[ $(dpkg-deb -f "$package" Version) != "$version" ]] ||
        [[ $(dpkg-deb -f "$package" Architecture) != amd64 ]]; then
        echo "Missing or invalid package: $package" >&2
        exit 1
    fi
    destination="$repo/pool/main/$(basename "$package")"
    if [[ -e $destination ]]; then
        if ! cmp -s "$package" "$destination"; then
            echo "Refusing to overwrite an existing package: $destination" >&2
            exit 1
        fi
    else
        cp "$package" "$destination"
    fi
done

gpg --batch --export "$fingerprint" > "$repo/immanip-archive-keyring.gpg"
if [[ ! -s "$repo/immanip-archive-keyring.gpg" ]] ||
    [[ $(key_fingerprint "$repo/immanip-archive-keyring.gpg") != "$fingerprint" ]]; then
    echo "Could not export the expected public signing key" >&2
    exit 1
fi

cd "$repo"
apt-ftparchive packages pool/main > dists/stable/main/binary-amd64/Packages
gzip -n -k -f dists/stable/main/binary-amd64/Packages
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=Immanip \
    -o APT::FTPArchive::Release::Label=Immanip \
    -o APT::FTPArchive::Release::Suite=stable \
    -o APT::FTPArchive::Release::Codename=stable \
    -o APT::FTPArchive::Release::Architectures=amd64 \
    -o APT::FTPArchive::Release::Components=main \
    release dists/stable > dists/stable/Release
gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 \
    --local-user "$fingerprint" --clearsign \
    --output dists/stable/InRelease dists/stable/Release 3<<<"$APT_GPG_PASSPHRASE"
gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 \
    --local-user "$fingerprint" --armor --detach-sign \
    --output dists/stable/Release.gpg dists/stable/Release 3<<<"$APT_GPG_PASSPHRASE"
