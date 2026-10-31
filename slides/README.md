# Sobel accelerator slides

Five-slide Slidev deck based on `numbers.md`. The two architecture sketches each have their own slide.

Run from this directory:

```sh
pnpm install
pnpm dev
```

Open the local URL printed by Slidev. Use the arrow keys to navigate.

```sh
pnpm build   # static site in dist/
```

For PDF export, install the browser dependency once, then export:

```sh
pnpm exec playwright install chromium
pnpm export
```
