"""
Compile and launch a simple Vertex AI Pipeline (KFP v2) that calls a publisher model
and stores the output in GCS. Uses Application Default Credentials to submit the run.
"""

import argparse
from pathlib import Path

from google.cloud import aiplatform
from kfp import compiler, dsl


@dsl.component(
    base_image="python:3.11",
    packages=["google-cloud-aiplatform==1.49.0"],
)
def generate_text(
    project: str,
    location: str,
    model_id: str,
    prompt: str,
    temperature: float,
    max_output_tokens: int,
) -> str:
    from google.cloud import aiplatform_v1

    client = aiplatform_v1.PredictionServiceClient()
    endpoint = f"projects/{project}/locations/{location}/publishers/google/models/{model_id}"
    response = client.predict(
        endpoint=endpoint,
        instances=[{"prompt": prompt}],
        parameters={
          "temperature": temperature,
          "maxOutputTokens": max_output_tokens,
        },
    )
    prediction = response.predictions[0]
    return prediction.get("content") or prediction.get("output") or str(prediction)


@dsl.component(
    base_image="python:3.11",
    packages=["google-cloud-storage==2.16.0"],
)
def write_to_gcs(bucket: str, region: str, text: str, prompt: str) -> str:
    import datetime
    import json
    from google.cloud import storage

    client = storage.Client()
    ts = datetime.datetime.utcnow().isoformat() + "Z"
    path = f"runs/{ts}.json"
    payload = {"prompt": prompt, "response": text, "region": region, "timestamp": ts}
    bucket_obj = client.bucket(bucket)
    blob = bucket_obj.blob(path)
    blob.upload_from_string(json.dumps(payload), content_type="application/json")
    return f"gs://{bucket}/{path}"


@dsl.pipeline(name="vertex-text-pipeline")
def text_pipeline(
    project: str,
    location: str,
    model_id: str,
    prompt: str,
    bucket: str,
    temperature: float = 0.2,
    max_output_tokens: int = 256,
):
    generated = generate_text(
        project=project,
        location=location,
        model_id=model_id,
        prompt=prompt,
        temperature=temperature,
        max_output_tokens=max_output_tokens,
    )
    write_to_gcs(
        bucket=bucket,
        region=location,
        text=generated.output,
        prompt=prompt,
    )


def run_pipeline(args: argparse.Namespace) -> None:
    aiplatform.init(project=args.project, location=args.region, staging_bucket=args.staging_bucket)
    package_path = "vertex_text_pipeline.json"
    compiler.Compiler().compile(
        pipeline_func=text_pipeline,
        package_path=package_path,
    )
    prompt_text = Path(args.prompt_file).read_text().strip()

    job = aiplatform.PipelineJob(
        display_name="gcp-adventure-text-pipeline",
        template_path=package_path,
        pipeline_root=f"{args.staging_bucket}/pipeline-root",
        parameter_values={
            "project": args.project,
            "location": args.region,
            "model_id": args.model_id,
            "prompt": prompt_text,
            "bucket": args.staging_bucket.replace("gs://", ""),
            "temperature": args.temperature,
            "max_output_tokens": args.max_output_tokens,
        },
    )
    job.submit()
    print(f"Submitted pipeline job: {job.resource_name}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, help="GCP project id")
    parser.add_argument("--region", required=True, help="Vertex AI region")
    parser.add_argument("--staging-bucket", required=True, help="gs:// bucket for pipeline root")
    parser.add_argument("--prompt-file", default="sample_prompt.txt", help="Path to prompt text file")
    parser.add_argument("--model_id", default="text-bison@001", help="Publisher model id")
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--max_output_tokens", type=int, default=256)
    return parser.parse_args()


if __name__ == "__main__":
    run_pipeline(parse_args())
