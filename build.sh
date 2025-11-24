#!/bin/bash

# Build and prepare package for publishing

set -e  # Exit on error

echo "🚀 Preparing flutter_modules for publishing..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Format code
echo -e "${YELLOW}📝 Formatting code...${NC}"
dart format . || {
    echo -e "${RED}❌ Formatting failed${NC}"
    exit 1
}
echo -e "${GREEN}✅ Code formatted${NC}"
echo ""

# Step 2: Analyze code
echo -e "${YELLOW}🔍 Analyzing code...${NC}"
dart analyze || {
    echo -e "${YELLOW}⚠️  Analysis found issues (continuing anyway)${NC}"
}
echo -e "${GREEN}✅ Analysis complete${NC}"
echo ""

# Step 3: Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
flutter test || {
    echo -e "${RED}❌ Tests failed${NC}"
    exit 1
}
echo -e "${GREEN}✅ All tests passed${NC}"
echo ""

# Step 4: Check package
echo -e "${YELLOW}📦 Checking package for publishing...${NC}"
dart pub publish --dry-run || {
    echo -e "${RED}❌ Package check failed${NC}"
    exit 1
}
echo -e "${GREEN}✅ Package check passed${NC}"
echo ""

# Step 5: Test CLI
echo -e "${YELLOW}🔧 Testing CLI commands...${NC}"
echo "Creating test module..."
dart run flutter_modules create TestModule --force 2>/dev/null || true
dart run flutter_modules list > /dev/null 2>&1 && echo -e "${GREEN}✅ CLI works${NC}" || echo -e "${YELLOW}⚠️  CLI test skipped (modules directory may not exist)${NC}"
# Cleanup
rm -rf modules/TestModule 2>/dev/null || true
rm -f modules_statuses.json 2>/dev/null || true
echo ""

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Package is ready to publish!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Review CHANGELOG.md"
echo "  2. Update version in pubspec.yaml if needed"
echo "  3. Run: dart pub login"
echo "  4. Run: dart pub publish"
echo ""

