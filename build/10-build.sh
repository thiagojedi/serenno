#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################
# This script follows the @ublue-os/bluefin pattern for build scripts.
# It uses set -eoux pipefail for strict error handling and debugging.
###############################################################################

echo "::group:: Install Sway Desktop"

mkdir -p /var/lib/apt/lists/partial
mkdir -p /var/lib/dpkg/

export DEBIAN_FRONTEND=noninteractive

# Update package lists
apt-get update
apt-get install -y \
	debconf \
	libgio-2.0-dev \
	python3

# Install sway
apt-get install -y \
	foot-themes \
	sway \
	sway-backgrounds \
	swayidle \
	swaylock \
	xdg-desktop-portal-gtk \
	xdg-desktop-portal-wlr \
	lightdm

apt-get install -y \
	podman \
	thunar \
	network-manager-applet

apt-get install -y whois
usermod -p "$(echo "changeme" | mkpasswd -s)" root

apt-get clean -y

echo "::endgroup::"

echo "::group:: Copy Custom Files"

# Copy Brewfiles to standard location (if using homebrew)
mkdir -p /usr/share/ublue-os/homebrew/
if [ -d /ctx/custom/brew ]; then
	cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/ 2>/dev/null || true
fi

# Consolidate Just Files (if using ujust)
mkdir -p /usr/share/ublue-os/just/
if [ -d /ctx/custom/ujust ]; then
	find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/60-custom.just 2>/dev/null || true
fi

# Copy Flatpak preinstall files (if using flatpak)
mkdir -p /etc/flatpak/preinstall.d/
if [ -d /ctx/custom/flatpaks ]; then
	cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/ 2>/dev/null || true
fi

echo "::endgroup::"

echo "::group:: System Configuration"

cp /ctx/custom/os-release /usr/lib/os-release

cat /usr/lib/os-release

# Enable/disable systemd services
systemctl enable podman.socket
# Example: systemctl mask unwanted-service

echo "::endgroup::"

# Restore default glob behavior
shopt -u nullglob

echo "Custom build complete!"
