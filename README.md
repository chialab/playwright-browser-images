# Playwright browser images

This repository automatically publishes Docker images to GitHub Container Registry whenever a new version of [Playwright](https://playwright.dev/) is detected on npm.
For each browser (`chromium`, `firefox`, `webkit`), two tags are published: `<browser>-<version>` and `<browser>-latest`.
Every image is built for `linux/amd64` and `linux/arm64`, so it also runs natively on ARM machines such as Apple Silicon Macs and ARM runners.

To rebuild the images of a version that is already published, for example to add a new architecture, run the workflow manually and set its `version` input.

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