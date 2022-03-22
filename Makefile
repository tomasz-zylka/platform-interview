ECR_REPO = 550346457415.dkr.ecr.eu-central-1.amazonaws.com/graphy-chat
ECR_TAG = latest

build:
	CLIENT_IMAGE=$(ECR_REPO):$(ECR_TAG) docker-compose build client 

run:
	CLIENT_IMAGE=$(ECR_REPO):$(ECR_TAG) docker-compose -p chat-app up -d

run/attached:
	CLIENT_IMAGE=$(ECR_REPO):$(ECR_TAG) docker-compose -p chat-app up

test:
	docker-compose -f docker-compose.test.yml -p chat-app run  --no-deps test

test/rebuild:
	docker-compose -f docker-compose.test.yml -p chat-app up --build  --no-deps test

stop:
	docker-compose -p chat-app down --remove-orphans

docker/login:
	aws --region eu-central-1 ecr get-login-password | docker login --username AWS --password-stdin $(ECR_REPO)

docker/push:
	docker push $(ECR_REPO):$(ECR_TAG)