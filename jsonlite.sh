#!/usr/bin/env bash
set -eo pipefail; [[ $TRACE ]] && set -x

VERSION="0.4.2"
CWD=$(pwd);

jsonlite_is_valid_uuid() {
  if [[ "$1" =~ ^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$ ]]; then
    echo true
  fi

  echo false
}

jsonlite_set() {
  local value="$1"
  if [[ -z "$value" ]]; then
    echo "Missing required argument json document" 1>&2
    exit 1;
  fi

  if [[ ! -d "$CWD/jsonlite.data" ]]; then
    mkdir "$CWD/jsonlite.data"
  fi

  # Is this portable across distros?
  UUID=$(uuidgen | awk '{print toupper($0)}')

  # Piping to python -m json.tool to pretty print json is super expensive.
  # What would be a good alternative?
  echo "$value" | python -m json.tool > "$CWD/jsonlite.data/$UUID"
  echo "$UUID";
}

jsonlite_get() {
  local document_id="$1"
  if [[ -z "$document_id" ]]; then
    echo "Missing required argument document id" 1>&2
    exit 2;
  fi

  VALID=$(jsonlite_is_valid_uuid "$document_id")
  if [[ "$VALID" = false ]]; then
    echo "Invalid argument document id" 1>&2
    exit 3;
  fi

  if [[ -f "$CWD/jsonlite.data/$document_id" ]]; then
    cat "$CWD/jsonlite.data/$document_id"
  fi
}

jsonlite_delete() {
  local document_id="$1"
  if [[ -z "$document_id" ]]; then
    echo "Missing required argument document id" 1>&2
    exit 2;
  fi

  VALID=$(jsonlite_is_valid_uuid "$document_id")
  if [[ "$VALID" = false ]]; then
    echo "Invalid argument document id" 1>&2
    exit 3;
  fi

  if [[ -f "$CWD/jsonlite.data/$document_id" ]]; then
    rm -f "$CWD/jsonlite.data/$document_id"
  fi
}

jsonlite_drop() {
  if [[ -d "$CWD/jsonlite.data" ]]; then
    read -p "Are you sure you want to drop '$CWD/jsonlite.data' (y/n)? " confirm
    case "$confirm" in
      # Do we need to guard against potentially naughty things here?
      y|Y|yes|YES ) rm -rf "$CWD/jsonlite.data";;
      * ) exit 4;;
    esac
  fi
}

main() {
  COMMAND=$1
  case "$COMMAND" in
    "set")
      jsonlite_set "$2"
      ;;

    "get")
      jsonlite_get "$2"
      ;;

    "delete")
      jsonlite_delete "$2"
      ;;

    "drop")
      jsonlite_drop
      ;;

    "version")
      printf "%s" "$VERSION"
  esac
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
