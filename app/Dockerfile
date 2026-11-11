FROM eclipse-temurin:21-jdk AS build
RUN apt-get update && apt-get install -y git
RUN git clone --depth 1 https://github.com/spring-projects/spring-petclinic.git /src
WORKDIR /src
RUN ./mvnw -q -DskipTests package

FROM eclipse-temurin:21-jre
COPY --from=build /src/target/*.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
