#!/bin/bash
# Docker helpers

# get_container_id <name>
# Prints the ID of the first running container whose name matches <name>.
get_container_id() {
    local name="$1"
    [ -n "$name" ] || return 0
    docker ps | grep "$name" | awk '{ print $1 }'
}
