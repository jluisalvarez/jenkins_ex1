FROM python:3.10-alpine

WORKDIR /app

EXPOSE 8080

COPY ./app .

RUN pip install --no-cache-dir -r requirements.txt

CMD [ "python", "./app.py" ]