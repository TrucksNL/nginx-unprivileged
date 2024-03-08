FROM alpine AS builder

RUN mkdir /sock \
    && chown -R nobody:nobody /sock


FROM nginxinc/nginx-unprivileged:stable-alpine-slim

COPY --chown=nobody --from=builder /sock /sock

VOLUME ["/sock"]

COPY --link --chown=nobody ./default.conf /etc/nginx/conf.d/default.conf

USER nobody
