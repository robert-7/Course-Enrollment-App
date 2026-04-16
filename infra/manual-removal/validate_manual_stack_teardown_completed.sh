#!/usr/bin/env bash
set -euo pipefail

ECS_CLUSTER_NAME="course-enrollment-app"
ECS_SERVICE_NAME="course-enrollment-app-svc"
ALB_NAME="course-enrollment-app-alb"
ECR_REPOSITORY_NAME="course-enrollment-app"
SECRET_KEY_PARAMETER_NAME="/course-enrollment-app/SECRET_KEY"
GITHUB_ACTIONS_ROLE_NAME="GitHubActions-CourseEnrollmentApp"

AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
export AWS_REGION
export AWS_DEFAULT_REGION="${AWS_REGION}"
export AWS_PAGER=""


log() {
    printf '[INFO] %s\n' "$*"
}


fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}


require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}


aws_regional() {
    aws --region "${AWS_REGION}" "$@"
}


resource_absent() {
    local description="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        fail "${description} still exists."
    fi

    log "${description} is absent."
}


require_cmd aws

aws sts get-caller-identity >/dev/null

resource_absent \
    "ECS service ${ECS_SERVICE_NAME}" \
    aws_regional ecs describe-services \
        --cluster "${ECS_CLUSTER_NAME}" \
        --services "${ECS_SERVICE_NAME}" \
        --query "services[?status!=\`INACTIVE\`]|[0]" \
        --output text

resource_absent \
    "ALB ${ALB_NAME}" \
    aws_regional elbv2 describe-load-balancers \
        --names "${ALB_NAME}"

resource_absent \
    "ECR repository ${ECR_REPOSITORY_NAME}" \
    aws_regional ecr describe-repositories \
        --repository-names "${ECR_REPOSITORY_NAME}"

resource_absent \
    "SSM parameter ${SECRET_KEY_PARAMETER_NAME}" \
    aws_regional ssm get-parameter \
        --name "${SECRET_KEY_PARAMETER_NAME}"

resource_absent \
    "IAM role ${GITHUB_ACTIONS_ROLE_NAME}" \
    aws iam get-role \
        --role-name "${GITHUB_ACTIONS_ROLE_NAME}"

log "Manual stack teardown verification completed successfully."
