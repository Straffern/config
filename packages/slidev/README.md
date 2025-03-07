# Slidev Package for NixOS

A Nix package for [Slidev](https://sli.dev) using Bun as the runtime.

## Usage

Build with `nix build .#slidev` and run with `result/bin/slidev <path-to-slides.md>`.

### Creating a New Presentation

1. Create a directory for your presentation:
   ```bash
   mkdir my-presentation
   cd my-presentation
   ```

2. Create a `slides.md` file with your presentation content:
   ```markdown
   # Welcome to Slidev

   Presentation slides for developers

   ---

   # Page 2

   Directly use code snippets for highlighting

   ```ts
   console.log('Hello, World!')
   ```

   ---

   # Page 3

   * Item 1
   * Item 2
   * Item 3
   ```

3. Run Slidev:
   ```bash
   slidev slides.md
   ```

4. For more information, visit the [Slidev documentation](https://sli.dev).