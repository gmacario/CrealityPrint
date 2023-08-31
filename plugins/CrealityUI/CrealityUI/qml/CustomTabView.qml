import QtQml 2.13

import QtQuick 2.13
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5

import Qt.labs.platform 1.1

// @brief 自定义 TabView 组件
// 与 CustomTabViewItem 结合使用 @see CustomTabViewItem.qml
// 示例:
//   CustomTabView {
//     anchors.fill: parent
//     defaultItem: item_1
//     CustomTabViewItem {
//       id: item_1
//       title: "item 1"
//       Text {
//         anchors.centerIn: parent
//         text: parent.title
//       }
//     }
//     CustomTabViewItem {
//       title: "item 2"
//     }
//   }
// 注意:
//   1. 只接受 CustomTabViewItem 作为 child;
Item {
  // -------------------- interface [begin] --------------------

  // 法线:
  //   宽度
  property int borderWidth: 1
  //   弧度 (包括标题栏按钮和面板的角落弧度)
  property int borderRadius: 5 * screenScaleFactor
  //   颜色
  property color borderColor: Constants.custom_tabview_border_color

  // 标题栏:
  //   标题栏样式
  enum TitleStyle {
    BUTTON_LIST,
    COMBO_BOX
  }
  property int titleStyle: CustomTabView.TitleStyle.BUTTON_LIST
  //   标题栏高度 (按钮选中时与标题栏同高度)
  property int titleBarHeight: 24 * screenScaleFactor
  //   标题栏右侧空位
  property int titleBarRightMargin: 64 * screenScaleFactor

  // 标题栏按钮:
  //   按钮颜色 (未选中, 选中时与面板背景同色)
  property color buttonColor: Constants.custom_tabview_button_color
  //   鼠标悬浮于按钮时的颜色 (只在 COMBO_BOX 标题样式下生效)
  property color buttonHoveredColor: Constants.custom_tabview_combo_item_hovered_color
  //   按钮顶部空位 (未选中, 选中时顶部没空位) (只在 BUTTON_LIST 标题样式下生效)
  property int buttonTopMargin: 2 * screenScaleFactor
  //   文本字体
  property font buttonTextFont: Constants.custom_tabview_button_text_font
  //   选中时文本字体是否加粗 (只在 BUTTON_LIST 标题样式下生效)
  property bool isButtonTextBoldWhenChecked: true
  //   文本颜色 (未选中) (只在 BUTTON_LIST 标题样式下生效)
  property color buttonTextDefaultColor: Constants.custom_tabview_button_text_default_color
  //   文本颜色 (已选中)
  property color buttonTextCheckedColor: Constants.custom_tabview_button_text_checked_color

  // 面板:
  //   背景色
  property color panelColor: Constants.custom_tabview_panel_color
  //   默认面板 (不设置则首个 Item 为 defaultItem)
  property var defaultPanel: null
  //   当前面板
  readonly property var currentPanel: {
    switch (titleStyle) {
      case CustomTabView.TitleStyle.COMBO_BOX:
        return combobox_title.currentPanel
      case CustomTabView.TitleStyle.BUTTON_LIST:
      default:
        return button_list_title.currentPanel
    }
  }
  //   选中默认面板
  function selectDefaultPanel() {
    switch (titleStyle) {
      case CustomTabView.TitleStyle.COMBO_BOX:
        return combobox_title.selectDefaultPanel()
      case CustomTabView.TitleStyle.BUTTON_LIST:
      default:
        return button_list_title.selectDefaultPanel()
    }
  }

  // -------------------- interface [end] --------------------
  id: root

  property var title_item: {
    switch (root.titleStyle) {
      case CustomTabView.TitleStyle.COMBO_BOX:
        return combobox_title
      case CustomTabView.TitleStyle.BUTTON_LIST:
      default:
        return button_list_title
    }
  }

  function _initItem(item) {
    title_model.insert(0, { "modelItem": item, })
    item.x = Qt.binding(function () { return panel_canvas.x })
    item.y = Qt.binding(function () { return panel_canvas.y })
    item.width = Qt.binding(function () { return panel_canvas.width })
    item.height = Qt.binding(function () { return panel_canvas.height })
    item.visible = Qt.binding(function () { return root.currentPanel === item })
  }

  ListModel {
    id: title_model
    //  ListElement {  // @see function _initItem
    //    modelItem -> Item
    //  }
  }

  Canvas {
    id: panel_canvas

    anchors.top: root.title_item.bottom
    anchors.bottom: root.bottom
    anchors.left: root.left
    anchors.right: root.right
    anchors.topMargin: -root.borderWidth

    antialiasing: true

    onVisibleChanged: {
      if (!visible) {
        return
      }
      this.requestPaint()
    }

    onPaint: {
      let context = this.getContext("2d")
      context.lineWidth = root.borderWidth
      context.strokeStyle = root.borderColor
      context.fillStyle = root.panelColor

      context.clearRect(0, 0, width, height)
      context.beginPath()

      // 最后一个按钮的右下角处
      context.moveTo(width - root.titleBarRightMargin, 0)

      // 顶部边缘
      context.lineTo(width - root.borderRadius, 0)

      // 右上角
      context.arcTo(width, 0,
                    width, root.borderRadius,
                    root.borderRadius, root.borderRadius)

      // 右侧边缘
      context.lineTo(width, height - root.borderRadius)

      // 右下角
      context.arcTo(width, height,
                    width - root.borderRadius, height,
                    root.borderRadius, root.borderRadius)

      // 底部边缘
      context.lineTo(root.borderRadius, height)

      // 左下角
      context.arcTo(0, height,
                    0, height - root.borderRadius,
                    root.borderRadius, root.borderRadius)

      // 左侧边缘
      context.lineTo(0, 0)

      context.fill()
      context.stroke()
    }

    Connections {
      target: Constants
      onCurrentThemeChanged: panel_canvas.requestPaint()
    }
  }

  RowLayout {
    id: button_list_title

    property var currentPanel: {
      let current_button = title_button_group.checkedButton
      return current_button == null ? null : current_button.panelItem
    }

    function selectDefaultPanel() {
      if (root.defaultPanel === null) { return }
      title_button_group.checkedButton = root.defaultPanel._button
    }

    visible: root.titleStyle === CustomTabView.TitleStyle.BUTTON_LIST

    anchors.top: root.top
    anchors.left: root.left
    anchors.right: root.right
    anchors.rightMargin: root.titleBarRightMargin
    height: root.titleBarHeight

    spacing: 0

    ButtonGroup {
      id: title_button_group
    }

    Repeater {
      id: title_button_repeater

      model: title_model

      delegate: Button {
        id: title_button

        readonly property var panelItem: modelItem
        readonly property string buttonText: panelItem.title
        readonly property bool isDefaultButton: panelItem === root.defaultPanel

        implicitHeight: checked ? button_list_title.height
                                : button_list_title.height - root.buttonTopMargin
        Layout.alignment: Qt.AlignBottom
        Layout.fillWidth: true

        visible: panelItem.enabled
        checkable: true

        background: Item {
          Canvas {
            id: title_button_canvas
            anchors.fill: parent
            antialiasing: true

            Connections {
              target: title_button
              onCheckedChanged: title_button_canvas.requestPaint()
              onHoveredChanged: title_button_canvas.requestPaint()
            }

            Connections {
              target: Constants
              onCurrentThemeChanged: title_button_canvas.requestPaint()
            }

            onPaint: {
              let context = this.getContext("2d")
              context.lineWidth = root.borderWidth
              context.strokeStyle = root.borderColor
              context.fillStyle = title_button.checked || title_button.hovered ? root.panelColor
                                                                               : root.buttonColor

              context.clearRect(0, 0, width, height)
              context.beginPath()

              // 左下角处
              context.moveTo(0, height)

              // 左侧边缘
              context.lineTo(0, root.borderRadius)

              // 左上角
              context.arcTo(0, 0, root.borderRadius, 0, root.borderRadius,
                            root.borderRadius)

              // 顶部边缘
              context.lineTo(width - root.borderRadius, 0)

              // 右上角
              context.arcTo(width, 0, width, root.borderRadius,
                            root.borderRadius, root.borderRadius)

              // 右侧边缘
              context.lineTo(width, height)

              // 底部边缘
              if (title_button.checked) {
                context.moveTo(0, height)
              } else {
                context.lineTo(0, height)
              }

              context.fill()
              context.stroke()
            }
          }

          Text {
            anchors.centerIn: parent
            text: title_button.buttonText
            color: title_button.checked ? root.buttonTextCheckedColor : root.buttonTextDefaultColor
            font.family: root.buttonTextFont.family
            font.pointSize: root.buttonTextFont.pointSize
            font.weight: !root.isButtonTextBoldWhenChecked ? root.buttonTextFont.weight
                                                           : title_button.checked ? Font.Bold
                                                                                  : Font.Normal
          }
        }

        Component.onCompleted: {
          this.panelItem._button = this
          title_button_group.addButton(this)

          if (root.defaultPanel === null) {
            if (title_button_group.checkedButton == null) {
              title_button_group.checkedButton = this
              root.defaultPanel = this.panelItem
            }
          } else if (root.defaultPanel === this.panelItem) {
            title_button_group.checkedButton = this
          }
        }
      }
    }
  }

  ComboBox {
    id: combobox_title

    property var currentPanel: root.defaultPanel
    function selectDefaultPanel() {
      if (root.defaultPanel && root.defaultPanel._button) {
        root.defaultPanel._button.clicked()
      }
    }

    visible: root.titleStyle === CustomTabView.TitleStyle.COMBO_BOX

    anchors.top: root.top
    anchors.left: root.left
    anchors.right: root.right
    anchors.rightMargin: root.titleBarRightMargin
    height: root.titleBarHeight

    displayText: currentPanel ? currentPanel.title : ""

    background: Canvas {
      id: title_combobox_canvas
      antialiasing: true

      Connections {
        target: Constants
        onCurrentThemeChanged: title_combobox_canvas.requestPaint()
      }

      onPaint: {
        let context = this.getContext("2d")

        context.fillStyle = root.panelColor
        context.lineWidth = root.borderWidth
        context.strokeStyle = root.borderColor

        context.beginPath()
        // 左下角处
        context.moveTo(0, height)
        // 左侧边缘
        context.lineTo(0, root.borderRadius)
        // 左上角
        context.arcTo(0, 0,
                      root.borderRadius, 0,
                      root.borderRadius, root.borderRadius)
        // 顶部边缘
        context.lineTo(width - root.borderRadius, 0)
        // 右上角
        context.arcTo(width, 0,
                      width, root.borderRadius,
                      root.borderRadius, root.borderRadius)
        // 右侧边缘
        context.lineTo(width, height)
        // 底部边缘
        context.moveTo(0, height)
        context.closePath()

        context.fill()
        context.stroke()
      }
    }

    contentItem: Text {
      anchors.left: parent.left
      anchors.leftMargin: 10 * screenScaleFactor
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignLeft
      verticalAlignment: Text.AlignVCenter

      font: root.buttonTextFont
      color: root.buttonTextCheckedColor
      text: parent.displayText
    }

    indicator: Image {
      anchors.right: parent.right
      anchors.rightMargin: 10 * screenScaleFactor
      anchors.verticalCenter: parent.verticalCenter

      width: 7 * screenScaleFactor
      height: 5 * screenScaleFactor
      source: Constants.downBtnImg
      opacity: parent.hovered ? 1 : 0.5
    }

    popup: Popup {
      y: parent.height - root.borderWidth
      width: parent.width
      implicitHeight: contentItem.implicitHeight

      background: Canvas {
        id: combobox_popup_canvas
        antialiasing: true

        Connections {
          target: Constants
          onCurrentThemeChanged: combobox_popup_canvas.requestPaint()
        }

        onPaint: {
          let context = this.getContext("2d")

          context.fillStyle = root.buttonColor
          context.lineWidth = root.borderWidth
          context.strokeStyle = root.borderColor

          context.beginPath()
          context.moveTo(0, 0)
          // 顶部边缘
          context.lineTo(width, 0)
          // 右侧边缘
          context.lineTo(width, height - root.borderRadius)
          // 右下角
          context.arcTo(width, height,
                        width - root.borderRadius, height,
                        root.borderRadius, root.borderRadius)
          // 底部边缘
          context.lineTo(root.borderRadius, height)
          // 左下角
          context.arcTo(0, height,
                        0, height - root.borderRadius,
                        root.borderRadius, root.borderRadius)
          // 左侧边缘
          context.lineTo(0, 0)
          context.closePath()

          context.fill()
          context.stroke()
        }
      }

      contentItem: ListView {
        anchors.fill: parent
        anchors.topMargin: root.borderWidth
        anchors.bottomMargin: root.borderRadius + root.borderWidth
        anchors.leftMargin: root.borderWidth
        anchors.rightMargin: root.borderWidth

        clip: true
        implicitHeight: contentHeight + anchors.topMargin + anchors.bottomMargin
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem

        spacing: 0
        model: combobox_title.delegateModel
        currentIndex: combobox_title.highlightedIndex
      }
    }

    model: title_model

    delegate: ItemDelegate {
      id: item_delegate
      width: parent.width
      height: root.titleBarHeight

      readonly property var panelItem: modelItem
      readonly property bool isDefaultItem: panelItem === root.defaultPanel
      readonly property bool isCurrentItem: ListView.isCurrentItem

      onClicked: {
        combobox_title.currentPanel = panelItem
      }

      Component.onCompleted: {
        panelItem._button = this

        if (root.defaultPanel === null) {
          root.defaultPanel = panelItem
        }

        if (root.defaultPanel === panelItem) {
          clicked()
        }
      }

      background: Rectangle {
        color: parent.hovered ? root.buttonHoveredColor : root.buttonColor
        Text {
          anchors.left: parent.left
          anchors.leftMargin: 10 * screenScaleFactor
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignLeft
          verticalAlignment: Text.AlignVCenter

          font: root.buttonTextFont
          color: root.buttonTextCheckedColor
          text: item_delegate.panelItem.title
        }
      }
    }
  }
}
