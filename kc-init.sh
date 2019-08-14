# Helper shell function to let tools like kubecfg and work with aws-vault
#
# Installation: see README.md
#
# This file expects to be sourced from a compatible shell (such as Bash or ZSH)
# and defines the `kc` shell function.
#
# Usage:
#  - Run `kc context` to use the given context by default in the current shell
#  - Run `kc context namespace` to use the given context and namespace
#  - Run `kc` to list contexts and reset your shell to normal

if test -n "$ZSH_VERSION"; then
  if [[ "$ZSH_EVAL_CONTEXT" == 'toplevel' ]]; then
      echo "You're running $0, but the correct way to use it is to source it in your current shell (so that it can create aliases for you.)" >&2
      echo "Run 'source $0' instead!" >&2
      exit 2
  fi
elif test -n "$BASH_VERSION"; then
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
      echo "You're running $0, but the correct way to use it is to source it in your current shell (so that it can create aliases for you.)" >&2
      echo "Run 'source $0' instead!" >&2
      exit 2
  fi
fi

if [[ "${KC_EKS_ALIASES:-0}" -eq 1 ]]; then
  if ! hash aws-vault > /dev/null 2>&1; then
      echo "Expected aws-vault to be on PATH; kc is configured for EKS" >&2
      exit 1
  fi
fi

# Colors for iterm2 tabs
if [[ "${TERM_PROGRAM}" == "iTerm.app" ]]; then
  if [[ ${KC_ITERM_TAB_COLOR:-0} -eq 1 ]]; then
    function __kc_tab_color() {
      echo -ne "\033]6;1;bg;red;brightness;${1:-}\a\033]6;1;bg;green;brightness;${2:-}\a\033]6;1;bg;blue;brightness;${3:-}\a"
    }

    function __kc_tab_color_reset() {
      echo -ne "\033]6;1;bg;*;default\a"
    }
  fi

  if [[ ${KC_ITERM_USER_VAR:-1} -eq 1 ]]; then
    function __kc_user_var() {
      printf "\033]1337;SetUserVar=%s=%s\007" "$1" "$(printf "%s" "$2" | base64 | tr -d '\n')"
    }
  fi
fi

# Announce the context change
function __kc_on() {
  # shellcheck disable=SC2034
  if typeset -f kubeon > /dev/null; then
    if [[ ${KC_KUBE_PS1_TOGGLE:-1} -eq 1 ]]; then
      kubeon
    fi
  fi

  if [[ "${TERM_PROGRAM}" == "iTerm.app" ]]; then
    if [[ ${KC_ITERM_TAB_COLOR:-0} -eq 1 ]]; then
      case "${__kc_context}" in
        *prod*)
          __kc_tab_color 251 107  98 # red
          ;;
        *staging*)
          __kc_tab_color  95 164 248 # blue
          ;;
        *docker*)
          __kc_tab_color 181 215  73 # green
          ;;
        *)
          __kc_tab_color_reset
          ;;
      esac
    fi

    if [[ ${KC_ITERM_USER_VAR:-1} -eq 1 ]]; then
      __kc_user_var kubecontext "${__kc_context}"
      __kc_user_var kubens "${__kc_ns}"
    fi
  fi

  if [[ -z "${__kc_ns}" ]]; then
    echo "Using context ${__kc_context}"
  else
    echo "Using context ${__kc_context} and namespace ${__kc_ns}"
  fi
}

# Announce the reset
function __kc_off() {
  # shellcheck disable=SC2034
  if typeset -f kubeoff > /dev/null; then
    if [[ ${KC_KUBE_PS1_TOGGLE:-1} -eq 1 ]]; then
      kubeoff
    fi
  fi

  if [[ "${TERM_PROGRAM}" == "iTerm.app" ]]; then
    if [[ ${KC_ITERM_TAB_COLOR:-0} -eq 1 ]]; then
      __kc_tab_color_reset
    fi

    if [[ ${KC_ITERM_USER_VAR:-1} -eq 1 ]]; then
      __kc_user_var kubecontext ""
      __kc_user_var kubens ""
    fi
  fi
}

# The main kc function
function kc() {
  if [[ -z "${__KC_CONFIG_DIR:-}" ]]; then
    __KC_CONFIG_DIR=$(mktemp -d)
    export __KC_CONFIG_DIR
  fi

  __kc_context=${1:-}
  __kc_ns=${2:-}

  if [[ -n "${__kc_context}" ]]; then
    # Set the KUBECONFIG to a generated config with the given context and/or namespace
    if [[ -z "${__kc_config_previous:-}" && -n "${KUBECONFIG:-}" && "${KUBECONFIG:-}" != ${__KC_CONFIG_DIR}* ]]; then
      __kc_config_previous="${KUBECONFIG}"
    fi

    local config="${__KC_CONFIG_DIR}/${__kc_context}"

    if [[ -n "${__kc_ns}" ]]; then
      config="${config}.${__kc_ns}"
    fi

    config="${config}.config"

    if [[ ! -f "${config}" ]]; then
      if [[ -n "${__kc_config_previous:-}" ]]; then
        export KUBECONFIG="${__kc_config_previous}"
      else
        unset KUBECONFIG
      fi

      if ! kubectl config view --minify --flatten --context="${__kc_context}" > "${config}"; then
        rm -rf "${config}"
        return 1
      fi

      # Temporary export for next two commands
      export KUBECONFIG="${config}"

      if [[ -n "${__kc_ns}" ]]; then
        if ! kubectl config set-context "${__kc_context}" --namespace="${__kc_ns}" > /dev/null; then
          rm -rf "${config}"
          return 2
        fi
      fi

      if ! kubectl config set current-context "${__kc_context}" > /dev/null; then
        rm -rf "${config}"
        return 3
      fi
    fi

    export KUBECONFIG="${config}"

    if [[ "${KC_EKS_ALIASES:-0}" -eq 1 ]]; then
      assume_role_ttl="${KC_EKS_ASSUME_ROLE_TTL:-60m}"

      # shellcheck disable=SC2139
      alias kubectl="aws-vault exec --assume-role-ttl=${assume_role_ttl} ${__kc_context} -- kubectl"
      # shellcheck disable=SC2139
      alias helm="aws-vault exec --assume-role-ttl=${assume_role_ttl} ${__kc_context} -- helm"
    fi

    __kc_on
  else
    # Reset KUBECONFIG to its previous value
    if [[ -n "${__kc_config_previous:-}" ]]; then
      export KUBECONFIG="${__kc_config_previous}"
    else
      unset KUBECONFIG
    fi

    # Unalias common tools
    if [[ "${KC_EKS_ALIASES:-0}" -eq 1 ]]; then
      unalias kubectl 2>/dev/null
      unalias helm 2>/dev/null
    fi

    __kc_off

    echo "Possible contexts are:"
    kubectl config get-contexts -o=name | sort -n
  fi

  return 0
}
