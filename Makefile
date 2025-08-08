.PHONY: build test example clean

# Build the package
build:
	swift build

# Run tests
test:
	swift test

# Build and run the speaker example
example: build
	swift run --package-path . --target SpeakerExample

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Run speaker example 1
example1: build
	swift run --package-path . --target SpeakerExample 1

# Run speaker example 2
example2: build
	swift run --package-path . --target SpeakerExample 2 