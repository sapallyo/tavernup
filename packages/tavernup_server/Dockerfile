# Stage 1: Dependencies cachen
FROM dart:3.11 AS deps
WORKDIR /packages
COPY tavernup_domain/pubspec.yaml tavernup_domain/pubspec.yaml
COPY tavernup_auth_supabase/pubspec.yaml tavernup_auth_supabase/pubspec.yaml
COPY tavernup_repositories_supabase/pubspec.yaml tavernup_repositories_supabase/pubspec.yaml
COPY tavernup_process_camunda/pubspec.yaml tavernup_process_camunda/pubspec.yaml
COPY tavernup_server/pubspec.yaml tavernup_server/pubspec.lock tavernup_server/

WORKDIR /packages/tavernup_server
RUN dart pub get

# Stage 2: AOT-Kompilat bauen
FROM dart:3.11 AS builder
WORKDIR /packages
COPY --from=deps /root/.pub-cache /root/.pub-cache
COPY . .

WORKDIR /packages/tavernup_server
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Stage 3: Minimales Runtime-Image
FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /packages/tavernup_server/bin/server ./server
EXPOSE 8080
CMD ["./server"]
