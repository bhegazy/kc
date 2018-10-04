_kc_contexts() {
  local cur;
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($(compgen -W "$(kubectl config get-contexts --output='name')" -- $cur ));
}

complete -F _kc_contexts kc
