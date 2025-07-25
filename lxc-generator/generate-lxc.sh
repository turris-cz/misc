#!/bin/bash
mkdir -p meta/1.0
rm -f meta/1.0/index-system*
rm -f meta/1.0/index-user*
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
    echo "$1;$2;$3;default;$DATE;/images/$1/$2/$3/$DATE" >> meta/1.0/index-user
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
    date="$(wget -O - https://images.linuxcontainers.org/images/$1/${2:-default} | sed -n 's|.*href="\(20[^/]*\)/.*|\1|p' | sort | tail -n 1)"
    echo "https://images.linuxcontainers.org/images/$1/${2:-default}/$date/rootfs.tar.xz"
}

get_opensuse_url() {
    URL="`wget -O - "$1" | sed -n 's|.*href="\([^"]*JeOS[^"]*rootfs[^"]*'"$2"'[^"]*.tar.xz\)".*|\1|p' | head -n 1`"
    [ -n "$URL" ] || URL="`wget -O - "$1" | sed -n 's|.*href="\([^"]*JeOS[^"]*Snapshot[^"]*'"$2"'[^"]*.tar.xz\)".*|\1|p' | head -n 1`"
    echo "$1/$URL"
}

get_alpine_url() {
    VER="$1"
    [ "$1" = edge ] || VER="v$VER"
    URL="https://dl-cdn.alpinelinux.org/alpine/$VER/releases/$2"
    URL="`wget -O - "$URL/latest-releases.yaml" | sed -n 's|.*file: \(alpine-minirootfs-.*\)|'"$URL"'/\1|p'`"
    echo "$URL"
}

