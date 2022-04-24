# Needed a 8u202 image to run this, this one works
FROM lwieske/java-8:jdk-8u202-slim as build

WORKDIR /app

COPY . .

# Build
RUN chmod +x ./gradlew
RUN ./gradlew
RUN ./gradlew jar

FROM alpine/git:latest as git
WORKDIR /app/
RUN git clone https://github.com/Dimbreath/GenshinData.git
RUN git clone https://github.com/radioegor146/gi-bin-output.git
RUN git clone https://github.com/Grasscutters/Grasscutter-Protos.git

# Download and switch to development branch
RUN git clone https://github.com/Grasscutters/Grasscutter.git
RUN sh -c "cd Grasscutter && git checkout development"


FROM lwieske/java-8:jdk-8u202-slim as run
WORKDIR /app

# Copy the jar to the run image
COPY --from=build /app/grasscutter.jar .

# Run jar to generate files & folders, ignore errors
RUN java -jar grasscutter.jar | :

# Download all genshin files
RUN mkdir -p /app/resources/
COPY --from=git /app/GenshinData/ /app/resources/
COPY --from=git /app/gi-bin-output/ /app/resources/BinOutput/
COPY --from=git /app/Grasscutter-Protos/ /app/proto/
COPY --from=git /app/Grasscutter/keys /app
COPY --from=git /app/Grasscutter/data /app
COPY --from=git /app/Grasscutter/keystore.p12 /app
# Don't know what this does, but the wiki says it should be run
RUN java -jar grasscutter.jar -handbook | :

EXPOSE 8080
ENTRYPOINT ["sh", "-c"]
CMD ["java -jar grasscutter.jar"]