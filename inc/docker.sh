#!/bin/bash
# Docker helpers

# get_container_id <name>
# Prints the ID of the running container named exactly <name>.
get_container_id() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "dotfile: get_container_id: usage: get_container_id <name>" >&2
        return 1
    fi
    # Anchored: docker's `name=` filter is an unanchored substring match, so
    # `foo` would otherwise also match a container named `foobar`.
    docker ps --filter "name=^${name}\$" --format '{{.ID}}' | head -n1
}
