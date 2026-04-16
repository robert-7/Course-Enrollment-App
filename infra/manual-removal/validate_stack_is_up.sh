#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOTENV_FILE="${ROOT_INFRA_DIR}/.env"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common_manual_stack_vars.sh"

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


require_cmd aws

ACCOUNT_ID="$(aws sts get-caller-identity --query 'Account' --output text)"
EXPECTED_ACCOUNT_ID="$(dotenv_value CDK_DEFAULT_ACCOUNT "${DOTENV_FILE}")"
if [[ -n "${EXPECTED_ACCOUNT_ID}" && "${ACCOUNT_ID}" != "${EXPECTED_ACCOUNT_ID}" ]]; then
    fail "Authenticated AWS account (${ACCOUNT_ID}) does not match infra/.env account (${EXPECTED_ACCOUNT_ID})."
fi

SERVICE_STATUS="$(aws_regional ecs describe-services \
    --cluster "${ECS_CLUSTER_NAME}" \
    --services "${ECS_SERVICE_NAME}" \
    --query 'services[0].status' \
    --output text 2>/dev/null || true)"
[[ "${SERVICE_STATUS}" == "ACTIVE" ]] || fail "ECS service ${ECS_SERVICE_NAME} is not ACTIVE."

SERVICE_COUNTS="$(aws_regional ecs describe-services \
    --cluster "${ECS_CLUSTER_NAME}" \
    --services "${ECS_SERVICE_NAME}" \
    --query 'services[0].[desiredCount,runningCount,pendingCount]' \
    --output text 2>/dev/null || true)"
[[ "${SERVICE_COUNTS}" == $'1\t1\t0' ]] || fail "ECS service counts are not desired=1 running=1 pending=0 (got: ${SERVICE_COUNTS})."

LOAD_BALANCER_STATE="$(aws_regional elbv2 describe-load-balancers \
    --names "${ALB_NAME}" \
    --query 'LoadBalancers[0].State.Code' \
    --output text 2>/dev/null || true)"
[[ "${LOAD_BALANCER_STATE}" == "active" ]] || fail "ALB ${ALB_NAME} is not active."

TARGET_GROUP_HEALTH="$(aws_regional elbv2 describe-target-health \
    --target-group-arn "$(aws_regional elbv2 describe-target-groups \
        --names "${TARGET_GROUP_NAME}" \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)" \
    --query 'TargetHealthDescriptions[0].TargetHealth.State' \
    --output text 2>/dev/null || true)"
[[ "${TARGET_GROUP_HEALTH}" == "healthy" ]] || fail "Target group ${TARGET_GROUP_NAME} does not have a healthy target."

SECRET_KEY_PRESENT="$(aws_regional ssm get-parameter \
    --name "${SECRET_KEY_PARAMETER_NAME}" \
    --query 'Parameter.Name' \
    --output text 2>/dev/null || true)"
[[ "${SECRET_KEY_PRESENT}" == "${SECRET_KEY_PARAMETER_NAME}" ]] || fail "SSM parameter ${SECRET_KEY_PARAMETER_NAME} is missing."

MONGO_URI_PRESENT="$(aws_regional ssm get-parameter \
    --name "${MONGO_URI_PARAMETER_NAME}" \
    --query 'Parameter.Name' \
    --output text 2>/dev/null || true)"
[[ "${MONGO_URI_PRESENT}" == "${MONGO_URI_PARAMETER_NAME}" ]] || fail "SSM parameter ${MONGO_URI_PARAMETER_NAME} is missing."

TASK_EXECUTION_ROLE_PRESENT="$(aws iam get-role \
    --role-name "${TASK_EXECUTION_ROLE_NAME}" \
    --query 'Role.RoleName' \
    --output text 2>/dev/null || true)"
[[ "${TASK_EXECUTION_ROLE_PRESENT}" == "${TASK_EXECUTION_ROLE_NAME}" ]] || fail "IAM role ${TASK_EXECUTION_ROLE_NAME} is missing."

GITHUB_ACTIONS_ROLE_PRESENT="$(aws iam get-role \
    --role-name "${GITHUB_ACTIONS_ROLE_NAME}" \
    --query 'Role.RoleName' \
    --output text 2>/dev/null || true)"
[[ "${GITHUB_ACTIONS_ROLE_PRESENT}" == "${GITHUB_ACTIONS_ROLE_NAME}" ]] || fail "IAM role ${GITHUB_ACTIONS_ROLE_NAME} is missing."

REPOSITORY_PRESENT="$(aws_regional ecr describe-repositories \
    --repository-names "${APP_NAME}" \
    --query 'repositories[0].repositoryName' \
    --output text 2>/dev/null || true)"
[[ "${REPOSITORY_PRESENT}" == "${APP_NAME}" ]] || fail "ECR repository ${APP_NAME} is missing."

LOAD_BALANCER_DNS="$(aws_regional elbv2 describe-load-balancers \
    --names "${ALB_NAME}" \
    --query 'LoadBalancers[0].DNSName' \
    --output text)"

log "AWS stack validation completed successfully."
log "ECS service ${ECS_SERVICE_NAME} is ACTIVE with desired=1 running=1 pending=0."
log "ALB ${ALB_NAME} is active."
log "Target group ${TARGET_GROUP_NAME} has a healthy target."
log "SSM parameters, IAM roles, and ECR repository are present."
log "ALB DNS: ${LOAD_BALANCER_DNS}"
