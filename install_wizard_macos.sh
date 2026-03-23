#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_ROOT/.venv"
DB_PATH="$PROJECT_ROOT/media_inventory.db"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

print_header() {
  echo ""
  echo "==========================================="
  echo "   Media Inventory macOS Install Wizard"
  echo "==========================================="
  echo ""
}

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-Y}"
  local reply

  if [[ "$default" == "Y" ]]; then
    read -r -p "$prompt [Y/n]: " reply
    reply="${reply:-Y}"
  else
    read -r -p "$prompt [y/N]: " reply
    reply="${reply:-N}"
  fi

  [[ "$reply" =~ ^[Yy]$ ]]
}

check_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This installer is for macOS only."
    exit 1
  fi
  success "macOS detected"
}

check_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    error "python3 is not installed. Install Python 3.10+ and run again."
    exit 1
  fi

  PYTHON_BIN="$(command -v python3)"
  success "Python found at $PYTHON_BIN"
}

setup_virtualenv() {
  if [[ -d "$VENV_DIR" ]]; then
    info "Virtual environment already exists at $VENV_DIR"
    if ask_yes_no "Recreate the virtual environment?" "N"; then
      rm -rf "$VENV_DIR"
      "$PYTHON_BIN" -m venv "$VENV_DIR"
      success "Virtual environment recreated"
    else
      success "Using existing virtual environment"
    fi
  else
    info "Creating virtual environment"
    "$PYTHON_BIN" -m venv "$VENV_DIR"
    success "Virtual environment created"
  fi

  # shellcheck disable=SC1090
  source "$VENV_DIR/bin/activate"
  python -m pip install --upgrade pip setuptools wheel >/dev/null
  success "pip tooling upgraded"
}

install_python_dependencies() {
  info "Installing Python dependencies"
  pip install \
    flask \
    requests \
    beautifulsoup4 \
    python-barcode \
    pillow
  success "Python dependencies installed"
}

initialize_database() {
  if [[ -f "$DB_PATH" ]]; then
    warn "Database already exists at $DB_PATH"
    if ask_yes_no "Recreate database (this deletes existing data)?" "N"; then
      rm -f "$DB_PATH"
      python -c "import system; system.create_database()"
      success "Database recreated"
    else
      success "Keeping existing database"
    fi
  else
    info "Creating initial SQLite database"
    python -c "import system; system.create_database()"
    success "Database created"
  fi
}

check_xcode() {
  if command -v xcodebuild >/dev/null 2>&1; then
    success "Xcode command line tools available"
  else
    warn "Xcode command line tools not found. macOS app build may fail until Xcode is installed."
  fi
}

launch_options() {
  echo ""
  echo "Install complete."

  if ask_yes_no "Open the project in Xcode now?" "N"; then
    open "$PROJECT_ROOT/macOS/MediaInventory/MediaInventory.xcodeproj" || true
  fi

  if ask_yes_no "Start the Flask web server now?" "Y"; then
    echo ""
    info "Starting server on http://localhost:5000"
    info "Press Ctrl+C to stop"
    cd "$PROJECT_ROOT"
    python app.py
  else
    echo ""
    info "To start later:"
    echo "  cd \"$PROJECT_ROOT\""
    echo "  source .venv/bin/activate"
    echo "  python app.py"
  fi
}

main() {
  print_header
  check_macos
  check_python
  check_xcode
  setup_virtualenv
  install_python_dependencies
  initialize_database
  launch_options
}

main
