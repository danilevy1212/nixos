use_nvm()
{
    local version
    version="${1}"

    [[ "${version}" == --auto ]] && version="$(read_version_file .node-version .nvmrc)"
    [[ -z "${version}" ]] && return

    if [[ -e "${NVM_DIR}" ]]; then
        source "${NVM_DIR}"
        nvm use "${version}"
    fi
}
