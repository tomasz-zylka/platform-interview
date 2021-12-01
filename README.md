# AWS Chat App

![app](./docs/images/chat.png)

A simple Slack-like chat app built with [Node.js](https://nodejs.org/en/) and [Vue.js](https://vuejs.org/).

## Run it locally

To run the application on your local machine you need:

- `docker`
- `docker-compose`
- `make`

Execute the following command:

```
make run
```

The application will be available at `http://localhost:3000`

If you make changes to the code, you can run:

```
make build
```

This updates the client application.

To run integration tests execute:

```
make test
```

To stop the application execute:
```
make stop
```

## Architecture

![architecture](./docs/images/architecture.png)

The app makes use of the [socket.io-redis](https://github.com/socketio/socket.io-redis-adapter) adaptor, which uses [Redis](https://redis.io/) as a message broker to pass messages between Node.js processes.
[DynamoDB](https://aws.amazon.com/dynamodb/) is used to provide durable persistence for user accounts and message history.
