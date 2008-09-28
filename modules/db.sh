require @pkg_db-${DB_VER}:null:db_compile

db::()
{
		export DB_OUTPUT="${TEMP}/db-output"
        cd ${TEMP}
        [ -e ${DB_OUTPUT} ] && rm -rf "${DB_OUTPUT}"
        mkdir -p ${DB_OUTPUT}
        cd ${DB_OUTPUT}
        genkernel_extract_package "db-${DB_VER}"

}

