# ADF/ACS Application with Angular CLI

Minimal ready-to-use Angular CLI project template pre-configured with ADF 2.0.0 components.

This project was generated with [Angular CLI](https://github.com/angular/angular-cli) version 1.5.0

## Quick start

```sh
npm install
npm start
```

## Creating an image

The generated app provides a "Dockerfile" file in the repository root.
You can build the image with the following command:

```sh
docker image build -t YOUR_NAME_APP .
```

## Helm chart

```sh
helm install . --namespace example
