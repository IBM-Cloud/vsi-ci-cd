vpc:
	cd tf; source ./local.env; terraform init; terraform apply -auto-approve

printenv:
	./sourceenv.sh

