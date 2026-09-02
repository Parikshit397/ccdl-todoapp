# Multi-stage build: same todo.war artifact Lab 5 taught, now built and run
# entirely inside Docker — no local JDK/Maven install required.

# ===== Stage 1: build the WAR =====
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

# Copy just the pom first so dependency resolution is cached separately from
# source changes (a source-only edit won't re-download every dependency).
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B clean package -DskipTests
# Tests are deliberately skipped here — see the testing sections above for
# how to run all 9 test types; the image build isn't where that happens.

# ===== Stage 2: run it on Tomcat =====
FROM tomcat:10.1-jdk17-temurin
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /build/target/todo.war /usr/local/tomcat/webapps/todo.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
