from application.models import Course
from application.models import User


def test_api_root_redirects_to_docs(client):
    response = client.get("/api", follow_redirects=False)

    assert response.status_code == 302
    assert response.headers["Location"].endswith("/api/v1/docs")


def test_api_docs_page_loads(client):
    response = client.get("/api/v1/docs")

    assert response.status_code == 200


def test_api_courses_lists_courses(client):
    Course(
        courseID="CSE200",
        title="Web Systems",
        description="HTTP and app architecture",
        credits=4,
        term="Fall 2026",
    ).save()
    Course(
        courseID="CSE100",
        title="Intro to Testing",
        description="Core testing patterns",
        credits=3,
        term="Fall 2026",
    ).save()

    response = client.get("/api/v1/courses")

    assert response.status_code == 200
    payload = response.get_json()
    assert len(payload) == 2
    assert payload[0]["courseID"] == "CSE100"
    assert payload[1]["courseID"] == "CSE200"


def test_api_course_by_id_returns_single_course(client):
    Course(
        courseID="MTH101",
        title="Discrete Math",
        description="Logic and combinatorics",
        credits=3,
        term="Spring 2027",
    ).save()

    response = client.get("/api/v1/courses/MTH101")

    assert response.status_code == 200
    payload = response.get_json()
    assert len(payload) == 1
    assert payload[0]["title"] == "Discrete Math"


def test_api_course_by_id_returns_404_for_missing_course(client):
    response = client.get("/api/v1/courses/NOPE999")

    assert response.status_code == 404
    assert response.get_json()["error"] == "Course not found"


def test_api_courses_does_not_return_users(client):
    user = User(
        user_id=1,
        email="apiuser@example.com",
        first_name="Api",
        last_name="User",
    )
    user.set_password("secret12")
    user.save()

    response = client.get("/api/v1/courses")

    assert response.status_code == 200
    assert response.get_json() == []
