all: check test

check:
	v fmt -w .
	v vet .

test:
	v test .

version:
	npx conventional-changelog-cli -p angular -i CHANGELOG.md -s
