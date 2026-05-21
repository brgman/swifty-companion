
.PHONY: prod dev build build-dev re

build:
	docker compose -f docker-compose.yml build

build-dev:
	docker compose -f docker-compose.dev.yml build --no-cache
	docker compose -f docker-compose.dev.yml up

prod: build
	docker compose -f docker-compose.yml up

dev:
	docker compose -f docker-compose.dev.yml up

re:
	docker stop swifty_companion_swifty-companion_1
	docker rm swifty_companion_swifty-companion_1
	docker compose -f docker-compose.dev.yml build --no-cache
	docker compose -f docker-compose.dev.yml up

migrate:
	podman system migrate