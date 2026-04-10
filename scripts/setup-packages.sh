#!/usr/bin/env bash
set -euo pipefail

GO_VERSION="${GO_VERSION:-1.25.0}"
INSTALL_PYTHON3="${INSTALL_PYTHON3:-1}"
TARGET_USER="${SUDO_USER:-${TARGET_USER:-}}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/setup-packages.sh" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Unsupported system: /etc/os-release not found" >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

case "${ID:-}" in
  ubuntu|debian)
    ;;
  *)
    echo "Unsupported distribution: ${ID:-unknown}. This script supports Ubuntu and Debian." >&2
    exit 1
    ;;
esac

if [[ -z "${VERSION_CODENAME:-}" ]]; then
  echo "VERSION_CODENAME is missing in /etc/os-release" >&2
  exit 1
fi

install_go() {
  local arch archive tmp_dir current_version

  if command -v go >/dev/null 2>&1; then
    current_version="$(go version | awk '{print $3}')"
    if [[ "${current_version}" == "go${GO_VERSION}" ]]; then
      echo "Go ${GO_VERSION} already installed."
      return
    fi
  fi

  case "$(dpkg --print-architecture)" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *)
      echo "Unsupported architecture for Go install: $(dpkg --print-architecture)" >&2
      exit 1
      ;;
  esac

  archive="go${GO_VERSION}.linux-${arch}.tar.gz"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' RETURN

  echo "==> Installing Go ${GO_VERSION}"
  curl -fsSL "https://go.dev/dl/${archive}" -o "${tmp_dir}/${archive}"
  rm -rf /usr/local/go
  tar -C /usr/local -xzf "${tmp_dir}/${archive}"
  ln -sf /usr/local/go/bin/go /usr/local/bin/go
  ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
  go version
}

echo "==> Installing base packages"
apt update
apt install -y ca-certificates curl gnupg git make

if [[ "${INSTALL_PYTHON3}" == "1" ]]; then
  apt install -y python3
fi

echo "==> Installing Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker

install_go

if [[ -n "${TARGET_USER}" && "${TARGET_USER}" != "root" ]]; then
  usermod -aG docker "${TARGET_USER}" || true
fi

echo
echo "Packages are installed."
echo
echo "Checks:"
echo "  docker --version"
echo "  docker compose version"
echo "  go version"
echo "  git --version"
echo "  make --version"
if [[ "${INSTALL_PYTHON3}" == "1" ]]; then
  echo "  python3 --version"
fi
if [[ -n "${TARGET_USER}" && "${TARGET_USER}" != "root" ]]; then
  echo
echo "Docker group updated for: ${TARGET_USER}"
echo "Log out and log back in before using docker without sudo."
fi
