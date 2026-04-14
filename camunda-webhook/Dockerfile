# ── Stage 1: Build the webhook plugin JAR ───────────────────────────────────
FROM maven:3.9-eclipse-temurin-11 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn dependency:go-offline -q
RUN mvn package -DskipTests -q

# ── Stage 2: Custom Camunda image with plugin ────────────────────────────────
FROM camunda/camunda-bpm-platform:7.21.0

# JAR in Tomcat shared lib
COPY --from=builder /build/target/camunda-webhook-plugin-1.0.0.jar \
     /camunda/lib/camunda-webhook-plugin.jar

# Plugin-Registrierung via bpm-platform.xml
COPY bpm-platform.xml /camunda/conf/bpm-platform.xml