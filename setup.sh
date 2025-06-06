#!/usr/bin/env bash

set -e

show_usage() {
  echo "Usage: $(basename $0) takes exactly 1 argument (install | uninstall)"
}

if [ $# -ne 1 ]; then
  show_usage
  exit 1
fi

check_env() {
  if [[ -z "${RALPM_TMP_DIR}" ]]; then
    echo "RALPM_TMP_DIR is not set"
    exit 1
  elif [[ -z "${RALPM_PKG_INSTALL_DIR}" ]]; then
    echo "RALPM_PKG_INSTALL_DIR is not set"
    exit 1
  elif [[ -z "${RALPM_PKG_BIN_DIR}" ]]; then
    echo "RALPM_PKG_BIN_DIR is not set"
    exit 1
  fi
}

install() {
  sudo apt update
  sudo apt install --no-install-recommends -y \
    git make gcc pkg-config meson \
    libpci-dev libusb-1.0-0-dev libftdi1-dev libjaylink-dev libgpiod-dev

  mkdir -p "$RALPM_PKG_INSTALL_DIR/flashprog"
  cd "$RALPM_PKG_INSTALL_DIR"
  git clone https://github.com/SourceArcade/flashprog.git
  cd flashprog

  make
  make DESTDIR="$RALPM_PKG_INSTALL_DIR/flashprog" install

  # Create wrapper to call installed binary
  echo "#!/usr/bin/env sh" > "$RALPM_PKG_BIN_DIR/flashprog"
  echo "\"$RALPM_PKG_INSTALL_DIR/flashprog/usr/local/bin/flashprog\" \"\$@\"" >> "$RALPM_PKG_BIN_DIR/flashprog"
  chmod +x "$RALPM_PKG_BIN_DIR/flashprog"

  echo "This package provides the following command:"
  echo "  - flashprog"
}

uninstall() {
  rm -rf "$RALPM_PKG_INSTALL_DIR/flashprog"
  rm -f "$RALPM_PKG_BIN_DIR/flashprog"
}

run() {
  if [[ "$1" == "install" ]]; then 
    install
  elif [[ "$1" == "uninstall" ]]; then 
    uninstall
  else
    show_usage
  fi
}

check_env
run "$1"