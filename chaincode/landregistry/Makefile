# Makefile for Land Registry Chaincode

CHAINCODE_NAME=landregistry
CHAINCODE_VERSION=1.0
CHAINCODE_PATH=github.com/landregistry/chaincode
FABRIC_VERSION=2.5.3

.PHONY: all build test clean vendor

all: build

# Build the chaincode
build:
	@echo "Building chaincode..."
	go build -o $(CHAINCODE_NAME)

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -f $(CHAINCODE_NAME)
	go clean

# Download dependencies
vendor:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	golangci-lint run || echo "golangci-lint not installed, skipping..."

# Package chaincode (for deployment)
package:
	@echo "Packaging chaincode..."
	@mkdir -p ../packaged
	tar -czf ../packaged/$(CHAINCODE_NAME).tar.gz .

# Install dependencies for testing
test-deps:
	@echo "Installing test dependencies..."
	go get github.com/stretchr/testify/assert
	go get github.com/stretchr/testify/mock
