uv run main.py \
  --use-case pii \
  --model-id  \
  --onnx-enabled false \
  --default-threshold 0.3 \
  --default-entities "address,age,bank account number,city,country,credit card number,date,date of birth,drivers license number,email,health insurance number,iban,ip address,license plate,location,passport number,person,phone number,social security number,state,tax identification number,vehicle identification number,zip code" \
  --host localhost \
  --port 8083