uv run main.py \
  --use-case medical \
  --model-id Ihor/gliner-biomed-base-v1.0 \
  --onnx-enabled false \
  --default-threshold 0.3 \
  --default-entities "anatomy,bacteria,demographic information,disease,doctor,drug dosage,drug frequency,drug,illness,lab test value,lab test,medical worker,procedure,symptom,test,treatment,virus" \
  --host localhost \
  --port 8082