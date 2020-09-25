.PHONY: test

test:
	docker-compose build --pull release
	docker-compose build
	docker-compose run test