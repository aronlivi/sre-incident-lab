import os
import time

from fastapi import FastAPI, HTTPException

APP_ENVIRONMENT = os.getenv("APP_ENVIRONMENT", "local")
APP_MESSAGE = os.getenv("APP_MESSAGE", "SRE Incident Lab")
LAB_SECRET = os.getenv("LAB_SECRET", "")

health_state = {
    "live": True,
    "ready": True,
}

app = FastAPI(
    title="SRE Incident Lab API",
    version="0.3.0",
)


@app.get("/")
def root():
    return {
        "service": "sre-incident-lab",
        "status": "running",
        "environment": APP_ENVIRONMENT,
        "message": APP_MESSAGE,
        "secret_configured": bool(LAB_SECRET),
    }


@app.get("/health/live")
def health_live():
    if not health_state["live"]:
        raise HTTPException(
            status_code=503,
            detail="Liveness check failed",
        )

    return {
        "status": "alive",
    }


@app.get("/health/ready")
def health_ready():
    if not health_state["ready"]:
        raise HTTPException(
            status_code=503,
            detail="Readiness check failed",
        )

    return {
        "status": "ready",
    }


@app.post("/simulate/readiness/fail")
def readiness_fail():
    health_state["ready"] = False

    return {
        "readiness": "failed",
    }


@app.post("/simulate/readiness/recover")
def readiness_recover():
    health_state["ready"] = True

    return {
        "readiness": "recovered",
    }


@app.post("/simulate/liveness/fail")
def liveness_fail():
    health_state["live"] = False

    return {
        "liveness": "failed",
    }


@app.post("/simulate/liveness/recover")
def liveness_recover():
    health_state["live"] = True

    return {
        "liveness": "recovered",
    }


@app.get("/error")
def error():
    raise HTTPException(
        status_code=500,
        detail="Simulated internal server error",
    )


@app.get("/slow")
def slow(delay: int = 3):
    delay = max(0, min(delay, 10))
    time.sleep(delay)

    return {
        "status": "completed",
        "delay_seconds": delay,
    }


@app.get("/cpu-stress")
def cpu_stress(seconds: int = 2):
    seconds = max(1, min(seconds, 10))

    end_time = time.time() + seconds
    iterations = 0

    while time.time() < end_time:
        iterations += 1

    return {
        "status": "completed",
        "duration_seconds": seconds,
        "iterations": iterations,
    }
