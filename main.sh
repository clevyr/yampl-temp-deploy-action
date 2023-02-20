#!/bin/bash
# Set up some variables so we can reference the GitHub Action context
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TAGS=( $TAGS "$@" )
TAGS+=( $(env | grep '^YAMPL_.*' | cut -d= -f1 | cut -d_ -f2- ))
SOPSFILES=()
YAMPLARGS=()

 # Detect secrets and decrypt
echo "Finding secrets and decrypting..."
IFS=$'\n'
YAMLFILES=($(find $TEMPLATEPATH -type f -name "*.yaml"))
unset IFS
for file in "${YAMLFILES[@]}"; do
    if [[ $(yq '. | has ("sops")' $file) == "true" ]]; then
    echo "$file is a sops secret"
    SOPSFILES+=($file)
    fi
done
for file in "${SOPSFILES[@]}"; do
    sops -d -i $file
done

# Do the YAMPL 
for tag in "${TAGS[@]}"; do
        a="YAMPL_$tag"
        case ${!a} in
            RAND*)
                length=$(echo "${!a}" | sed 's/RAND//')
                YAMPLARGS+=("-v $tag=$(openssl rand -base64 32 | tr -d /=+ | cut -c -$length)")
                ;;
            COLORANIMAL)
                friendlyName=$(shuf -n 1 "$__dir/colors.txt")-$(shuf -n 1 "$__dir/animals.txt")
                YAMPLARGS+=("-v $tag=$friendlyName")
                ;;
            *)
                YAMPLARGS+=("-v $tag=${!a}")
                ;;
        esac
done
yampl -i ${YAMPLARGS[@]} $TEMPLATEPATH/*.yaml $TEMPLATEPATH/*/*.yaml

# Replace secret namespace seperatly since SOPS breaks the in-line comments used by YAMPL
for file in "${SOPSFILES[@]}"; do
    yq e -i ".metadata.namespace = \"$YAMPL_namespace\"" $file
done

# Re-encrypt secrets
for file in "${SOPSFILES[@]}"; do
    sops -e -i $file
done