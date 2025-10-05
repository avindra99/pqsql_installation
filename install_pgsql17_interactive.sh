#!/bin/bash
# -------------------------------------------------------------------------
# Interactive PostgreSQL 17 Source Installation Script
# Author: Avindra Gorijala
# Company: Amtrica
# -------------------------------------------------------------------------

set -e  # Exit immediately if a command fails
PG_VERSION=17.5
PG_BASE="/opt/applications/pgsql"
PG_PREFIX="$PG_BASE/postgresql-$PG_VERSION"
PG_DATA="$PG_PREFIX/data"
PG_SYMLINK="$PG_BASE/postgresql"

# --------- Helper Functions ---------
pause() {
  echo
  read -rp "➡️  Press [Enter] to continue or Ctrl+C to abort..."
  echo
}

check_exit() {
  if [ $? -ne 0 ]; then
    echo "❌ Error encountered in previous step. Exiting."
    exit 1
  fi
}

print_step() {
  echo
  echo "===================================================="
  echo "🚀 STEP $1: $2"
  echo "===================================================="
  echo
}

# --------- Script Start ---------
echo "===================================================="
echo " PostgreSQL $PG_VERSION Interactive Installation"
echo "===================================================="
echo "This script will build PostgreSQL from source safely."
echo "Installation Path: $PG_PREFIX"
echo "Data Directory:    $PG_DATA"
echo

pause

# Step 1: Install dependencies
print_step 1 "Install required packages"
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
  bison flex readline readline-devel zlib zlib-devel \
  openssl openssl-devel libxml2 libxml2-devel libxslt libxslt-devel \
  python3-devel tcl-devel perl-devel perl-ExtUtils-Embed \
  systemd-devel clang llvm-devel make gcc wget libicu-devel perl-FindBin

check_exit
echo "✅ Dependencies installed successfully."
pause

# Step 2: Prepare directories
print_step 2 "Prepare installation directories"
sudo mkdir -p "$PG_BASE"
cd "$PG_BASE"
echo "✅ Directory structure prepared at $PG_BASE."
pause

# Step 3: Download PostgreSQL
print_step 3 "Download PostgreSQL $PG_VERSION source"
if [ ! -f "postgresql-$PG_VERSION.tar.gz" ]; then
  wget https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.gz
else
  echo "⚠️ Source tarball already exists, skipping download."
fi
check_exit
pause

# Step 4: Extract source
print_step 4 "Extract source files"
tar -xvzf postgresql-$PG_VERSION.tar.gz
ln -sf postgresql-$PG_VERSION postgresql
cd postgresql
echo "✅ Source extracted to $PG_PREFIX"
pause

# Step 5: Configure build
print_step 5 "Configure build"
./configure --prefix=$PG_PREFIX --with-openssl --with-libxml --with-libxslt
check_exit
pause

# Step 6: Compile source
print_step 6 "Compile PostgreSQL source"
make world-bin
check_exit
pause

# Step 7: Install compiled binaries
print_step 7 "Install PostgreSQL binaries"
sudo make install-world-bin
check_exit
pause

# Step 8: Create postgres user
print_step 8 "Create postgres user"
if id "postgres" &>/dev/null; then
  echo "⚠️ User 'postgres' already exists. Skipping creation."
else
  sudo useradd postgres
  echo "✅ User 'postgres' created."
fi
pause

# Step 9: Setup data directory
print_step 9 "Create and set permissions on data directory"
sudo mkdir -p "$PG_DATA"
sudo chown -R postgres:postgres "$PG_PREFIX"
sudo chmod 700 "$PG_DATA"
check_exit
echo "✅ Data directory ready."
pause

# Step 10: Initialize cluster
print_step 10 "Initialize PostgreSQL database cluster"
sudo -u postgres $PG_PREFIX/bin/initdb -D $PG_DATA
check_exit
pause

# Step 11: Add to PATH
print_step 11 "Add PostgreSQL bin path to postgres user profile"
PG_PROFILE="/home/postgres/.bash_profile"
if ! grep -q "$PG_PREFIX/bin" "$PG_PROFILE" 2>/dev/null; then
  echo "export PATH=\$PATH:$PG_PREFIX/bin" | sudo tee -a "$PG_PROFILE"
  echo "✅ PATH updated in $PG_PROFILE"
else
  echo "⚠️ PATH already contains PostgreSQL bin directory."
fi
pause

# Step 12: Start PostgreSQL
print_step 12 "Start PostgreSQL server"
sudo -u postgres $PG_PREFIX/bin/pg_ctl -D $PG_DATA -l $PG_PREFIX/logfile start
sleep 5
check_exit
pause

# Step 13: Verify installation
print_step 13 "Verify PostgreSQL version"
sudo -u postgres $PG_PREFIX/bin/psql --version
echo
echo "✅ PostgreSQL $PG_VERSION successfully installed and running!"
echo "Binary Path: $PG_PREFIX/bin"
echo "Data Path:   $PG_DATA"
echo
echo "-----------------------------------------------------"
echo "💡 To stop the server: sudo -u postgres $PG_PREFIX/bin/pg_ctl stop -D $PG_DATA"
echo "💡 To connect:          sudo -u postgres psql"
echo "-----------------------------------------------------"
