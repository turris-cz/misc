#!/bin/bash
mkdir -p meta/1.0
rm -f meta/1.0/index-system*
mkdir -p images
rm -rf images/*

die() {
    echo "$1"
    exit 1
}

DATE="`date +%Y-%m-%d`"

add_image() {
    echo "$1;$2;$3;default;$DATE;/images/$1/$2/$3/$DATE" >> meta/1.0/index-system.2
    echo "$1;$2;$3;default;$DATE;/images/$1/$2/$3/$DATE" >> meta/1.0/index-system
    mkdir -p "images/$1/$2/$3/$DATE"
    pushd "images/$1/$2/$3/$DATE"
    if [ -f "$4" ]; then
        mv "$4" .
    else
        wget "$4" || die "Downloading $1 $2 for $3 from $4 failed"
    fi
    FILE="`ls -1`"
    if expr "$FILE" : .*\\.tbz || expr "$FILE" : .*\\.tar.bz2; then
        bzip2 -d "$FILE"
        FILE="`echo "$FILE" | sed -e 's|\.tbz$|.tar|' -e 's|\.tar\.bz2$|.tar|'`"
    elif expr "$FILE" : .*\\.tgz || expr "$FILE" : .*\\.tar.gz; then
        gzip -d "$FILE"
        FILE="`echo "$FILE" | sed -e 's|\.tgz$|.tar|' -e 's|\.tar\.gz$|.tar|'`"
    elif expr "$FILE" : .*\\.tar.xz; then
        mv "$FILE" rootfs.tar.xz
        FILE=rootfs.tar.xz
    fi
    if [ "$FILE" \!= rootfs.tar.xz ]; then
        mv "$FILE" rootfs.tar
        xz rootfs.tar
    fi
    echo "Distribution $1 version $2 was just installed as a container." > create-message
    echo "" >> create-message
    echo "Content of the tarballs is provided by third party, thus there is no warranty of any kind nor support from Turris team." >> create-message
    echo "" >> create-message
    echo "Do not use containers on internal flash, they can wear it down really fast!!!" >> create-message
    echo "lxc.arch = armv7l" > config
    expr `date +%s` + 1209600 > expiry
    tar -cJf meta.tar.xz create-message config expiry
    rm -f create-message config expiry
    popd
}

get_gentoo_url() {
    REL="`wget -O - "http://distfiles.gentoo.org/releases/$1/autobuilds/latest-stage3-$2.txt" | sed -n 's|\(.*\.tar.xz\).*|\1|p'`"
    echo "http://distfiles.gentoo.org/releases/$1/autobuilds/$REL"
}

get_linaro_latest() {
    case "$1" in
        debian)
            echo https://releases.linaro.org/debian/images/developer-armhf/latest/
            ;;
        ubuntu)
            echo https://releases.linaro.org/ubuntu/images/developer/latest/
            ;;
    esac
}

get_linaro_release() {
    wget -O - `get_linaro_latest $1` | sed -n 's|.*href="/'"$1"'/images/.*/linaro-\([a-z]*\)-developer-[0-9]*-[0-9]*.tar.gz.*|\1|p'
}

get_linaro_url() {
    LIN_LATEST="`get_linaro_latest $1`"
    echo "https://releases.linaro.org`wget -O - $LIN_LATEST | sed -n 's|.*href="\(/'"$1"'/images/.*/latest/linaro-[a-z]*-developer-[0-9]*-[0-9]*.tar.gz\).*|\1|p'`"
}

get_lxc_url() {
    date="$(wget -O - https://images.linuxcontainers.org/images/$1/${2:-default} | sed -n 's|.*href="\./\(20[^/]*\)/.*|\1|p' | sort | tail -n 1)"
    echo "https://images.linuxcontainers.org/images/$1/${2:-default}/$date/rootfs.tar.xz"
}

