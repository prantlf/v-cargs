all: check test

check:
	v fmt -w .
	v vet .

test:
	v -use-os-system-to-run test .
	v -use-os-system-to-run run src/help_test.v
	v -use-os-system-to-run run src/version_test.v
