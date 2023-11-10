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

## Documented Iterative Development in Git History

Use `git log --reverse` to see a run-down of how we built `pnpm-only-template`.

## Enforcing pnpm as the Exclusive Package Manager: What We Tried

Ensuring that pnpm is the sole package manager for our projects required some research and community contributions. Special thanks to those who have shared insights on this topic.

## Disabling `yarn`

Disabling yarn as a package intaller was easiest.

Running [`only-allow`](https://github.com/pnpm/only-allow) in the preinstall script stops `yarn`, `yarn add` and `yarn install`: even with an un-initialized project. The results can be seen below.

```bash
$ yarn add {package}, yarn install or yarn
yarn add v1.22.19
info No lockfile found.
$ npx only-allow pnpm
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║   Use "pnpm install" for installation in this project.      ║
║                                                             ║
║   If you don't have pnpm, install it via "npm i -g pnpm".   ║
║   For more details, go to https://pnpm.js.org/              ║
║                                                             ║
╚═════════════════════════════════════════════════════════════╝
error Command failed with exit code 1.
info Visit https://yarnpkg.com/en/docs/cli/add for documentation
about this command.
```

## Disabling `npm`

It takes a little more work to disable `npm` from installing packages because `npm` installs packages before calling the `preinstall` script.

To stop `npm` from installing packages, we needed to add to `package.json`:

```json
// package.json
{
  "engines": {
    "npm": "Use pnpm instead of npm."
  }
}
```

and create a `.npmrc` files with `engine-strict=true`:

```bash
echo "# Stop npm from being used as the installer.
# The following was added to package.json
# { \"engines\": { \"npm\": \"Use pnpm instead of npm.\" } }
engine-strict=true" > .npmrc
```

Running `npm install` and `npm add` now shows the following error:

```bash
$ npm install
npm ERR! code EBADENGINE
npm ERR! engine Unsupported engine
```

### What Sort of Works

#### Pnpm Used to Initialize a Project

If a project has already been initialized by running `pnpm install`, running `npm` results in an error:

```bash
$ npm install
npm ERR! Cannot set properties of null (setting 'peer')
npm ERR! A complete log of this run can be found in: ....
```

#### Remove npm (not always possible)

Removing `npm` from the developers machine is an option.

#### Script a Replacement (not recommended)

In a project, create a script named `npm` and add the current working directory to `$PATH`.

```bash
# create the file

echo -e '#!/bin/bash
echo "Please use pnpm."
exit 1' > npm && chmod +x npm

# you can run it as follows but calling

$ ./npm

# this still runs npm
$ npm

# WARNING: Adding the current directory as part of the PATH can
# be dangerous.
# prepend the current working directory to your path
# MUST be prepended so the npm script will override npm
echo 'export PATH=".:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

### What Doesn't Work

### Using Package.json packageManager option

At the time of writing, there is an experimental [packageManager](https://nodejs.org/api/packages.html#packagemanager) option in `package.json` which doesn't seem to work yet.