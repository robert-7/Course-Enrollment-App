import os

import aws_cdk as cdk
from course_enrollment_stack import CourseEnrollmentAppStack


def _required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def _required_subnet_ids() -> list[str]:
    subnet_ids = [
        subnet_id.strip()
        for subnet_id in _required_env("CDK_PUBLIC_SUBNET_IDS").split(",")
        if subnet_id.strip()
    ]
    if len(subnet_ids) < 2:
        raise RuntimeError(
            "CDK_PUBLIC_SUBNET_IDS must include at least two "
            "comma-separated subnet IDs."
        )
    return subnet_ids


app = cdk.App()

CourseEnrollmentAppStack(
    app,
    "CourseEnrollmentAppStack",
    stack_name="CourseEnrollmentAppStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT"),
        region=os.environ.get("CDK_DEFAULT_REGION", "us-east-1"),
    ),
    vpc_id=_required_env("CDK_VPC_ID"),
    public_subnet_ids=_required_subnet_ids(),
    certificate_arn=_required_env("CDK_CERTIFICATE_ARN"),
    image_tag=_required_env("CDK_IMAGE_TAG"),
    secret_key_value=_required_env("CDK_SECRET_KEY"),
    mongo_uri_value=_required_env("CDK_MONGO_URI"),
)

app.synth()
