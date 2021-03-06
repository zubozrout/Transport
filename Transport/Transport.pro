TEMPLATE = aux
TARGET = Transport

RESOURCES += Transport.qrc

QML_FILES += $$files(*.qml) \
             $$files(*.js)

QML_PAGES_FILES += $$files(pages/*.qml)

QML_COMPONENTS_FILES += $$files(components/*.qml)

JS_FILES += $$files(transport-api/*.js)

ICON_FILES += $$files(icons/*.svg)
IMAGE_FILES += $$files(images/*.svg)

CONF_FILES +=  Transport.apparmor \
               Transport.png \
               Transport.svg

AP_TEST_FILES += tests/autopilot/run \
                 $$files(tests/*.py,true)

OTHER_FILES += $${CONF_FILES} \
               $${QML_FILES} \
               $${AP_TEST_FILES}

#specify where the qml/js files are installed to
qml_files.path = /Transport
qml_files.files += $${QML_FILES}

#specify where the qml files are installed to
qml_pages_files.path = /Transport/pages
qml_pages_files.files += $${QML_PAGES_FILES}

#specify where the qml files are installed to
qml_components_files.path = /Transport/components
qml_components_files.files += $${QML_COMPONENTS_FILES}

#specify where the js files are installed to
qml_js_files.path = /Transport/transport-api
qml_js_files.files += $${JS_FILES}

#specify where the icon files are installed to
qml_icon_files.path = /Transport/icons
qml_icon_files.files += $${ICON_FILES}

#specify where the image files are installed to
qml_image_files.path = /Transport/images
qml_image_files.files += $${IMAGE_FILES}

#specify where the config files are installed to
config_files.path = /Transport
config_files.files += $${CONF_FILES}

#install the desktop file, a translated version is automatically created in 
#the build directory
desktop_file.path = /Transport
desktop_file.files = $$OUT_PWD/Transport.desktop
desktop_file.CONFIG += no_check_exist 

INSTALLS+=config_files qml_files desktop_file qml_pages_files qml_components_files qml_js_files qml_icon_files qml_image_files

DISTFILES += \
    Transport.desktop \
    pages/ConnectionDetail.page \
    pages/ConnectionDetailPage.qml \
    components/ConnectionDetailDelegate.qml \
    components/ConnectionDetailRoutesDelegate.qml \
    components/ErrorMessage.qml \
    components/RecentBottomEdge.qml \
    components/CallbackTimer.qml \
    components/OverlayDetail.qml \
    pages/AboutPage.qml \
    components/CustomDataList.qml \
    pages/SettingsPage.qml \
    components/RowPicker.qml \
    components/RectangleButton.qml

