# My Awesome List of Elixir libraries

This is Phoenix web application for representation of [Awesome Elixir](https://github.com/h4cc/awesome-elixir) list of libraries with an additional info such as: amount of stars, number of days since the last push. It is possible to filter libraries by min number of stars, by using /?min_stars=`n` parameter.

## Docker-compose installation
  * Check .env file, make sure all the env variables set:
    * My Awesome List Web service env variables:
      * MIX_ENV - MIX_ENV to use to build app at build of docker image;
      * SECRET_KEY_BASE - used to encrypt and sign session to db, could be generated with `mix phx.gen.secret`;
      * GITHUB_API_TOKEN - [Github API Token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
      * PORT - Phoenix Endpoint port(inside container);
    * Postgres db env variables:
      * POSTGRES_HOST
      * POSTGRES_PORT
      * POSTGRES_DB
      * POSTGRES_USER
      * POSTGRES_PASSWORD
  * Configure different `ports` in docker-compose.yaml if you would like
  * Build services `docker-compose build`
  * Start services with `docker-compose up`

  Now you can visit [`localhost:4001`](http://localhost:4001) from your browser.

## Local installation
  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Setup postgresql db on localhost
  * Configure db connection options in `dev.exs` if needed.
    * Defaults:  
      * username: "postgres",
      * password: "postgres",
      * database: "my_awesome_list_dev",
      * hostname: "localhost",
  * Create and migrate database with `mix ecto.setup`
  * Add your [GitHub Api Token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token#creating-a-token) value in `dev.secret.exs`
  * Start Phoenix endpoint with `mix phx.server`

  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Run Tests
  * `mix deps.get`
  * `MIX_ENV=test mix ecto.reset`
  * `mix test`