get_maurerr_url() {
    DIST=$1
    VER=$2
    ARCH=$3
    REL_DATE=$(wget -O - "https://maurerr.github.io/lxc/images/$DIST/$VER/$ARCH/" | grep -Eo '<a\ href=\"[0-9].*\">' | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    URL="https://maurerr.github.io/lxc/images/$DIST/$VER/$ARCH/$REL_DATE/rootfs.tar.xz"
    echo "$URL"
}

get_ubuntu_url() {
    VER="$1"
    ARCH="$2"
    URL="https://cloud-images.ubuntu.com/releases/$VER/release/ubuntu-$VER-server-cloudimg-$ARCH-root.tar.xz"
    echo "$URL"
}

get_openwrt_url() {
    VER="$1"
    ARCH="$2"
    if [ "$ARCH" = arm64 ]; then
        ARCH="cortexa53"
    elif [ "$ARCH" = armv7l ]; then
        ARCH="cortexa9"
    fi
    if [ "$VER" = snapshot ]; then
        URL="https://downloads.openwrt.org/snapshots/targets/mvebu/$ARCH/openwrt-mvebu-$ARCH-rootfs.tar.gz"
    else
        URL="https://downloads.openwrt.org/releases/$VER/targets/mvebu/$ARCH/openwrt-$VER-mvebu-$ARCH-rootfs.tar.gz"
    fi
    echo "$URL"
}

add_image "Turris_OS" "HBS" "aarch64" "https://repo.turris.cz/hbs/medkit/mox-medkit-latest.tar.gz"
add_image "Turris_OS" "HBS" "armv7l" "https://repo.turris.cz/hbs/medkit/omnia-medkit-latest.tar.gz"
add_image "Turris_OS" "HBS" "ppc" "https://repo.turris.cz/hbs/medkit/turris1x-medkit-latest.tar.gz"
add_image "Alpine" "3.21" "armv7l" "`get_alpine_url 3.21 armhf`"
add_image "Alpine" "3.21" "aarch64" "`get_alpine_url 3.21 aarch64`"
add_image "Alpine" "3.22" "armv7l" "`get_alpine_url 3.22 armhf`"
add_image "Alpine" "3.22" "aarch64" "`get_alpine_url 3.22 aarch64`"
add_image "Alpine" "Edge" "armv7l" "`get_alpine_url edge armhf`"
add_image "Alpine" "Edge" "aarch64" "`get_alpine_url edge aarch64`"
add_image "ArchLinux" "latest" "armv7l" "http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz"
add_image "ArchLinux" "latest" "aarch64" "http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
add_image "CentOS_Stream" "9" "aarch64" "`get_lxc_url centos/9-Stream/arm64`"
add_image "Debian" "Bullseye" "aarch64" "`get_lxc_url debian/bullseye/arm64`"
add_image "Debian" "Bookworm" "aarch64" "`get_lxc_url debian/bookworm/arm64`"
add_image "Debian" "Buster" "aarch64" "`get_lxc_url debian/buster/arm64`"
add_image "Debian" "Bullseye" "armv7l" "`get_lxc_url debian/bullseye/armhf`"
add_image "Debian" "Bookworm" "armv7l" "`get_lxc_url debian/bookworm/armhf`"
add_image "Debian" "Buster" "armv7l" "`get_lxc_url debian/buster/armhf`"
add_image "Debian_by_maurerr" "Bookworm" "armv7l" "`get_maurerr_url debian bookworm armv7l`"
add_image "Debian_by_maurerr" "Bullseye" "armv7l" "`get_maurerr_url debian bullseye armv7l`"
add_image "Fedora" "40" "aarch64" "`get_lxc_url fedora/40/arm64`"
add_image "Fedora" "41" "aarch64" "`get_lxc_url fedora/41/arm64`"
add_image "Fedora" "42" "aarch64" "`get_lxc_url fedora/42/arm64`"
add_image "Gentoo" "openrc" "armv7l" "`get_gentoo_url arm armv7a_hardfp-openrc`"
add_image "Gentoo" "systemd" "armv7l" "`get_gentoo_url arm armv7a_hardfp-systemd`"
add_image "Gentoo" "musl-openrc" "armv7l" "`get_gentoo_url arm armv7a_hardfp-musl-openrc`"
add_image "Gentoo" "openrc" "aarch64" "`get_gentoo_url arm64 arm64`"
add_image "Gentoo" "systemd" "aarch64" "`get_gentoo_url arm64 arm64-systemd`"
add_image "Gentoo" "musl-openrc" "aarch64" "`get_gentoo_url arm64 arm64-musl`"
add_image "Kali_by_maurerr" "Kali-rolling" "armv7l" "`get_maurerr_url kali kali-rolling armv7l`"
add_image "openSUSE" "15.4" "armv7l" "`get_opensuse_url https://download.opensuse.org/ports/armv7hl/distribution/leap/15.4/appliances`"
add_image "openSUSE" "15.4" "aarch64" "`get_opensuse_url https://download.opensuse.org/ports/aarch64/distribution/leap/15.4/appliances`"
add_image "openSUSE" "15.5" "aarch64" "`get_opensuse_url https://download.opensuse.org/distribution/leap/15.5/appliances/ aarch64`"
add_image "openSUSE" "Tumbleweed" "armv7l" "https://download.opensuse.org/ports/armv7hl/factory/appliances/opensuse-tumbleweed-image.armv7l-lxc.tar.xz"
add_image "openSUSE" "Tumbleweed" "aarch64" "https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/opensuse-tumbleweed-image.aarch64-lxc.tar.xz"
add_image "OpenWrt" "24.10.2" "arm64" "`get_openwrt_url 24.10.2 arm64`"
add_image "OpenWrt" "24.10.2" "armv7l" "`get_openwrt_url 24.10.2 armv7l`"
add_image "OpenWrt" "snapshot" "arm64" "`get_openwrt_url snapshot arm64`"
add_image "OpenWrt" "snapshot" "armv7l" "`get_openwrt_url snapshot armv7l`"
add_image "Ubuntu" "24.04" "armv7l" "`get_ubuntu_url 24.04 armhf`"
add_image "Ubuntu" "24.04" "aarch64" "`get_ubuntu_url 24.04 amd64`"
add_image "Ubuntu" "25.04" "armv7l" "`get_ubuntu_url 25.04 armhf`"
add_image "Ubuntu" "25.04" "aarch64" "`get_ubuntu_url 25.04 amd64`"
add_image "VoidLinux" "glibc" "aarch64" "`get_lxc_url voidlinux/current/arm64`"
add_image "VoidLinux" "musl" "aarch64" "`get_lxc_url voidlinux/current/arm64 musl`"

if [ "`gpg -K`" ]; then
if [ -f ~/gpg-pass ]; then
    find . -type f -exec gpg --batch --no-tty --yes --passphrase-file ~/gpg-pass --pinentry-mode loopback --armor --detach-sign \{\} \;
else
    find . -type f -exec gpg -a --detach-sign \{\} \;
fi
fi
