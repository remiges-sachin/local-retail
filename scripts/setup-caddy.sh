#!/usr/bin/env bash
set -euo pipefail

BAP_DOMAIN="${BAP_DOMAIN:-baptest.remiges.tech}"
BPP_DOMAIN="${BPP_DOMAIN:-bpptest.remiges.tech}"
BAPAPP_DOMAIN="${BAPAPP_DOMAIN:-bapapp.remiges.tech}"
BPPAPP_DOMAIN="${BPPAPP_DOMAIN:-bppapp.remiges.tech}"
BAP_UPSTREAM="${BAP_UPSTREAM:-127.0.0.1:8081}"
BPP_UPSTREAM="${BPP_UPSTREAM:-127.0.0.1:8082}"
BAPAPP_UPSTREAM="${BAPAPP_UPSTREAM:-127.0.0.1:8083}"
BPPAPP_UPSTREAM="${BPPAPP_UPSTREAM:-127.0.0.1:8080}"
GO_VERSION="${GO_VERSION:-1.25.0}"
CADDY_EMAIL="${CADDY_EMAIL:-}"

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/setup-caddy.sh"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  apt update
  apt install -y curl
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

echo "==> Installing Caddy"
apt update
apt install -y debian-keyring debian-archive-keyring apt-transport-https gnupg curl
install_go
mkdir -p /usr/share/keyrings
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  -o /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy

mkdir -p /etc/caddy
if [[ -f /etc/caddy/Caddyfile ]]; then
  cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%Y%m%d%H%M%S)"
fi

EMAIL_BLOCK=""
if [[ -n "${CADDY_EMAIL}" ]]; then
  EMAIL_BLOCK="email ${CADDY_EMAIL}"
fi

cat > /etc/caddy/Caddyfile <<EOF
{
	${EMAIL_BLOCK}
}

${BAP_DOMAIN} {
	encode zstd gzip
	reverse_proxy ${BAP_UPSTREAM}
}

${BPP_DOMAIN} {
	encode zstd gzip
	reverse_proxy ${BPP_UPSTREAM}
}

${BAPAPP_DOMAIN} {
	encode zstd gzip
	reverse_proxy ${BAPAPP_UPSTREAM}
}

${BPPAPP_DOMAIN} {
	encode zstd gzip
	reverse_proxy ${BPPAPP_UPSTREAM}
}
EOF

caddy fmt --overwrite /etc/caddy/Caddyfile
caddy validate --config /etc/caddy/Caddyfile
systemctl enable caddy
systemctl restart caddy

echo
echo "Caddy is configured."
echo "BAP domain: ${BAP_DOMAIN} -> ${BAP_UPSTREAM}"
echo "BPP domain: ${BPP_DOMAIN} -> ${BPP_UPSTREAM}"
echo "BAP app domain: ${BAPAPP_DOMAIN} -> ${BAPAPP_UPSTREAM}"
echo "BPP app domain: ${BPPAPP_DOMAIN} -> ${BPPAPP_UPSTREAM}"
echo
echo "Checks:"
echo "  go version"
echo "  curl -I https://${BAP_DOMAIN}"
echo "  curl -I https://${BPP_DOMAIN}"
echo "  curl -I https://${BAPAPP_DOMAIN}"
echo "  curl -I https://${BPPAPP_DOMAIN}"
echo "  journalctl -u caddy -f"
