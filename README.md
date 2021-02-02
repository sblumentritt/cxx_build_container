# C++ build container

This repository holds container files to compile source code on other Linux
operating systems with newer tools.

[[_TOC_]]

> The container files are only tested with [podman][] but should also work with
> [Docker][].

## Usage

- When running the containers and interactive shell is entered as the
  `developer` user.
- Source code should be mounted at `/home/developer/src` which is also the
  default workdir.
- When using [podman][] to run the containers add `--userns=keep-id` which also
  the read and write in the mounted volume.

## TODO

- move the installation logic of newer software into a shell script to share it
- create symlinks for the LLVM tools which are suffix with a number
- add container files for other Debian and Ubuntu version
- add a newer version of Doxygen into the container

## License

The project is licensed under the MIT license. See [LICENSE](LICENSE) for more
information.

[podman]: https://podman.io/
[Docker]: https://www.docker.com/
