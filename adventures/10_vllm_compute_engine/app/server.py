"""
FastAPI wrapper for vLLM to present an OpenAI-compatible /v1/completions endpoint.
Run only on a GPU-enabled machine. Keep the model id licensed and accessible.
"""

import argparse
import time
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from vllm import LLM, SamplingParams


class CompletionRequest(BaseModel):
    prompt: str
    max_tokens: Optional[int] = 256
    temperature: Optional[float] = 0.7
    top_p: Optional[float] = 0.9
    n: Optional[int] = 1


def build_app(model_id: str) -> FastAPI:
    # Lazy-load model at startup so the health endpoint works pre-load.
    llm = LLM(model=model_id)
    app = FastAPI(title="vLLM OpenAI-compatible server", version="0.1")

    @app.get("/health")
    def health() -> Dict[str, str]:
        return {"status": "ok", "model": model_id}

    @app.post("/v1/completions")
    def completions(req: CompletionRequest) -> Dict[str, Any]:
        if req.n != 1:
            raise HTTPException(status_code=400, detail="Only n=1 supported in this starter server")
        sampling_params = SamplingParams(
            temperature=req.temperature,
            top_p=req.top_p,
            max_tokens=req.max_tokens,
        )
        outputs = llm.generate([req.prompt], sampling_params)
        result_texts: List[str] = [output.outputs[0].text for output in outputs]
        now = int(time.time())
        return {
            "id": f"cmpl-{now}",
            "object": "text_completion",
            "created": now,
            "model": model_id,
            "choices": [
                {
                    "index": 0,
                    "text": result_texts[0],
                    "finish_reason": outputs[0].outputs[0].finish_reason,
                }
            ],
        }

    return app


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True, help="Model id (e.g., meta-llama/Llama-2-7b-chat-hf)")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", default=8000, type=int)
    args = parser.parse_args()

    app = build_app(args.model)

    import uvicorn

    uvicorn.run(app, host=args.host, port=args.port)


if __name__ == "__main__":
    main()
