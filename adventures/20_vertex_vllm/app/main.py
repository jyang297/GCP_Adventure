"""FastAPI server compatible with Vertex AI custom prediction protocol."""
import os
import time
from typing import Any, Dict, List

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from vllm import LLM, SamplingParams

MODEL_ID = os.environ.get("MODEL_ID", "meta-llama/Llama-2-7b-chat-hf")
MAX_TOKENS = int(os.environ.get("MAX_TOKENS", "256"))
TEMPERATURE = float(os.environ.get("TEMPERATURE", "0.7"))
TOP_P = float(os.environ.get("TOP_P", "0.9"))

app = FastAPI(title="Vertex vLLM Server", version="0.1")

# Load model once at startup. In production, pin tensor parallel size per GPU type.
llm = LLM(model=MODEL_ID)


class PredictRequest(BaseModel):
    instances: List[Dict[str, Any]]
    parameters: Dict[str, Any] | None = None


def build_sampling(parameters: Dict[str, Any] | None) -> SamplingParams:
    params = parameters or {}
    return SamplingParams(
        temperature=float(params.get("temperature", TEMPERATURE)),
        top_p=float(params.get("top_p", TOP_P)),
        max_tokens=int(params.get("max_tokens", MAX_TOKENS)),
    )


@app.get("/ping")
def ping() -> Dict[str, str]:
    return {"status": "ok", "model": MODEL_ID}


@app.post("/predict")
def predict(body: PredictRequest) -> Dict[str, Any]:
    if not body.instances:
        raise HTTPException(status_code=400, detail="instances required")
    prompts = [inst.get("prompt", "") for inst in body.instances]
    sampling = build_sampling(body.parameters)
    outputs = llm.generate(prompts, sampling)
    predictions: List[Dict[str, str]] = []
    for output in outputs:
        predictions.append({"text": output.outputs[0].text})
    return {
        "predictions": predictions,
        "model": MODEL_ID,
        "created": int(time.time()),
    }
