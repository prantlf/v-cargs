all: check test

check:
	v fmt -w .
	v vet .

test:
	v test .
	v run src/help_test.v
	v test src/version_test.v
