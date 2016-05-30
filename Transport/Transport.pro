TEMPLATE = aux
TARGET = Transport

RESOURCES += Transport.qrc

QML_FILES += $$files(*.qml,true) \
             $$files(*.js,true)

CONF_FILES +=   Transport.apparmor \
                Transport.png \
                tram.svg \
                switch.svg \
                Transport.svg \
                error.svg

ICON_FILES +=   icons/bus.svg \
                icons/cableway.svg \
                icons/ship.svg \
                icons/metro.svg \
                icons/nbus.svg \
                icons/ntram.svg \
                icons/train.svg \
                icons/tram.svg \
                icons/trol.svg \
                icons/air.svg \
                icons/taxi.svg \
                icons/stop.svg \
                icons/map_stop.svg \
                icons/map_position.svg

AP_TEST_FILES += tests/autopilot/run \
                 $$files(tests/*.py,true)

OTHER_FILES += $${CONF_FILES} \
               $${ICON_FILES} \
               $${QML_FILES} \
               $${AP_TEST_FILES} \
               Transport.desktop

#specify where the qml/js files are installed to
qml_files.path = /Transport
qml_files.files += $${QML_FILES}

#specify where the config files are installed to
config_files.path = /Transport
config_files.files += $${CONF_FILES}

#specify where the icon files are installed to
icon_files.path = /Transport/icons
icon_files.files += $${ICON_FILES}

#install the desktop file, a translated version is automatically created in 
#the build directory
desktop_file.path = /Transport
desktop_file.files = $$OUT_PWD/Transport.desktop 
desktop_file.CONFIG += no_check_exist 

INSTALLS+=config_files icon_files qml_files desktop_file

DISTFILES += \
    tram.svg \
    switch.svg \
    error.svg \
    Transport.svg \
    icons/bus.svg \
    icons/cableway.svg \
    icons/ship.svg \
    icons/metro.svg \
    icons/nbus.svg \
    icons/ntram.svg \
    icons/train.svg \
    icons/tram.svg \
    icons/trol.svg \
    icons/air.svg \
    icons/taxi.svg \
    icons/stop.svg \
    icons/map_stop.svg \
    icons/map_position.svg
