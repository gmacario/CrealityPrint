import QtQml 2.13

import QtQuick 2.10
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0

import Qt.labs.platform 1.1

import "../qml"

DockItem {
    id: root
    width: 1282 * screenScaleFactor
    height: 906 * screenScaleFactor
    title: qsTr("Model Library")

    // for library_groups_layout

    property var idGroupMap: {0:0}
    property var idGroupSearchMap: {0:0}
    readonly property bool isSearchMode: model_type_repeater.model === search_result_model

    property int currentModelLibraryPage: 1
    property int nextModelLibraryPage: 2

    property int currentModelSearchPage: 1
    property int nextModelSearchPage: 2

    // for library_models_layout

    property string currentGroupId: ""
    property string currentModelId: ""

    property var idImageMap: {0:0}
    property var idModelMap: {0:0}

    // to MainWindow

    signal requestLogin()
    signal requestToShowDownloadTip()

    // ---------- util ----------

    function countMapSize(map) {
        let count = 0
        for (let _ in map) {
            count++
        }
        return count
    }

    function clearMap(map) {
        for (let key in map) {
            map[key].destroy()
            delete map[key]
        }
    }

    function onSigLoginTip() {
        requestLogin()
    }

    function onSigDownloadedTip() {
        goto_download_center_tip.visible = true
    }

    // ---------- invoke by cpp ----------

    Connections {
        target: cxkernel_cxcloud.modelLibraryService

        onSearchModelGroupSuccessed: function(json_string, page_index) {
            setSearchGroupList(json_string, page_index)
        }

        onLoadModelGroupCategoryListSuccessed: function(json_string) {
            setModelTypeList(json_string)
        }

        onLoadRecommendModelGroupListSuccessed: function(json_string, page_index) {
            setRecommendGroupList(json_string, page_index)
        }

        onLoadTypeModelGroupListSuccessed: function(json_string, page_index) {
            setTypeGroupList(json_string, page_index)
        }

        onLoadHistoryModelGroupListSuccessed: function(json_string) {
            setHistoryGroupList(json_string)
        }

        onLoadModelGroupInfoSuccessed: function(json_string) {
            setGroupInfo(json_string)
        }

        onLoadModelGroupFileListInfoSuccessed: function(json_string) {
            setGroupDetail(json_string)
        }
    }

    function showModelLibraryDialog() {
        visible = true
        cxkernel_cxcloud.modelLibraryService.loadModelGroupCategoryList()
    }

    function setModelTypeList(strJson) {
        let json_root = JSON.parse(strJson)
        if (json_root.code !== 0) {
            return
        }

        model_type_model.reset()
        let json_object_list = json_root.result.list
        for (let json_object of json_object_list) {
            model_type_model.append({
                                        "modelId"  : json_object.id,
                                        "modelText": json_object.name
                                    })
        }
    }

    function setRecommendGroupList(strJson, page) {
        let componentGroupItem = Qt.createComponent("ModelLibraryItem.qml")
        if (componentGroupItem.status === Component.Ready) {
            let json_root = JSON.parse(strJson)
            if (json_root.code !== 0) {
                return
            }

            currentModelLibraryPage = page
            nextModelLibraryPage = json_root.result.nextCursor

            let object_list = json_root.result.list
            for (let object of object_list) {
                let model_item = componentGroupItem.createObject(group_list, {
                                                                     "width"           : group_list.itemWidth,
                                                                     "height"          : group_list.itemHeight,
                                                                     "groupId"         : object.model.id,
                                                                     "groupName"       : object.model.groupName,
                                                                     "groupImage"      : object.model.covers.length == 0 ? "" : object.model.covers[0].url,
                                                                     "authorName"      : object.model.userInfo.nickName,
                                                                     "authorHead"      : object.model.userInfo.avatar,
                                                                     "modelCount"      : object.model.modelCount,
                                                                     "totalPrice"      : object.model.totalPrice,
                                                                     "collected"       : object.model.isCollection,
                                                                     "createdTimestamp": object.model.createTime,
                                                                 })

                model_item.sigButtonDownClicked.connect(onGroupDownloadButtonClicked)
                model_item.sigButtonClicked.connect(onGroupButtonClicked)
                model_item.sigDownloadedTip.connect(onSigDownloadedTip)
                model_item.sigLoginTip.connect(onSigLoginTip)

                idGroupMap[object.model.id] = model_item
            }
        }
    }

    function setTypeGroupList(strJson, page) {
        let componentGroupItem = Qt.createComponent("ModelLibraryItem.qml")
        if (componentGroupItem.status === Component.Ready) {
            let json_root = JSON.parse(strJson)

            if (json_root.code !== 0) {
                return
            }

            currentModelLibraryPage = page
            nextModelLibraryPage = json_root.result.nextCursor

            let object_list = json_root.result.list
            for (let object of object_list) {
                let model_item = componentGroupItem.createObject(group_list, {
                                                                     "width"           : group_list.itemWidth,
                                                                     "height"          : group_list.itemHeight,
                                                                     "groupId"         : object.id,
                                                                     "groupName"       : object.groupName,
                                                                     "groupImage"      : object.covers.length == 0 ? "" : object.covers[0].url,
                                                                     "authorName"      : object.userInfo.nickName,
                                                                     "authorHead"      : object.userInfo.avatar,
                                                                     "modelCount"      : object.modelCount,
                                                                     "totalPrice"      : object.totalPrice,
                                                                     "collected"       : object.isCollection,
                                                                     "createdTimestamp": object.createTime,
                                                                 })

                model_item.sigButtonDownClicked.connect(onGroupDownloadButtonClicked)
                model_item.sigButtonClicked.connect(onGroupButtonClicked)
                model_item.sigDownloadedTip.connect(onSigDownloadedTip)
                model_item.sigLoginTip.connect(onSigLoginTip)

                idGroupMap[object.id] = model_item
            }
        }
    }

    function setSearchGroupList(strjson, page) {
        let componentGroupItem = Qt.createComponent("ModelLibraryItem.qml")
        if (componentGroupItem.status !== Component.Ready) {
            return
        }

        let json_root = JSON.parse(strjson)
        if (json_root.code !== 0) {
            return
        }

        if (page === 1) {
            clearMap(idGroupSearchMap)
        }

        currentModelSearchPage = page
        let object_list = json_root.result.list
        if (object_list.length >= 24) {
            nextModelSearchPage = currentModelSearchPage + 1
        }

        for (let object of object_list) {
            let model_item = componentGroupItem.createObject(group_search_list, {
                                                                 "width"           : group_search_list.itemWidth,
                                                                 "height"          : group_search_list.itemHeight,
                                                                 "groupId"         : object.id,
                                                                 "groupName"       : object.groupName,
                                                                 "groupImage"      : object.covers.length == 0 ? "" : object.covers[0].url,
                                                                 "authorName"      : object.userInfo.nickName,
                                                                 "authorHead"      : object.userInfo.avatar,
                                                                 "modelCount"      : object.modelCount,
                                                                 "totalPrice"      : object.totalPrice,
                                                                 "collected"       : object.isCollection,
                                                                 "createdTimestamp": object.createTime,
                                                             })

            model_item.sigButtonDownClicked.connect(onGroupDownloadButtonClicked)
            model_item.sigButtonClicked.connect(onGroupButtonClicked)
            model_item.sigDownloadedTip.connect(onSigDownloadedTip)
            model_item.sigLoginTip.connect(onSigLoginTip)

            idGroupSearchMap[object.id] = model_item
        }
    }

    function setHistoryGroupList(json_string) {
        let model_component = Qt.createComponent("ModelLibraryItem.qml")
        if (model_component.status !== Component.Ready) {
            return
        }

        //    clearMap(idGroupMap)
        //    if (deleteModelGroupComponentStatus) {
        //      deleteModelGroupComponentStatus = false
        //    }

        currentModelLibraryPage = 1
        nextModelLibraryPage = 2

        let json_root = JSON.parse(json_string)
        for (let group of json_root.group_list) {
            let model_item = model_component.createObject(group_list, {
                "width"           : group_list.itemWidth,
                "height"          : group_list.itemHeight,
                "groupId"         : group.id,
                "groupName"       : group.name,
                "groupImage"      : group.image,
                "totalPrice"      : group.price,
                "authorName"      : group.author_name,
                "authorHead"      : group.author_image,
                "modelCount"      : 0,
                "collected"       : false,
                "createdTimestamp": 0
            });

            model_item.sigButtonDownClicked.connect(onGroupDownloadButtonClicked)
            model_item.sigButtonClicked.connect(onGroupButtonClicked)
            model_item.sigDownloadedTip.connect(onSigDownloadedTip)
            model_item.sigLoginTip.connect(onSigLoginTip)

            idGroupMap[group.id] = model_item
        }
    }

    function setGroupInfo(json_string) {
        let json_root = JSON.parse(json_string)
        if (json_root.code === 0) {
            let group_info = json_root.result.groupItem

            switch (group_info.license) {
            case "CC BY":
                license_image.source = "qrc:/UI/photo/license_by.png"
                break
            case "CC BY-SA":
                license_image.source = "qrc:/UI/photo/license_by_sa.png"
                break
            case "CC BY-NC":
                license_image.source = "qrc:/UI/photo/license_by_nc.png"
                break
            case "CC BY-NC-SA":
                license_image.source = "qrc:/UI/photo/license_by_nc_sa.png"
                break
            case "CC BY-ND":
                license_image.source = "qrc:/UI/photo/license_by_nd.png"
                break
            case "CC0":
                license_image.source = "qrc:/UI/photo/license_cc0.png"
                break
            default:
                license_image.source = ""
                break
            }

            license_image.visible = license_image.source !== ""

            let id_group_map = isSearchMode ? idGroupSearchMap : idGroupMap
            id_group_map[currentGroupId].collected = group_info.isCollection
            collected_group_button.collected = group_info.isCollection
        }
    }

    function setGroupDetail(json_string) {
        let componentImageItem = Qt.createComponent("BasicImageButton.qml")
        let componentModelItem = Qt.createComponent("ModelLibraryDetailIem.qml")
        if (componentImageItem.status !== Component.Ready ||
                componentImageItem.status !== Component.Ready) {
            return
        }

        clearMap(idImageMap)
        clearMap(idModelMap)
        currentModelId = ""

        let json_root = JSON.parse(json_string)
        if (json_root.code === 0) {
            let model_info_list = json_root.result.list

            let is_first_model = true
            for (let model_info of model_info_list) {
                let group_id   = model_info.modelId
                let model_id   = model_info.id
                let model_name = model_info.fileName
                let model_size = model_info.fileSize
                let image_url  = model_info.coverUrl

                // init image button

                let image_item = componentImageItem.createObject(image_list, {
                                                                     "id"       : model_id,
                                                                     "keystr"   : model_id,
                                                                     "btnRadius": 10 * screenScaleFactor,
                                                                     "btnImgUrl": image_url
                                                                 })

                image_item.sigBtnClicked.connect(onModelButtonClicked)

                idImageMap[model_id] = image_item

                // init model button

                let model_item = componentModelItem.createObject(model_list, {
                                                                     "groupId"  : group_id,
                                                                     "modelName": model_name,
                                                                     "modelSize": model_size,
                                                                     "modelId"  : model_id,
                                                                 })

                model_item.sigBtnDetailClicked.connect(onModelButtonClicked)
                model_item.sigBtnDownLoadDetailModel.connect(onModelDownloadButtonClicked)
                model_item.sigDownloadedTip.connect(onSigDownloadedTip)
                model_item.sigLoginTip.connect(onSigLoginTip)

                idModelMap[model_id] = model_item

                if (is_first_model) {
                    currentModelId = model_id
                    is_first_model = false
                }
            }
        }
    }

    // ---------- call by self ----------

    function getPageModelList(type_id, page_index, page_size) {
        if (type_id === -2) {
            cxkernel_cxcloud.modelLibraryService.loadRecommendModelGroupList(page_index, page_size)
        } else if (type_id === -1) {
            cxkernel_cxcloud.modelLibraryService.loadHistoryModelGroupList(page_index, page_size)
        } else {
            cxkernel_cxcloud.modelLibraryService.loadTypeModelGroupList(type_id, page_index, page_size)
        }
    }

    // ---------- receive from sub qml item ----------

    function onServerChange(){
        model_type_model.currentTypelIdChanged()
    }

    function onModelButtonClicked(model_id) {
        currentModelId = model_id
    }

    function onModelDownloadButtonClicked(model_id) {
        let id_group_map = isSearchMode ? idGroupSearchMap : idGroupMap

        if (id_group_map[currentGroupId].totalPrice > 0) {
            Qt.openUrlExternally(cxkernel_cxcloud.modelGroupUrlHead + currentGroupId)
            return
        }

        currentModelId = model_id
        cxkernel_cxcloud.downloadService.startModelDownloadTask(currentGroupId, currentModelId)

        root.requestToShowDownloadTip()
        root.visible = false
    }

    function onGroupButtonClicked(group_id) {
        if (currentGroupId !== group_id) {
            currentGroupId = group_id
        } else {
            currentGroupIdChanged()
        }
    }

    function onGroupDownloadButtonClicked(group_id) {
        currentGroupId = group_id
        cxkernel_cxcloud.downloadService.startModelGroupDownloadTask(currentGroupId)

        root.requestToShowDownloadTip()
        root.visible = false
    }

    onCurrentModelIdChanged: {
        if (currentModelId === "") {
            clearMap(idModelMap)
            clearMap(idImageMap)
            return
        }

        for (let model_key in idModelMap) {
            let model_item = idModelMap[model_key]
            let selected = model_key === currentModelId
            model_item.btnIsSelected = selected

            if (selected) {
                let visiableSize = model_list_scroll.vSize
                let virtualHeight = model_list_scroll.height / visiableSize
                let itemPosition = model_item.y / virtualHeight
                let position = model_list_scroll.vPosition
                /* 当前所选项不在列表的显示范围时，把列表滑动到所选项位置 */
                if (itemPosition < position ||
                        itemPosition > position + visiableSize) {
                    model_list_scroll.vPosition = Math.min(1 - visiableSize, itemPosition)
                }
            }
        }

        current_model_image.source = ""

        for (let image_key in idImageMap) {
            let image_item = idImageMap[image_key]
            let selected = image_key === currentModelId
            image_item.btnSelect = selected

            if (selected) {
                current_model_image.source = image_item.btnImgUrl
            }
        }
    }

    function refreshData(){
        let curId = model_type_repeater.model.currentTypelId
        model_type_repeater.model.currentTypelId = model_type_repeater.model.currentTypeInvalidValue
        model_type_repeater.model.currentTypelId = curId
    }

    onCurrentGroupIdChanged: {
        let id_group_map = isSearchMode ? idGroupSearchMap : idGroupMap

        if (currentGroupId === "") {
            clearMap(id_group_map)
            currentModelId = ""
            return
        }

        let group_item = id_group_map[currentGroupId]
        if (!group_item) {
            return
        }

        let group_id          = group_item.groupId
        let group_name        = group_item.groupName
        let group_image       = group_item.groupImage
        let model_count       = group_item.modelCount
        let author_name       = group_item.authorName
        let author_head       = group_item.authorHead
        let total_price       = group_item.totalPrice
        let collected         = group_item.collected
        let created_timestamp = group_item.createdTimestamp * 1000

        group_name_label.text = group_name
        author_name_label.text = author_name
        author_head_image.img_src = author_head
        group_upload_time_label.text = "%1 : %2".arg(qsTr("UploadedTime"))
        .arg(Qt.formatDateTime(new Date(Number(created_timestamp)), "yyyy-MM-dd hh:mm"))

        share_group_dialog.setId(group_id)
        cxkernel_cxcloud.modelLibraryService.loadModelGroupInfo(group_id)
        cxkernel_cxcloud.modelLibraryService.loadModelGroupFileListInfo(group_id, model_count)

        library_groups_layout.visible = false
        library_models_layout.visible = true

        // write to history
        cxkernel_cxcloud.modelLibraryService.pushHistoryModelGroup(String(group_id),
                                                                   String(group_name),
                                                                   String(group_image),
                                                                   Number(total_price),
                                                                   String(author_name),
                                                                   String(author_head))
    }

    onWidthChanged: {
        group_list.syncSize()
        group_search_list.syncSize()
    }

    Component.onCompleted: {
        idGroupMap = {}
        idGroupSearchMap = {}
        idImageMap = {}
        idModelMap = {}

        cxkernel_cxcloud.modelLibraryService.loadModelGroupCategoryList()
        model_type_model.currentTypelIdChanged()
    }

    ColumnLayout {
        id: library_groups_layout

        anchors.fill: parent
        anchors.bottomMargin: 40 * screenScaleFactor
        anchors.topMargin: root.currentTitleHeight + 30 * screenScaleFactor
        anchors.leftMargin: 40 * screenScaleFactor
        anchors.rightMargin: anchors.leftMargin / 2 - group_view.verticalWidth / 2

        spacing: 0

        RowLayout {
            id: model_type_row

            Layout.fillWidth: true
            Layout.maximumHeight: more_model_type_button.checked ? model_type_flow.height
                                                                 : model_type_flow.buttonHeight
            Layout.minimumHeight: model_type_flow.buttonHeight

            Behavior on Layout.maximumHeight {
                NumberAnimation {
                    duration: 300
                }
            }

            clip: true

            spacing: 10 * screenScaleFactor

            Flow {
                id: model_type_flow

                Layout.fillWidth: true
                Layout.minimumHeight: buttonHeight

                spacing: 10 * screenScaleFactor

                readonly property int buttonHeight: 46 * screenScaleFactor

                ListModel {
                    id: model_type_model

                    property int currentTypelId: -2
                    property int currentTypeInvalidValue: -10//默认的不合法的值

                    ListElement {
                        modelId: -1
                        modelText: qsTr("History") //"historymodellist"
                        modelIcon: ""
                    }

                    ListElement {
                        modelId: -2
                        modelText: qsTr("Recommend") //"recommendmodellist"
                        modelIcon: ""
                    }

                    function reset() {
                        if (count > 2) {
                            remove(2, count - 2)
                        }
                    }

                    onCurrentTypelIdChanged: {
                        if(currentTypelId == currentTypeInvalidValue)
                            return;
                        clearMap(idGroupMap)

                        model_type_repeater.model = model_type_model
                        group_search_view.visible = false
                        group_view.visible = true
                        group_view.vPosition = 0

                        currentModelLibraryPage = 1
                        getPageModelList(currentTypelId, currentModelLibraryPage, 24)
                    }
                }

                ListModel {
                    id: search_result_model

                    property int currentTypelId: -3

                    ListElement {
                        modelId: -3
                        modelText: qsTr("Search Result")
                        modelIcon: ""
                    }
                }

                ButtonGroup {
                    id: model_type_group
                }

                Repeater {
                    id: model_type_repeater
                    model: model_type_model
                    delegate: Button {
                        width: model_type_text.contentWidth + 40 * screenScaleFactor
                        height: model_type_flow.buttonHeight

                        checkable: true

                        background: Rectangle {
                            anchors.fill: parent
                            radius: 5 * screenScaleFactor
                            color: parent.checked || parent.hovered ? Constants.model_library_type_button_checked_color
                                                                    : Constants.model_library_type_button_default_color
                        }

                        Text {
                            id: model_type_text

                            anchors.centerIn: parent
                            text: modelText
                            color: parent.checked || parent.hovered ? Constants.model_library_type_button_text_checked_color
                                                                    : Constants.model_library_type_button_text_default_color
                            font.pointSize: Constants.labelFontPointSize_10
                            font.family: Constants.labelFontFamilyBold
                            font.weight: Font.Black
                        }

                        onToggled: {
                            if (!toggled) {
                                return
                            }

                            model_type_repeater.model.currentTypelId = modelId
                        }

                        Component.onCompleted: {
                            model_type_group.addButton(this)
                            checked = modelId === model_type_repeater.model.currentTypelId
                        }
                    }
                }
            }

            Button {
                id: more_model_type_button

                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                Layout.minimumWidth: 36 * screenScaleFactor
                Layout.minimumHeight: Layout.minimumWidth

                enabled: model_type_repeater.model === model_type_model

                checked: true
                checkable: true

                background: Rectangle {
                    anchors.fill: parent

                    visible: parent.enabled

                    radius: width / 2
                    color: parent.hovered ? Constants.model_library_border_color : "transparent"

                    Image {
                        anchors.centerIn: parent
                        source: more_model_type_button.checked ? "qrc:/UI/photo/comboboxDown2_flip.png"
                                                               : "qrc:/UI/photo/comboboxDown2.png"
                        width: 12 * screenScaleFactor
                        height: 6 * screenScaleFactor
                    }
                }
            }

            Button {
                id: clear_search_button

                enabled: search_edit.text != ""

                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                Layout.minimumWidth: 36 * screenScaleFactor
                Layout.minimumHeight: Layout.minimumWidth

                background: Rectangle {
                    anchors.fill: parent

                    visible: parent.enabled

                    radius: width / 2
                    color: parent.hovered ? Constants.model_library_border_color : "transparent"

                    Image {
                        anchors.centerIn: parent

                        width: 18 * screenScaleFactor
                        height: 12 * screenScaleFactor

                        fillMode: Image.PreserveAspectFit

                        source: "qrc:/UI/photo/model_library_detail_back.png"
                    }
                }

                onPressed: {
                    search_edit.text = ""
                    model_type_repeater.model = model_type_model
                    group_view.visible = true
                    group_search_view.visible = false
                }
            }

            BasicLoginTextEdit {
                id: search_edit

                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                Layout.minimumWidth: 260 * screenScaleFactor
                Layout.minimumHeight: 36 * screenScaleFactor

                radius: Layout.minimumHeight / 2

                text: ""
                property string prevText: ""

                placeholderText: qsTr("Enter Model Name")
                font.family: Constants.labelFontFamily
                font.pointSize: Constants.labelFontPointSize_10
                imgPadding: 12 * screenScaleFactor
                headImageSrc: hovered ? Constants.searchBtnImg_d : Constants.searchBtnImg
                tailImageSrc: hovered
                              && search_edit.text != "" ? Constants.clearBtnImg : ""
                hoveredTailImageSrc: Constants.clearBtnImg_d

                onEditingFinished: {
                    if (search_edit.text == "") {
                        clear_search_button.onPressed()
                    } else {
                        search_button.sigButtonClicked()
                    }
                }

                onTailBtnClicked: {
                    search_edit.text = ""
                    search_button.sigButtonClicked()
                }
            }

            BasicButton {
                id: search_button

                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                Layout.minimumWidth: 66 * screenScaleFactor
                Layout.minimumHeight: 36 * screenScaleFactor

                enabled: search_edit.text != ""

                btnRadius: Layout.minimumHeight / 2
                btnBorderW: 1
                borderColor: hovered ? Constants.model_library_type_button_checked_color : Constants.model_library_border_color

                text: qsTr("Search")
                pointSize: Constants.labelFontPointSize_10
                btnTextColor: enabled ? hovered ? Constants.model_library_type_button_text_checked_color : Constants.model_library_type_button_text_default_color : Constants.model_library_border_color

                defaultBtnBgColor: Constants.model_library_type_button_default_color
                hoveredBtnBgColor: Constants.model_library_type_button_checked_color

                onSigButtonClicked: {
                    if (search_edit.text == "") {
                        clear_search_button.onPressed()
                        return
                    }

                    model_type_repeater.model = search_result_model
                    group_view.visible = false
                    group_search_view.visible = true

                    if (search_edit.text == search_edit.prevText) {
                        return
                    }

                    search_edit.prevText = search_edit.text
                    clearMap(idGroupSearchMap)
                    group_search_view.vPosition = 0
                    currentModelSearchPage = 1
                    cxkernel_cxcloud.modelLibraryService.searchModelGroup(search_edit.text, currentModelSearchPage, 24)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            property int topPadding: 20 * screenScaleFactor

            color: root.panelColor

            BasicScrollView {
                id: group_view
                visible: true
                anchors.fill: parent
                anchors.topMargin: parent.topPadding
                rightPadding: library_groups_layout.anchors.rightMargin
                clip: true

        Grid {
          id: group_list
          width: parent.width
          height: parent.height
          spacing: 5 * screenScaleFactor
          columns: 4

                    property int itemWidth: 286 * screenScaleFactor
                    property int itemHeight: 360 * screenScaleFactor

                    function syncSize() {
                        let total_width = group_view.width + spacing
                        let item_width = itemWidth + spacing
                        columns = Math.floor(total_width / item_width)
                    }
                }

                onVPositionChanged: {
                    if ((vSize + vPosition) === 1) {
                        if (currentModelLibraryPage != nextModelLibraryPage) {
                            if (nextModelLibraryPage != "" || nextModelLibraryPage != -1) {
                                getPageModelList(model_type_model.currentTypelId, nextModelLibraryPage, 24)
                            }
                        }
                    }
                }
            }

            BasicScrollView {
                id: group_search_view
                visible: false
                anchors.fill: parent
                anchors.topMargin: parent.topPadding
                rightPadding: library_groups_layout.anchors.rightMargin
                clip: true
                vpolicyVisible: group_search_list.height > 400 *2* screenScaleFactor
                Grid {
                    id: group_search_list
                    width: parent.width
                    height: parent.height
                    spacing: 10 * screenScaleFactor
                    columns: 4

                    property int itemWidth: 286 * screenScaleFactor
                    property int itemHeight: 360 * screenScaleFactor

                    function syncSize() {
                        let total_width = group_search_view.width + spacing
                        let item_width = itemWidth + spacing
                        columns = Math.floor(total_width / item_width)
                    }
                }

                onVPositionChanged: {
                    if ((vSize + vPosition) === 1) {
                        if (currentModelSearchPage != nextModelSearchPage) {
                            cxkernel_cxcloud.modelLibraryService.searchModelGroup(search_edit.text, nextModelSearchPage, 24)
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: library_models_layout

        anchors.fill: parent
        anchors.topMargin: root.currentTitleHeight + 10 * screenScaleFactor
        anchors.leftMargin: 20 * screenScaleFactor
        anchors.rightMargin: anchors.leftMargin
        anchors.bottomMargin: 30 * screenScaleFactor

        spacing: 10 * screenScaleFactor

        visible: false

        Button {
            id: back_button

            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.minimumWidth: 76 * screenScaleFactor
            Layout.minimumHeight: 28 * screenScaleFactor

            background: Rectangle {
                anchors.fill: parent

                radius: height / 2

                border.width: 1
                border.color: back_button.hovered ? Constants.model_library_back_button_border_checked_color
                                                  : Constants.model_library_back_button_border_default_color

                color: back_button.hovered ? Constants.model_library_back_button_checked_color
                                           : Constants.model_library_back_button_default_color

                RowLayout {
                    anchors.fill: parent
                    spacing: 5 * screenScaleFactor

                    Image {
                        Layout.alignment: Qt.AlignCenter
                        Layout.leftMargin: 20 * screenScaleFactor

                        sourceSize.width: 6 * screenScaleFactor
                        sourceSize.height: 10 * screenScaleFactor

                        source: back_button.hovered ? Constants.model_library_back_button_checked_image
                                                    : Constants.model_library_back_button_default_image
                    }

                    Text {
                        Layout.alignment: Qt.AlignCenter
                        Layout.rightMargin: 20 * screenScaleFactor

                        text: qsTr("Back")
                        font.family: Constants.labelFontFamily
                        font.pointSize: Constants.labelFontPointSize_9

                        color: back_button.hovered ? Constants.model_library_back_button_text_checked_color
                                                   : Constants.model_library_back_button_text_default_color
                    }
                }
            }

            onClicked: {
                library_models_layout.visible = false
                library_groups_layout.visible = true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillWidth: true
            Layout.minimumHeight: 500 * screenScaleFactor
            Layout.maximumHeight: Layout.minimumHeight

            spacing: 10 * screenScaleFactor

            Rectangle {
                Layout.minimumWidth: 442 * screenScaleFactor
                Layout.fillHeight: true

                border.width: 1
                border.color: Constants.model_library_border_color
                radius: 10 * screenScaleFactor
                color: "#FFFFFF"

                ColumnLayout {
                    anchors.fill: parent

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 400 * screenScaleFactor

                        color: "transparent"

                        Image {
                            id: current_model_image
                            anchors.fill: parent
                            mipmap: true
                            smooth: true
                            cache: false
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            source: ""
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.topMargin: 20 * screenScaleFactor
                            anchors.bottomMargin: anchors.topMargin
                            anchors.leftMargin: 10 * screenScaleFactor
                            anchors.rightMargin: anchors.leftMargin

                            spacing: 10 * screenScaleFactor

                            Button {
                                id: model_image_left_button

                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.minimumWidth: 30 * screenScaleFactor
                                Layout.minimumHeight: Layout.minimumWidth

                                //enabled: image_list_view.hPosition !== 0

                                background: Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: model_image_left_button.hovered ? "#E2F5FF" : "transparent"

                                    Image {
                                        anchors.centerIn: parent
                                        visible: model_image_left_button.enabled
                                        width: 6 * screenScaleFactor
                                        height: 10 * screenScaleFactor
                                        source: "qrc:/UI/photo/model_library_detail_left.png"
                                    }
                                }

                                onClicked: {
                                    let new_pos = image_list_view.hPosition - 1 / countMapSize(idImageMap)
                                    image_list_view.hPosition = Math.max(0, new_pos)

                                    // 查找上一个modelId
                                    let currentIndex
                                    var ids = Object.keys(idModelMap)
                                    for (var i = ids.length - 1; i >= 0; i--) {
                                        if (ids[i] === currentModelId)
                                            currentIndex = i
                                    }

                                    // 切换到上一个modelId
                                    let nextIndex = Math.max(0, currentIndex - 1);
                                    currentModelId = ids[nextIndex];

                                }
                            }

                            Rectangle {
                                id: image_list_rect
                                Layout.fillWidth: true
                                Layout.minimumHeight: 60 * screenScaleFactor

                                BasicScrollView {
                                    id: image_list_view
                                    anchors.fill: parent
                                    anchors.margins: 0
                                    wheelEnabled: false
                                    clip: true
                                    vpolicyVisible: false
                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    Row {
                                        id: image_list
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 0
                                        spacing: 10 * screenScaleFactor
                                    }
                                }
                            }

                            Button {
                                id: model_image_right_button

                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                Layout.minimumWidth: 30 * screenScaleFactor
                                Layout.minimumHeight: Layout.minimumWidth

                                //enabled: image_list_view.hPosition !== 1 - image_list_view.hSize

                                background: Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: model_image_right_button.hovered ? "#E2F5FF" : "transparent"

                                    Image {
                                        anchors.centerIn: parent
                                        visible: true
                                        width: 6 * screenScaleFactor
                                        height: 10 * screenScaleFactor
                                        source: "qrc:/UI/photo/model_library_detail_right.png"
                                    }
                                }

                                onClicked: {
                                    let new_pos = image_list_view.hPosition + 1 / countMapSize(idImageMap)
                                    image_list_view.hPosition = Math.min(1 - image_list_view.hSize, new_pos)

                                    // 查找下一个modelId
                                    let currentIndex
                                    var ids = Object.keys(idModelMap)
                                    for (var i = ids.length - 1; i >= 0; i--) {
                                        if (ids[i] === currentModelId)
                                            currentIndex = i
                                    }

                                    let nextIndex = Math.min(ids.length - 1, currentIndex + 1);
                                    currentModelId = ids[nextIndex];
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: 1
                border.color: Constants.model_library_border_color
                radius: 10 * screenScaleFactor
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 30 * screenScaleFactor
                    anchors.bottomMargin: anchors.topMargin
                    anchors.leftMargin: 20 * screenScaleFactor
                    anchors.rightMargin: anchors.leftMargin

                    StyledLabel {
                        id: group_name_label

                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.minimumHeight: 20 * screenScaleFactor

                        elide: Text.ElideRight

                        text: ""
                        color: Constants.model_library_special_text_color
                        font.weight: "Bold"
                        font.pointSize: Constants.labelFontPointSize_12
                    }

                    StyledLabel {
                        id: group_upload_time_label
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.minimumHeight: 20 * screenScaleFactor

                        text: ""
                        color: Constants.model_library_general_text_color
                        font.pointSize: Constants.labelFontPointSize_9
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.minimumHeight: 85 * screenScaleFactor

                        spacing: 8 * screenScaleFactor

                        BaseCircularImage {
                            id: author_head_image
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.minimumWidth: 60 * screenScaleFactor
                            Layout.minimumHeight: Layout.minimumWidth
                            img_src: ""
                        }

                        StyledLabel {
                            id: author_name_label

                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.fillWidth: true
                            Layout.minimumHeight: author_head_image.Layout.minimumHeight

                            verticalAlignment: Text.AlignVCenter

                            elide: Text.ElideRight

                            text: ""
                            color: Constants.model_library_special_text_color
                            font.pointSize: Constants.labelFontPointSize_12
                        }

                        GridLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                            columns: 2

                            columnSpacing: 10 * screenScaleFactor
                            rowSpacing: columnSpacing

                            BasicDialogButton {
                                id: download_group_button

                                Layout.alignment: Qt.AlignCenter
                                Layout.minimumWidth: 150 * screenScaleFactor
                                Layout.minimumHeight: 36 * screenScaleFactor

                                btnBorderW: 1
                                btnRadius: Layout.minimumHeight / 2
                                borderColor:Constants.model_library_action_button_border_checked_color

                                isAnimatedImage: false

                                imgWidth: 14 * screenScaleFactor
                                imgHeight: 14 * screenScaleFactor
                                iconImage.fillMode: Image.PreserveAspectFit
                                pressedIconSource:  Constants.model_library_download_checked_image
                                defaultBtnBgColor: Constants.model_library_action_button_checked_color
                                hoveredBtnBgColor: hovered ? "#1eb6e2" : Constants.model_library_action_button_checked_color

                                text: qsTr("DownLoad All")
                                btnTextColor: Constants.model_library_action_button_text_checked_color

                                onSigButtonClicked: {
                                    let group_id = currentGroupId
                                    let id_group_map = isSearchMode ? idGroupSearchMap : idGroupMap

                                    if (id_group_map[group_id].totalPrice > 0) {
                                        Qt.openUrlExternally(cxkernel_cxcloud.modelGroupUrlHead + group_id)
                                        return
                                    }

                                    if (!cxkernel_cxcloud.downloadService.checkModelGroupDownloadable(group_id)) {
                                        onSigDownloadedTip()
                                        return
                                    }

                                    if (!cxkernel_cxcloud.accountService.logined) {
                                        for (let model_id in root.idModelMap) {
                                            cxkernel_cxcloud.downloadService.makeModelDownloadPromise(group_id, model_id)
                                        }
                                        onSigLoginTip()
                                        return
                                    }

                                    cxkernel_cxcloud.downloadService.startModelGroupDownloadTask(group_id)

                                    root.requestToShowDownloadTip()
                                    root.visible = false
                                }
                            }

                            BasicDialogButton {
                                id: collected_group_button

                                Layout.alignment: Qt.AlignCenter
                                Layout.minimumWidth: 150 * screenScaleFactor
                                Layout.minimumHeight: 36 * screenScaleFactor

                                property bool collected: false

                                btnBorderW: 1
                                btnRadius: Layout.minimumHeight / 2
                                borderColor: hovered ? Constants.model_library_action_button_border_checked_color
                                                     : Constants.model_library_action_button_border_default_color

                                imgWidth: 14 * screenScaleFactor
                                imgHeight: 14 * screenScaleFactor
                                iconImage.fillMode: Image.PreserveAspectFit
                                pressedIconSource: collected ? "qrc:/UI/photo/model_library_collect.png"
                                                             : hovered   ? Constants.model_library_uncollect_checked_image
                                                                         : Constants.model_library_uncollect_default_image

                                defaultBtnBgColor: Constants.model_library_action_button_default_color
                                hoveredBtnBgColor: Constants.model_library_action_button_checked_color

                                text: qsTr("Collect")
                                btnTextColor: hovered ? Constants.model_library_action_button_text_checked_color
                                                      : Constants.model_library_action_button_text_default_color

                                onSigButtonClicked: {
                                    if (!cxkernel_cxcloud.accountService.logined) {
                                        onSigLoginTip()
                                        return
                                    }

                                    cxkernel_cxcloud.modelLibraryService.collectModelGroup(currentGroupId, !collected)
                                }
                            }

                            BasicDialogButton {
                                id: share_group_button

                                Layout.alignment: Qt.AlignCenter
                                Layout.minimumWidth: 150 * screenScaleFactor
                                Layout.minimumHeight: 36 * screenScaleFactor

                                btnBorderW: 1
                                btnRadius: Layout.minimumHeight / 2
                                borderColor: hovered ? Constants.model_library_action_button_border_checked_color
                                                     : Constants.model_library_action_button_border_default_color

                                imgWidth: 14 * screenScaleFactor
                                imgHeight: 14 * screenScaleFactor
                                iconImage.fillMode: Image.PreserveAspectFit
                                pressedIconSource: this.hovered ? Constants.model_library_shared_checked_image
                                                                : Constants.model_library_shared_default_image

                                defaultBtnBgColor: Constants.model_library_action_button_default_color
                                hoveredBtnBgColor: Constants.model_library_action_button_checked_color

                                text: qsTr("Share")
                                btnTextColor: hovered ? Constants.model_library_action_button_text_checked_color
                                                      : Constants.model_library_action_button_text_default_color

                                onSigButtonClicked: {
                                    share_group_dialog.trackTo(this)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        height: 20 * screenScaleFactor
                        color: "transparent"
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        height: 1
                        color: Constants.model_library_border_color
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        height: 20 * screenScaleFactor
                        color: "transparent"
                    }

                    StyledLabel {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.minimumHeight: 20 * screenScaleFactor
                        color: Constants.model_library_special_text_color
                        text: qsTr("Model List")
                        font.family: Constants.labelFontFamily
                        font.pointSize: Constants.labelFontPointSize_12
                    }

                    Rectangle {
                        id: model_list_rect
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        color: "transparent"

                        BasicScrollView {
                            id: model_list_scroll
                            anchors.fill: parent
                            anchors.rightMargin: -15 * screenScaleFactor
                            clip: true
                            vpolicyVisible: model_list.height > model_list_rect.height
                            background: Rectangle {
                                color: "transparent"
                            }

                            Column {
                                id: model_list
                                width: model_list_rect.width
                                spacing: 10 * screenScaleFactor
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: group_license_rect
            //      Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.minimumHeight: 100 * screenScaleFactor
            Layout.fillWidth: true
            //      Layout.fillHeight: false
            height: 123*screenScaleFactor
            border.width: 1
            border.color: Constants.model_library_border_color
            radius: 10 * screenScaleFactor
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20 * screenScaleFactor

                ColumnLayout {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 15 * screenScaleFactor

                    RowLayout {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10 * screenScaleFactor

                        StyledLabel {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.minimumHeight: 18 * screenScaleFactor

                            font.pointSize: Constants.labelFontPointSize_12

                            color: Constants.model_library_special_text_color
                            text: qsTr("Creative Commons License")
                        }

                        Button {
                            id: license_button
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                            Layout.minimumWidth: 18 * screenScaleFactor
                            Layout.minimumHeight: Layout.minimumWidth

                            background: Rectangle {
                                anchors.fill: parent
                                radius: license_button.Layout.minimumWidth / 2

                                color: license_button.hovered ? Constants.model_library_license_checked_color : Constants.model_library_license_default_color

                                Image {
                                    anchors.fill: parent
                                    anchors.centerIn: parent
                                    anchors.margins: 4 * screenScaleFactor

                                    fillMode: Image.PreserveAspectFit
                                    source: license_button.hovered ? Constants.model_library_license_checked_image : Constants.model_library_license_default_image
                                }
                            }

                            onClicked: {
                                license_dialog.visible = true
                            }
                        }
                    }

                    StyledLabel {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        font.pointSize: Constants.labelFontPointSize_9
                        color: Constants.model_library_general_text_color
                        text: qsTr("Please check the copyright information in the description.")
                    }
                }

                Image {
                    id: license_image

                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.minimumWidth: 172 * screenScaleFactor
                    Layout.minimumHeight: 60 * screenScaleFactor

                    mipmap: true
                    smooth: true
                    cache: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/UI/photo/license_by_nc.png"
                }
            }
        }
        Item{
            Layout.fillHeight: true
        }
    }

    LicenseDescriptionDlg {
        id: license_dialog
        visible: false
    }

    ModelLibraryShareDialog {
        id: share_group_dialog
        visible: false
    }

    UploadMessageDlg {
        id: goto_download_center_tip
        visible: false
        msgText: qsTr("The Model is in the download task list. Please check the download center.")
        cancelBtnVisible: false
        ignoreBtnVisible: false
        onSigOkButtonClicked: {
            root.requestToShowDownloadTip()
            this.visible = false
        }
    }
}
