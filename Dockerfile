FROM eclipse-temurin:17-jdk-jammy
LABEL maintainer="alaabenterdayet"
WORKDIR /app
COPY target/*.jar student-management.jar
EXPOSE 8089
ENV JAVA_OPTS=""
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar student-management.jar"]
