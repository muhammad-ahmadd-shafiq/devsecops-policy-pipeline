from app.app import app

def test_home_returns_application_information():
    client = app.test_client()

    response = client.get("/")

    assert response.status_code == 200

    data = response.get_json()
    assert data["Application"] == "Devsecops-Policy-Pipeline"
    assert data["status"] == "running"

def test_health_healthy_status():
    client = app.test_client()

    response = client.get("/health")


    assert response.status_code == 200
    assert response.get_json() == {"status":"running"}