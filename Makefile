# Install HomeBrew
# Install swift-format
# Set up git pre-commit hook
# Clone env repository
# Set up .env file
init:
	sh Scripts/init.sh

# Format Swift files
format:
	swift-format -i -r -p .

# Read iOS Certificates
match-read:
	bundle exec fastlane match development --readonly

# Update iOS Certificates
match-update:
	bundle exec fastlane match development

# Pull changes in .env repository
env-pull:
	@cd .env && git pull || echo "Nothing to pull"

# Push changes in .env repository
env-push:
	@cd .env && git add . && git commit -m "Update env variables" || echo "Nothing to commit"
	@cd .env && git push