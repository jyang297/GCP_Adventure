"""
Cloud Run proxy that forwards prompts to Vertex AI publisher models or an existing Endpoint.
Environment:
- PROJECT_ID: target project
- LOCATION: region for Vertex
- MODEL_ID: publisher model id (e.g., text-bison@001); ignored if ENDPOINT_ID is set
- ENDPOINT_ID: optional Vertex Endpoint id (UUID) to call instead of publisher model
"""

import os
from typing import Any, Dict, Optional

from fastapi import FastAPI, HTTPException
from google.cloud import aiplatform_v1
from pydantic import BaseModel
import uvicorn

PROJECT_ID = os.environ.get("PROJECT_ID")
LOCATION = os.environ.get("LOCATION", "us-central1")
MODEL_ID = os.environ.get("MODEL_ID", "text-bison@001")
ENDPOINT_ID = os.environ.get("ENDPOINT_ID", "")

if not PROJECT_ID:
    raise RuntimeError("PROJECT_ID is required")

app = FastAPI(title="Vertex Proxy", version="0.1.0")
client = aiplatform_v1.PredictionServiceClient()


class PredictRequest(BaseModel):
    prompt: str
    parameters: Optional[Dict[str, Any]] = None


def predict_publisher_model(prompt: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
    endpoint = f"projects/{PROJECT_ID}/locations/{LOCATION}/publishers/google/models/{MODEL_ID}"
    instance = {"prompt": prompt}
    response = client.predict(
        endpoint=endpoint,
        instances=[instance],
        parameters=parameters,
    )
    prediction = response.predictions[0]
    # text-bison returns {"content": "..."}; other models may differ
    text = prediction.get("content") or prediction.get("output") or prediction
    return {"model": MODEL_ID, "response": text}


def predict_endpoint(prompt: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
    endpoint_path = client.endpoint_path(PROJECT_ID, LOCATION, ENDPOINT_ID)
    instance = {"prompt": prompt}
    response = client.predict(
        endpoint=endpoint_path,
        instances=[instance],
        parameters=parameters,
    )
    text = response.predictions[0].get("content") or response.predictions[0]
    return {"endpoint": ENDPOINT_ID, "response": text}


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/predict")
def predict(body: PredictRequest) -> Dict[str, Any]:
    if not body.prompt:
        raise HTTPException(status_code=400, detail="prompt is required")
    parameters = body.parameters or {"temperature": 0.2, "maxOutputTokens": 128, "topP": 0.95}

    if ENDPOINT_ID:
        return predict_endpoint(body.prompt, parameters)
    return predict_publisher_model(body.prompt, parameters)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
