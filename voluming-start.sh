#!/bin/sh
set -eu -o pipefail

cd /app

create_cache_symlink () {
  local SOURCE="$1"
  local CACHE_BASE_DIR="$2"
  local CACHE_DEST="$2/$(basename $1)"

  # If the cache already exists, discard whatever's already
  # there are use the cache
  if [ -d "$CACHE_DEST" ]
  then
    rm -rf "$SOURCE"
    echo "Cache exists in $CACHE_DEST, replacing $SOURCE"
  fi

  # If there's something already there (and the cache does not exist)
  # move it into the cache
  if [ -d "$SOURCE" ]
  then
    mv -f "$SOURCE" "$CACHE_BASE_DIR"
    echo "Prepopulating cache $CACHE_DEST from $SOURCE"
  fi

  if [ ! -d "$CACHE_DEST" ]
  then
    mkdir -p "$CACHE_DEST"
  fi

  ln -s "$CACHE_DEST" "$SOURCE"
  echo "Linked $SOURCE to cache $CACHE_DEST"
}

if [ -d "/cache" ] # If a caching volume has been mounted, use the cache
then
  create_cache_symlink "/root/.npm" "/cache"

  # npm deletes any node_modules symlink (see https://github.com/npm/arborist/security/advisories/GHSA-gmw6-94gg-2rc2)
  # so we will detect if the cache has already been populated, and if
  # not we will install packages, then create the cache afterwards.
  # If the cache has been populated, we will just use it, and not run npm
  # so that it will not erase our symlink
  if [ ! -d "/cache/node_modules" ]
  then
    npm ci
  fi
  create_cache_symlink "/app/node_modules" "/cache"
else
  npm ci
fi

# Can't use npm scripts here because npm doesn't handle SIGTERM properly.
# Using exec, becaus it replaces the shell process with the node process
# so that it receives the SIGTERM signal properly. Otherwise the shell just
# eats the signal.
exec ./node_modules/.bin/ts-node --transpileOnly ./src/index.ts
