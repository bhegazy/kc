# kc

`kc` is a tool, in the spirit of [kubectx/kubens](https://github.com/ahmetb/kubectx),
that allows you to easily work in multiple Kubernetes contexts. Its main point
of difference is that it manages a _local_ context only; it changes context per
shell, not globally, so you can run commands against two clusters, in different
terminals, at the same time.

This means you're less likely to change contexts in one shell, and then
accidentally run against the production cluster in a different shell where your
[kube-ps1](https://github.com/jonmosco/kube-ps1) says minikube. (In other words,
it works around the lack of a [KUBECONTEXT](https://github.com/kubernetes/kubernetes/issues/27308)
environment variable.)

Because it's a shell function, not an executable, it can also alias common tools
like `helm` to work with EKS via IAM authentication, by making use of
[aws-vault](https://github.com/99designs/aws-vault)

## Usage

```
  kc <CONTEXT>             : switches to the given context
  kc <CONTEXT> <NAMESPACE> : switches to the given context and namespace in the current shell
  kc                       : reset your shell to use your default context and namespace
```

## Installation

### Bash

- Copy `kc-init.sh` somewhere (doesn't have to be on the PATH)
- Source it in your `~/.bashrc`:

  ```bash
  if [[ -f ~/.path/to/kc-init.sh ]]; then
    source ~/.path/to/kc-init.sh
  fi
  ```
- Copy `completion/kc.bash` to your bash completion dir
  (e.g. for Homebrew on Mac OS X, this is `/usr/local/etc/bash_completion.d`):

  ```bash
  cp completion/kc.bash /usr/local/etc/bash_completion.d
  ```

### oh-my-zsh

- Copy or link `kc-init.sh` into your `~/.oh-my-zsh/custom` directory with a
  `.zsh` file extension:

  ```sh
  cp kc-init.sh ~/.oh-my-zsh/custom/kc-init.zsh
  ```
- Copy `completion/kc.zsh` to your `~/.oh-my-zsh/completions` directory:

  ```sh
  mkdir -p ~/.oh-my-zsh/completions
  cp completion/kc.zsh ~/.oh-my-zsh/completions/
  ```

## Configuration

`kc` supports the following environment variables that can alter its behavior:

env | default | behavior
--- | --- | ---
`KC_KUBE_PS1_TOGGLE` | 1 | Whether to turn the kube-ps1 prompt display on and off automatically based on whether kc has set an active context
`KC_TAB_COLOR` | 1 | Whether to change the iTerm2 tab color automatically based on the context name (e.g. red for `prod` anywhere in the context name)
`KC_EKS_ALIASES` | 1 | Whether to alias `kubectl` and `helm` to use AWS IAM authentication via `aws-vault`

## Limitations

- When `kc` is configured for EKS, it always uses `aws-vault` authentication and
assumes your context name is the same as your AWS authentication profile name
- `kc` has only been tested on Mac OS X so far
