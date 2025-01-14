PYTHON_DIR="/var/packages/python3/target/bin"
PATH="${SYNOPKG_PKGDEST}/bin:${SYNOPKG_PKGDEST}/env/bin:${PYTHON_DIR}:${PATH}"
VIRTUALENV="${PYTHON_DIR}/python3 -m venv"
PYTHON="${SYNOPKG_PKGDEST=}/env/bin/python"
LANGUAGE="env LANG=en_US.UTF-8"
SALT_MINION="${SYNOPKG_PKGDEST}/env/bin/salt-minion"
PID_FILE="${SYNOPKG_PKGVAR}/run/salt-minion.pid"

SERVICE_COMMAND="${SALT_MINION} -c ${SYNOPKG_PKGVAR} -d"

service_postinst ()
{
    # Create a Python virtualenv
    ${VIRTUALENV} --system-site-packages ${SYNOPKG_PKGDEST}/env

    # Install wheels
    wheelhouse=${SYNOPKG_PKGDEST}/share/wheelhouse
    ${SYNOPKG_PKGDEST}/env/bin/pip install --no-deps --force-reinstall --no-index --find-links ${wheelhouse} ${wheelhouse}/*.whl

    # Patch rsax931.py file to find libcrypto lib
    # (Rely on patch util bundled with python3's busybox)
    ${PYTHON_DIR}/bin/patch ${SYNOPKG_PKGDEST}/env/lib/python3.7/site-packages/salt/utils/rsax931.py < ${SYNOPKG_PKGDEST}/share/rsax931.py.patch

    # Prepare salt-minion config in /var/salt
    install -m 755 -d ${SYNOPKG_PKGVAR}
    install -m 755 -d ${SYNOPKG_PKGVAR}/minion.d
    install -m 644 ${SYNOPKG_PKGDEST}/share/minion.conf ${SYNOPKG_PKGVAR}
    echo "pidfile: ${PID_FILE}" > ${SYNOPKG_PKGVAR}/minion.d/02_pidfile.conf
    # Populate salt master address and minion_id only if file don't already exist
    test -f ${SYNOPKG_PKGVAR}/minion.d/99-master-address.conf || echo "master: salt" > ${SYNOPKG_PKGVAR}/minion.d/99-master-address.conf
    test -f ${SYNOPKG_PKGVAR}/minion.d/98-minion-id.conf || echo "id: myname" > ${SYNOPKG_PKGVAR}/minion.d/98-minion-id.conf
}

