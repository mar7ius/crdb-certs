FROM maven:3.8-eclipse-temurin-17 as builder
WORKDIR /app
COPY ./pom.xml ./pom.xml
RUN mvn dependency:go-offline -B
COPY ./src ./src
RUN mvn package && cp target/*.jar application.jar
RUN java -Djarmode=layertools -jar application.jar extract

FROM mar7ius/cockroach_macos_arm:v22.1.3_arm64 as cockroach

FROM eclipse-temurin:17-jdk
COPY --from=builder /app/dependencies/ ./
COPY --from=builder /app/snapshot-dependencies/ ./
COPY --from=builder /app/spring-boot-loader/ ./
COPY --from=builder /app/application/ ./
COPY --from=cockroach /cockroach/ ./

RUN mkdir -pv ./.cockroach-certs
RUN mkdir -pv ./.cockroach-key

EXPOSE 9999

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
