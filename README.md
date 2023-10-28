# pnpm-only-template

A project that demonstrates how to set up a Node.js project: configured to only allow installation using pnpm.

The [pnpm-only.sh](./pnpm-only.sh) shell script was ran against this project creating the `.npmrc` file and adding appropriate scripts in `package.json`.

## pnpm-only shell script

Executing the `pnpm-only.sh` bash script within a project directory configures the environment to exclusively use `pnpm` for package management.

You can verify the shell script at [https://raw.githubusercontent.com/erichosick/pnpm-only-template/main/pnpm-only.sh](https://raw.githubusercontent.com/erichosick/pnpm-only-template/main/pnpm-only.sh).

```bash
# NOTE: Always review shell scripts before running them on your machine.
curl -sL https://raw.githubusercontent.com/erichosick/pnpm-only-template/main/pnpm-only.sh | bash
```
