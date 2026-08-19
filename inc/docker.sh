#!/bin/bash
# Docker helpers

# get_container_id <name>
# Prints the ID of the first running container whose name matches <name>.
get_container_id() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "dotfile: get_container_id: usage: get_container_id <name>" >&2
        return 1
    fi
    docker ps --filter "name=$name" --format '{{.ID}}' | head -n1
}
