FROM eclipse-temurin:21-jdk AS build
RUN apt-get update && apt-get install -y git
RUN git clone --depth 1 https://github.com/spring-projects/spring-petclinic.git /src
WORKDIR /src
RUN grep -q micrometer-registry-prometheus pom.xml || sed -i '0,/<\/dependencies>/s##<dependency><groupId>io.micrometer</groupId><artifactId>micrometer-registry-prometheus</artifactId></dependency></dependencies>#' pom.xml
ENV MAVEN_OPTS="-Xmx700m"
RUN --mount=type=cache,target=/root/.m2 ./mvnw -q -B -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Dmaven.javadoc.skip=true package

FROM eclipse-temurin:21-jre
COPY --from=build /src/target/*.jar /app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
