#!/usr/bin/env bash

color_enabled() {
    [[ -t 1 && -z "${NO_COLOR:-}" ]]
}


_log_with_color() {
    local label="$1"
    local color_code="$2"
    local message="$3"

    if color_enabled; then
        printf '\033[%sm[%s]\033[0m %s\n' "${color_code}" "${label}" "${message}"
    else
        printf '[%s] %s\n' "${label}" "${message}"
    fi
}


log_info() {
    _log_with_color "INFO" "34" "$*"
}


log_success() {
    _log_with_color "SUCCESS" "32" "$*"
}


log_warn() {
    if color_enabled; then
        printf '\033[33m[WARN]\033[0m %s\n' "$*" >&2
    else
        printf '[WARN] %s\n' "$*" >&2
    fi
}


log_error() {
    if color_enabled; then
        printf '\033[31m[ERROR]\033[0m %s\n' "$*" >&2
    else
        printf '[ERROR] %s\n' "$*" >&2
    fi
}


die() {
    log_error "$*"
    exit 1
}


require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}


dotenv_value() {
    local key="$1"
    local file="$2"

    if [[ ! -f "${file}" ]]; then
        return 0
    fi

    grep -E "^${key}=" "${file}" | tail -n 1 | cut -d '=' -f 2-
}


aws_regional() {
    aws --region "${AWS_REGION}" "$@"
}
