all: check test

check:
	v fmt -w .
	v vet .

test:
	v test .
	v run help_test.v
	v run version_test.v
