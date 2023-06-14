FROM alpine
RUN apk update && apk upgrade -a --no-cache
COPY app/target/app-0.0.1-SNAPSHOT.jar /app.jar
