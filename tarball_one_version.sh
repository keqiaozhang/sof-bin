#!/bin/sh

set -e

usage()
{
    cat <<EOF
1. Creates a complete git archive from HEAD
2. Removes all but the selected version from it
3. Moves that selected version one level up, to the top-level in the archive

Sample usage:
        $0 v1.7.x/v1.7
EOF
    exit 1
}

main()
{
    [ "$#" -eq 1 ] || usage


    local path; path=$(dirname "$1")
    local ver; ver=$(basename "$1")
    local archive_name=sof-bin-"$ver"

    local gittop; gittop="$(git rev-parse --show-toplevel)"
    cd "${gittop}"

    if test -e "$archive_name"; then
        die "%s already exists\n" "$archive_name"
    fi

    set -x
    # Start with a clean git archive
    git archive -o _.tar --prefix="$archive_name"/ HEAD
    tar xf _.tar; rm _.tar

    # Save the selected version
    rm -rf _selected_version;   mkdir _selected_version
    mv "$archive_name"/"$path"/*"$ver"  _selected_version/

    # Delete all other versions
    rm -r "${archive_name:?}"/v[0-9].*

    # Exclude the copy of ourselves (we depend on git) any obsolete
    # scripts or other irrelevant stuff
    ( cd "${archive_name:?}"
      rm "$(basename "$0")"
      rm -f README-before-1.7.md go.sh publish.sh
      rm -f HOWTO-new-release.md
    )

    # Restore the selected version
    mv _selected_version/* "$archive_name"/
    rmdir _selected_version

    ( set +x
      if find "${archive_name}"/ -xtype l | grep -q . ; then
          find "${archive_name}"/ -xtype l -exec file {} \;
          die "Found some broken symbolic links\n"
      fi
    )

    tar cfz "$archive_name".tar.gz "$archive_name"/
    rm -r "${archive_name:?}"/
}


die()
{
    >&2 printf '%s ERROR: ' "$0"
    # We want die() to be usable exactly like printf
    # shellcheck disable=SC2059
    >&2 printf "$@"
    exit 1
}

main "$@"
