# Playwright browser images

This repository automatically publishes Docker images to GitHub Container Registry whenever a new version of [Playwright](https://playwright.dev/) is detected on npm.
For each browser (`chromium`, `firefox`, `webkit`), two tags are published: `<browser>-<version>` and `<browser>-latest`.

The images are based on Alpine Linux and include only the browsers required to run Playwright, without additional dependencies.
They are intended for use in CI environments, such as GitHub Actions.

## Example usage

```yml
name: Playwright tests
on: [push]

jobs:
  test-chromium:
    runs-on: ubuntu-latest
    container: chialab/playwright:chromium-1.58.2
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
      - run: npm install
      - run: npx playwright test --project=chromium
```

## License

**Playwright browser images** is released under the [MIT](https://github.com/chialab/playwright-browser/blob/main/LICENSE) license.