get_opensuse_url() {
    URL="`wget -O - "$1" | sed -n 's|.*href="\([^"]*JeOS[^"]*rootfs[^"]*.tar.xz\)".*|\1|p' | head -n 1`"
    [ -n "$URL" ] || URL="`wget -O - "$1" | sed -n 's|.*href="\([^"]*JeOS[^"]*Snapshot[^"]*.tar.xz\)".*|\1|p' | head -n 1`"
    echo "$1/$URL"
}

add_image "Turris_OS" "HBS" "aarch64" "https://repo.turris.cz/hbs/medkit/mox-medkit-latest.tar.gz"
add_image "Turris_OS" "HBS" "armv7l" "https://repo.turris.cz/hbs/medkit/omnia-medkit-latest.tar.gz"
add_image "Turris_OS" "HBS" "ppc" "https://repo.turris.cz/hbs/medkit/turris1x-medkit-latest.tar.gz"
add_image "Alpine" "3.13" "armv7l" "`get_lxc_url alpine/3.13/armhf`"
add_image "Alpine" "3.13" "aarch64" "`get_lxc_url alpine/3.13/arm64`"
add_image "Alpine" "3.14" "armv7l" "`get_lxc_url alpine/3.14/armhf`"
add_image "Alpine" "3.14" "aarch64" "`get_lxc_url alpine/3.14/arm64`"
add_image "Alpine" "3.15" "armv7l" "`get_lxc_url alpine/3.15/armhf`"
add_image "Alpine" "3.15" "aarch64" "`get_lxc_url alpine/3.15/arm64`"
add_image "Alpine" "3.16" "armv7l" "`get_lxc_url alpine/3.16/armhf`"
add_image "Alpine" "3.16" "aarch64" "`get_lxc_url alpine/3.16/arm64`"
add_image "Alpine" "Edge" "armv7l" "`get_lxc_url alpine/edge/armhf`"
add_image "Alpine" "Edge" "aarch64" "`get_lxc_url alpine/edge/arm64`"
add_image "ArchLinux" "latest" "armv7l" "`get_lxc_url archlinux/current/armhf`"
add_image "ArchLinux" "latest" "aarch64" "`get_lxc_url archlinux/current/arm64`"
add_image "CentOS_Stream" "8" "aarch64" "`get_lxc_url centos/8-Stream/arm64`"
add_image "CentOS_Stream" "9" "aarch64" "`get_lxc_url centos/9-Stream/arm64`"
add_image "Debian" "Buster" "armv7l" "`get_lxc_url debian/buster/armhf`"
add_image "Debian" "Buster" "aarch64" "`get_lxc_url debian/buster/arm64`"
add_image "Debian" "Bullseye" "armv7l" "`get_lxc_url debian/bullseye/armhf`"
add_image "Debian" "Bullseye" "aarch64" "`get_lxc_url debian/bullseye/arm64`"
add_image "Fedora" "35" "aarch64" "`get_lxc_url fedora/35/arm64`"
add_image "Fedora" "36" "armv7l" "`get_lxc_url fedora/36/armhf`"
add_image "Fedora" "36" "aarch64" "`get_lxc_url fedora/36/arm64`"
add_image "Gentoo" "openrc" "armv7l" "`get_gentoo_url arm armv7a_hardfp-openrc`"
add_image "Gentoo" "systemd" "armv7l" "`get_gentoo_url arm armv7a_hardfp-systemd`"
add_image "Gentoo" "musl-openrc" "armv7l" "`get_gentoo_url arm armv7a_hardfp-musl-openrc`"
add_image "Gentoo" "openrc" "aarch64" "`get_gentoo_url arm64 arm64`"
add_image "Gentoo" "systemd" "aarch64" "`get_gentoo_url arm64 arm64-systemd`"
add_image "Gentoo" "musl-openrc" "aarch64" "`get_gentoo_url arm64 arm64-musl`"
add_image "openSUSE" "15.3" "armv7l" "`get_opensuse_url https://download.opensuse.org/ports/armv7hl/distribution/leap/15.3/appliances`"
add_image "openSUSE" "15.3" "aarch64" "`get_opensuse_url https://download.opensuse.org/ports/aarch64/distribution/leap/15.3/appliances`"
add_image "openSUSE" "Tumbleweed" "armv7l" "https://download.opensuse.org/ports/armv7hl/factory/appliances/opensuse-tumbleweed-image.armv7l-lxc.tar.xz"
add_image "openSUSE" "Tumbleweed" "aarch64" "https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/opensuse-tumbleweed-image.aarch64-lxc.tar.xz"
add_image "Ubuntu" "Bionic" "armv7l" "`get_lxc_url ubuntu/bionic/armhf`"
add_image "Ubuntu" "Bionic" "aarch64" "`get_lxc_url ubuntu/bionic/arm64`"
add_image "Ubuntu" "Focal" "armv7l" "`get_lxc_url ubuntu/focal/armhf`"
add_image "Ubuntu" "Focal" "aarch64" "`get_lxc_url ubuntu/focal/arm64`"
add_image "Ubuntu" "Jammy" "armv7l" "`get_lxc_url ubuntu/jammy/armhf`"
add_image "Ubuntu" "Jammy" "aarch64" "`get_lxc_url ubuntu/jammy/arm64`"
add_image "VoidLinux" "glibc" "aarch64" "`get_lxc_url voidlinux/current/arm64`"
add_image "VoidLinux" "glibc" "armv7l" "`get_lxc_url voidlinux/current/armhf`"
add_image "VoidLinux" "musl" "aarch64" "`get_lxc_url voidlinux/current/arm64 musl`"
add_image "VoidLinux" "musl" "armv7l" "`get_lxc_url voidlinux/current/armhf musl`"

if [ "`gpg -K`" ]; then
if [ -f ~/gpg-pass ]; then
    find . -type f -exec gpg --batch --no-tty --yes --passphrase-file ~/gpg-pass --pinentry-mode loopback --armor --detach-sign \{\} \;
else
    find . -type f -exec gpg -a --detach-sign \{\} \;
fi
fi
