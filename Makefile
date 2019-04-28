.PHONY: deploy
deploy:
	@kubectl apply -f kubernetes/pvc.yaml -f kubernetes/secret.yaml -f kubernetes/deployment.yaml -f kubernetes/service.yaml
