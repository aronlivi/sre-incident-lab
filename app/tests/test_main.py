from fastapi.testclient import TestClient

from app.src.main import app


client = TestClient(app)


def test_root():
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "service": "sre-incident-lab",
        "status": "running",
    }


def test_health_live():
    response = client.get("/health/live")

    assert response.status_code == 200
    assert response.json() == {
        "status": "alive",
    }


def test_health_ready():
    response = client.get("/health/ready")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ready",
    }


def test_error():
    response = client.get("/error")

    assert response.status_code == 500
    assert response.json() == {
        "detail": "Simulated internal server error",
    }


def test_slow():
    response = client.get("/slow?delay=0")

    assert response.status_code == 200
    assert response.json()["status"] == "completed"
    assert response.json()["delay_seconds"] == 0


def test_cpu_stress():
    response = client.get("/cpu-stress?seconds=1")

    assert response.status_code == 200
    assert response.json()["status"] == "completed"
    assert response.json()["duration_seconds"] == 1
    assert response.json()["iterations"] > 0
