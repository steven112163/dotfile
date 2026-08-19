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
    # docker's `name=` filter is a regex substring match (unanchored, and
    # metacharacters in $name like `.` aren't escaped), so it can't express
    # exact matching; compare names literally instead. Captured (not piped)
    # so a `docker ps` failure isn't masked by awk's own exit status.
    local ps_output
    ps_output="$(docker ps --format '{{.ID}} {{.Names}}')" || {
        echo "dotfile: get_container_id: docker ps failed" >&2
        return 1
    }
    awk -v n="$name" '$2==n{print $1; exit}' <<< "$ps_output"
}
