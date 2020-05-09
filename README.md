# W-A-R-I-O
> An opinionated GitHub multi-repo wiz bang doodle. Written in Dart.

![WARIO](https://i.imgur.com/rnBMps7.png)

## Installation
WARIO requires the latest version of [Dart](https://www.dartlang.org/). You can download the latest and greatest [here](https://www.dartlang.org/tools/sdk#install). After that's all worked out, install WARIO as a global:

```sh
$ pub global activate wario
```

After installation, you'll need to go create a [personal access token](https://github.com/settings/tokens) in GitHub.  Take this token, and save it as an environment variable named `WARIO_GH_TOKEN`.

## Usage
Run `wario` to see the list options. It currently supports the following commands:

#### wario init
Download all of the repositories (currently hard coded) in your config.  This will clone all of the repositories under the `CWD/.wario` directory.

```sh
$ wario init --language nodejs
```

#### wario exec
Execute a command against every subdirectory (non-recursive) in the CWD. Especially useful for random git commands:

```sh
$ wario exec -- git checkout -b datfix
$ wario exec -- git commit -a -m 'fix: make us go'
$ wario exec -- git push origin datfix
```

## License
[Apache 2.0](LICENSE)
