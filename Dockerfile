FROM golang:1.14.6-alpine3.12 AS builder

WORKDIR /build
RUN adduser -u 10001 -D app-runner

ENV GOPROXY https://goproxy.cn
COPY go.mod .
#COPY go.sum .
#RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -a -o hello .

FROM alpine:3.12 AS final

WORKDIR /app
COPY --from=builder /build/hello /app/
#COPY --from=builder /build/config /app/config
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

USER app-runner
ENTRYPOINT ["/app/hello"]