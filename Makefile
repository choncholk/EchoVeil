.PHONY: build test clean deploy

build:
	forge build

test:
	forge test

clean:
	forge clean

deploy:
	forge script scripts/Deploy.s.sol --broadcast

gas-report:
	forge test --gas-report

coverage:
	forge coverage

lint:
	npm run lint

format:
	forge fmt

