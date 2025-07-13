uv run main.py \
  --use-case general \
  --model-id knowledgator/gliner-x-large \
  --onnx-enabled true \
  --onnx-model-path "onnx/model_quantized.onnx" \
  --default-threshold 0.3 \
  --default-entities "address,age,bank account number,city,country,credit card number,date,date of birth,drivers license number,email,health insurance number,iban,ip address,license plate,location,passport number,person,phone number,social security number,state,tax identification number,vehicle identification number,zip code,anatomy,bacteria,disease,drug,illness,procedure,symptom,test,treatment,virus" \
  --host localhost \
  --port 8083