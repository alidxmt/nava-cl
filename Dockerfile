# $DEL_BEGIN

# ####### 👇 SIMPLE SOLUTION 👇 ########
# FROM python:3.8.12-buster
# WORKDIR /prod
# COPY taxifare taxifare
# COPY requirements.txt requirements.txt
# COPY setup.py setup.py
# RUN pip install .
# CMD uvicorn taxifare.api.fast:app --host 0.0.0.0 --port $PORT

####### 👇 OPTIMIZED SOLUTION👇  (too advanced for ML-Ops module but useful for the project weeks) #######
# tensorflow base-images are optimized: lighter than python-buster + pip install tensorflow
FROM tensorflow/tensorflow:2.9.1
WORKDIR /prod
COPY taxifare taxifare
# We strip the requirements from useless packages like `ipykernel`, `matplotlib` etc...
COPY requirements_prod.txt requirements.txt
COPY setup.py setup.py
RUN python -m pip install --upgrade pip
RUN pip install .
# Copy .env with DATA_SOURCE=local and MODEL_TARGET=mlflow
COPY .env .env
# A build time, download the model from the MLflow server and copy it once for all inside of the image
RUN python -c 'from dotenv import load_dotenv, find_dotenv; load_dotenv(find_dotenv()); \
    from taxifare.ml_logic.registry import load_model; load_model(save_copy_locally=True)'
# Then, at run time, load the model locally from the container instead of querying the MLflow server, thanks to "MODEL_TARGET=local"
# This avoids to download the heavy model from the Internet every time an API request is performed
CMD MODEL_TARGET=local uvicorn taxifare.api.fast:app --host 0.0.0.0 --port $PORT

# $DEL_END
