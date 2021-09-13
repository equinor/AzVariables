# AzVariables - Manage workflow variables

[![Action-Test](https://github.com/equinor/AzVariables/actions/workflows/Action-Test.yml/badge.svg)](https://github.com/equinor/AzVariables/actions/workflows/Action-Test.yml)

[![Linter](https://github.com/equinor/AzVariables/workflows/Linter/badge.svg)](https://github.com/equinor/AzVariables/actions/workflows/Linter.yml)

[![GitHub](https://img.shields.io/github/license/equinor/AzVariables)](LICENSE)

This action manages environment variables. It can:

- Load custom variables.
- List environment variables which are present on the GitHub runner.
- Load variables from a json file into a GitHub runners environment variables. Will also load variables from files referenced by the main json file.

## Why use this module?

This action addresses the need for defining variables as code, which can be reused for **all deployments** in the repo in addition to using the secrets and environments
defined for the repo.

## Inputs

| Input name         | Default | Required | Description                                              | Allowed values                            |
| :----------------- | :------ | :------- | :------------------------------------------------------- | :---------------------------------------- |
| `Load`             | `true`  | No       | Load environment variables from variable file to runner. | `true`/`false`                            |
| `List`             | `false` | No       | List environment variables on runner                     | `true`/`false`                            |
| `VariableFilePath` | ''      | Yes      | Path to a variables json file.                           | Relative or absolute path to a json file. |

### Input overrides

This action uses environment variables with input overrides. For more info please read our article on [Input handling](https://github.com/equinor/AzActions#input-handling)

### Input parameter: `VariableFilePath`

Takes a relative or absolute path to a json file containing variables.
If `VariableFilePath` is not provided with this action, the environment variable called `VariableFilePath` is checked and used instead.
If neither are present, the variable loader will not be invoked and the script will exit with a failure.

### Example of variables json file

```json
{
    "MascotName": "Super Cat",
    "Superpower": "Lazer shooting eyes",
    "VariableFilePaths": [
        "./Folder/Vars.json"
        "./GlobalVars.json"
    ]
}
```

### Loading referenced variables json files

Referenced variables json files can be loaded by using the `VariableFilePaths` item. This item takes an array of paths to other files.
Referenced files are loaded before the variables in the first file, leading to variables in referenced files being overridden by the first file.

Lets take a look at an example of 3 variables files, `A.json`, `B.json` and `C.json`. Each of the files contains the letters in a variable called `Letter`. File `A.json` also has a `VariableFilePaths` array with file `B` and `C`.
The loading process would be as following:

1. Runner reads file content of file `A.json`.
2. Process files in  `VariableFilePaths` from file `A.json`.
   1. Runner reads file content of file `B.json`.
      1. Process files in `VariableFilePaths`- It's empty, so the action continues.
      2. Load variables of file `B.json`. `Letter = B`.
   2. Runner reads file content of file `C.json`.
      1. Process files in `VariableFilePaths`- It's empty, so the action continues.
      2. Load variables of file `C.json`. `Letter = C`.
3. Load variables in file `A.json`. `Letter = A`.

We see here that the last write wins and `Letter` has been overridden twice, and is `A` at the end of the loading process.

To see this in action, check out the "Load and list variables" step in the [Action-Test workflow](https://github.com/equinor/AzVariables/actions).

## Outputs

N/A

## Environment variables

This module can load variables into the environment variables of the runner.
The variable names and values of these depend on the variable file which is loaded.
When creating the environment variables, be sure to follow the [recommended naming convention from GitHub](https://docs.github.com/en/actions/reference/environment-variables#naming-conventions-for-environment-variables) when doing so.

In addition there are some missing variables which a GitHub runner should have.

| Variable name            | Description                                                                                                                                                                                                   |
| :----------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `build`                  | A timestamp from when this action is run, following the format `YYYYMMDDhhmmss`. Can be used for constructing [semver version](https://semver.org/) for builds, adding to the `patch` segment of the version. |
| `GITHUB_REPOSITORY_NAME` | The name of the repository where the workflow is being triggered from.                                                                                                                                        |

## Usage

```yml
name: Test-Workflow

on: [push]

env:
  VariableFilePath: Folder/greenVars.json

jobs:
  AzVariables:
    runs-on: ubuntu-latest
    steps:

      - name: Checkout source code
        uses: actions/checkout@v2

      - name: List variables
        uses: equinor/AzVariables@v1
        with:
          List: true
        # Will list environment variables on the runner

      - name: Load variables
        uses: equinor/AzVariables@v1
        # Will load based on env.VariableFilePath, 'Folder/greenVars.json'

      - name: Load and list variables
        uses: equinor/AzVariables@v1
        with:
          Load: true
          List: true
          VariableFilePath: Folder/blueVars.json
        # Will load based on input.VariableFilePath, 'Folder/blueVars.json'.

```

## Dependencies

- [equinor/AzUtilities](https://www.github.com/equinor/AzUtilities)
- If you are looking to load a variable file, run [action/checkout](https://github.com/actions/checkout) first.

## Contributing

This project welcomes contributions and suggestions. Please review [How to contribute](https://github.com/equinor/AzActions#how-to-contibute) on our [AzActions](https://github.com/equinor/AzActions) page.
