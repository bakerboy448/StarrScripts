#!/usr/bin/env bash
set -euo pipefail

export PATH=$PATH:/usr/local/go/bin

handle_error() {
    echo "Error: $1" >&2
    exit 1
}

display_help() {
    cat <<EOF
Usage: $0 [options]
Options:
  -h, --help               Show this help message
  --repo-url URL           Git repository URL (default: https://github.com/Notifiarr/notifiarr.git)
  --repo-dir DIR           Directory to clone or update repo (default: /opt/notifiarr-repo)
  --bin-path PATH          Destination for compiled binary (default: /usr/bin/notifiarr)
  --branch BRANCH          Git branch to checkout (default: master)
  --reinstall-apt          Reinstall Notifiarr using apt without prompt
EOF
    exit 0
}

ensure_tool_installed() {
    local tool="$1" install_cmd="$2"
    command -v "$tool" &>/dev/null && return
    read -rp "$tool is not installed. Install it? [Y/n] " r
    [[ "$r" =~ ^[Yy] ]] && eval "$install_cmd" || handle_error "$tool is required"
}

repo_url="https://github.com/Notifiarr/notifiarr.git"
repo_dir="/opt/notifiarr-repo"
bin_path="/usr/bin/notifiarr"
branch="master"
branch_explicit=false
apt_reinstall=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) display_help ;;
        --repo-url) repo_url="$2"; shift ;;
        --repo-dir) repo_dir="$2"; shift ;;
        --bin-path) bin_path="$2"; shift ;;
        --branch) branch="$2"; branch_explicit=true; shift ;;
        --reinstall-apt) apt_reinstall=true ;;
        *) handle_error "Invalid option: $1. Use --help for usage." ;;
    esac
    shift
done

ensure_tool_installed "make" "sudo apt update && sudo apt install -y make"
ensure_tool_installed "git" "sudo apt update && sudo apt install -y git"
ensure_tool_installed "go" "sudo apt update && sudo apt install -y golang"

$apt_reinstall && {
    sudo apt update
    sudo apt install --reinstall -y notifiarr || handle_error "APT reinstall failed"
    exit 0
}

if [[ ! -d "$repo_dir/.git" ]]; then
    git clone "$repo_url" "$repo_dir" || handle_error "Git clone failed"
else
    git -C "$repo_dir" fetch --all --prune || handle_error "Git fetch failed"
fi

cd "$repo_dir"
current_branch=$(git rev-parse --abbrev-ref HEAD)

if ! $branch_explicit; then
    read -rp "Use current branch ($current_branch)? [Y/n] " answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        echo "Available branches:"
        git branch -r | sed 's|origin/||' | grep -vE 'HEAD|->'
        read -rp "Enter branch: " branch
    else
        branch="$current_branch"
    fi
fi

git checkout "$branch" || handle_error "Git checkout failed"
git pull || handle_error "Git pull failed"

make || handle_error "Make failed"

sudo systemctl stop notifiarr || true

[[ -f "$bin_path" ]] && sudo mv "$bin_path" "${bin_path}.old"
sudo mv "$repo_dir/notifiarr" "$bin_path"
sudo chown root:root "$bin_path"

sudo systemctl start notifiarr || handle_error "Service failed to start"

if systemctl is-active --quiet notifiarr; then
    echo "Notifiarr service is running."
else
    handle_error "Notifiarr service is not running."
fi
