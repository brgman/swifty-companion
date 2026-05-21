
.PHONY: prod dev build re

build-dev:
	docker compose -f docker-compose.dev.yml build

prod:
	docker compose -f docker-compose.yml up

dev:
	docker compose -f docker-compose.dev.yml up

re:
	docker stop swifty_companion_swifty-companion_1
	docker rm swifty_companion_swifty-companion_1
	docker compose -f docker-compose.dev.yml build
	docker compose -f docker-compose.dev.yml up