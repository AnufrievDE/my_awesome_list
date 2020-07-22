FROM bitwalker/alpine-elixir-phoenix:1.10.3

## Cache elixir deps
ADD mix.exs mix.lock .env ./
RUN set -o allexport; source .env; set +o allexport && \
    mix do deps.get, deps.compile

## Same with npm deps
ADD assets/package.json assets/
RUN cd assets && \
    npm install

ADD . .

## Run frontend build, compile, and digest assets
RUN set -o allexport; source .env; set +o allexport && \
    cd assets/ && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest

RUN apk --update add postgresql-client

USER default

#ENTRYPOINT ["/opt/app/entrypoint.sh", "mix"] ?
#CMD ["phx.server"] ?
CMD ["/opt/app/entrypoint.sh"]