# How to run the tests

## Installation

The project uses a Python stack for unit tests. It is suggested to use `pipenv` (https://pipenv.pypa.io/en/latest/) to manage dependencies.

Once `pipenv` is installed:

``` shell
$ pipenv --python $PATH_TO_PY_38 shell
# once inside the virtualenv
$ pipenv install
```

## Testing

Once all of the dependencies are installed, you can use `pytest` (inside the virtualenv you have created). The `-n auto` flag will attempt to parallelize the test runs.

``` shell
$ pytest -n auto tests
```
