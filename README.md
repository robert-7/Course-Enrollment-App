# Course Enrollment App

![Python](https://img.shields.io/badge/Python-3.13-blue?logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-3.1-lightgrey?logo=flask&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-8.2-green?logo=mongodb&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker&logoColor=white)

A full-stack Flask web application for course enrollment with user
authentication, MongoDB-backed data models, REST APIs with Swagger docs,
and a fully containerized Docker Compose setup.

![App Walkthrough](docs/walkthrough.gif)

## Quick Start

Make sure [Docker](https://docs.docker.com/get-docker/) is installed, then run:

```bash
docker compose build
docker compose up -d
```

The app will be available at [http://localhost:5000](http://localhost:5000). The Swagger API docs are at [http://localhost:5000/api](http://localhost:5000/api).

To tear everything down:

```bash
docker compose down -v
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for environment setup, linting, Postman, and other developer instructions.

## Features to try

Please see [the testing documentation](TESTING.md) that showcases an end-to-end demo of features supported.

## Notes about Files and Folders

Some important files and folders are seen below:

* **application/** — Flask app (routes, models, forms, templates)
* **mongo-setup/** — MongoDB seed data and initialization script
* **Docker Compose** orchestrates the Flask app, MongoDB, and seed containers

## Acknowledgments

This project was originally based on the LinkedIn Learning course
["Full Stack Web Development with Flask"](https://www.linkedin.com/learning/full-stack-web-development-with-flask).
It has since been extended with Docker containerization, CI/CD pipelines,
rebranded course data, and additional tooling.
