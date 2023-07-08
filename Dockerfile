FROM elixir:1.15.1-otp-25-alpine AS deps

WORKDIR /app
ENV MIX_ENV=dev

RUN apk add --no-cache git && \
    mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./

RUN mix deps.get && \
    mix deps.compile

COPY lib/ lib/
COPY priv/ priv/

RUN mix compile

ENTRYPOINT [ "mix" ]
