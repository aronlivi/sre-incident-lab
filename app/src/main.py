import time

from fastapi import FastAPI, HTTPException

app = FastAPI(
    title="SRE Incident Lab API",
    version="0.1.0",
)


@app.get("/")
def root():
    return {
        "service": "sre-incident-lab",
        "status": "running",
    }


@app.get("/health/live")
def health_live():
    return {
        "status": "alive",
    }


@app.get("/health/ready")
def health_ready():
    return {
        "status": "ready",
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
