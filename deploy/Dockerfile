FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --chown=10001:10001 mytest.jar /app/mytest.jar
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/mytest.jar"]
