# Proyecto Prueba Fudo

Este proyecto utiliza Docker para su construcción y ejecución.

## Requisitos

- Docker
- Docker Compose

## Instrucciones

1. Clona este repositorio:

  ```bash
  git clone <URL_DEL_REPOSITORIO>
  cd prueba-fudo
  ```

2. Construye y ejecuta el proyecto:

  ```bash
  docker compose up --build prueba-fudo
  ```

  luego puedes omitir el parametro --build para correrlo

3. Para ejecutar los tests:

  ```bash
  docker compose up tests
  ```
