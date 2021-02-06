# C++ build container

This repository holds container files to compile source code on other Linux
operating systems with newer tools.

## Table of Contents

* [Usage](#usage)
* [TODO](#todo)
* [License](#license)

> The container files are only tested with [podman][] but should also work with
> [Docker][].

## Usage

- When running the containers and interactive shell is entered as the
  `developer` user.
- Source code should be mounted at `/home/developer/src` which is also the
  default workdir.
- When using [podman][] to run the containers add `--userns=keep-id` which
  allows read and write operations in the mounted volume.

## TODO

- add a newer version of Doxygen into the container
- find a way to use `COPY`/`ADD` instead of the `wget` workaround

## License

The project is licensed under the MIT license. See [LICENSE](LICENSE) for more
information.

[podman]: https://podman.io/
[Docker]: https://www.docker.com/
