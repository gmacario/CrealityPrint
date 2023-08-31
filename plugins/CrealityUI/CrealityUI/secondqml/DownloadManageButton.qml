import QtQml 2.13

import QtQuick 2.10
import QtQuick.Controls 2.0

import "../qml"
import "./"

Button {
  id: root

  property int downloadTaskCount: 0
  property int finishedTaskCount: 10

  readonly property bool isDownloading: downloadTaskCount > 0
  onIsDownloadingChanged: {
    if (this.isDownloading) {
      showTip()
    }
  }

  function showTip() {
    tip_animation.start()
  }

  background: Rectangle {
    id: round

    anchors.fill: parent

    radius: height / 2
    border.color: root.isDownloading ? root.hovered ? Constants.downloadbtn_download_border_hovered_color
                                                    : Constants.downloadbtn_download_border_default_color
                                     : root.hovered ? Constants.downloadbtn_finished_border_hovered_color
                                                    : Constants.downloadbtn_finished_border_default_color
    border.width: 2 * screenScaleFactor

    color: root.isDownloading ? root.hovered ? Constants.downloadbtn_download_hovered_color
                                             : Constants.downloadbtn_download_default_color
                              : root.hovered ? Constants.downloadbtn_finished_hovered_color
                                             : Constants.downloadbtn_finished_default_color

    Canvas {
      id: wave

      anchors.fill: parent
      anchors.margins: parent.border.width
      visible: root.isDownloading

      // 数值范围
      property real maxValue: 100
      property real minValue: 0
      property real curValue: 50

      // 进度
      property real curProgress: (curValue - minValue) / (maxValue - minValue) * 100

      // 画布
      property int canvasWidth: width < height ? width : height
      property int canvasMargin: 0
      property int waveRadius: canvasWidth / 2 - canvasMargin //水球半径

      property color waveFontColor: "#78C3ED" // 前波浪颜色
      property color waveBackColor: "#D2EBF9" // 后波浪颜色

      // 波浪参数
      property real waveWidth: 0.1    // 波浪宽度, 数越小越宽
      property real waveHeight: 3     // 波浪高度, 数越大越高
      property real speed: 0.1        // 波浪速度, 数越大速度越快
      property real offset: 0         // 波浪 x 偏移量, 用于动画

      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, canvasWidth, canvasWidth)
        ctx.save()

        // 截取波浪圆形区域进行绘制
        ctx.lineWidth = 0
        ctx.beginPath()
        ctx.arc(canvasWidth / 2, canvasWidth / 2, waveRadius, 0, 2 * Math.PI)
        ctx.closePath()
        ctx.clip()

        // 画波浪, 可以导出波浪个数属性
        drawWave(ctx, waveBackColor, 1.5, -1, true)
        drawWave(ctx, waveFontColor, 0, 0, false)

        ctx.restore()
      }

      // 画笔， 颜色， x偏移， y偏移，角度值取反
      function drawWave(ctx, w_color, x_offset, y_offset, reverse = false) {
        //sin曲线
        ctx.beginPath()
        var x_base = canvasWidth / 2 - waveRadius
        var y_base = canvasWidth / 2 + waveRadius - waveRadius * 2 * (curProgress / 100)

        //波浪曲线部分，横坐标步进为5px
        for (var x_value = 0; x_value <= waveRadius * 2 + 5; x_value += 5) {
            var y_value = waveHeight * Math.sin((reverse ? -1 : 1)
                                     * (x_value) * waveWidth + offset + x_offset) + y_offset
            ctx.lineTo(x_base + x_value, y_base + y_value)
        }

        //底部两端围成实心
        ctx.lineTo(canvasWidth / 2 + waveRadius, canvasWidth / 2 + waveRadius)
        ctx.lineTo(canvasWidth / 2 - waveRadius, canvasWidth / 2 + waveRadius)
        ctx.closePath()
        ctx.fillStyle = w_color
        ctx.fill()
      }

      Timer {
        running: wave.visible
        repeat: true
        interval: 50
        onTriggered:{
          //波浪移动
          wave.offset += wave.speed;
          wave.offset %= Math.PI * 2;
          wave.requestPaint();
        }
      }
    }
  }

  contentItem: Item {
    anchors.centerIn: parent

    Text {
      anchors.centerIn: parent

      visible: root.isDownloading

      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter

      font.pointSize: Constants.labelFontPointSize_12
      font.family: Constants.labelFontFamilyBold
      font.weight: Font.Black

      color: root.isDownloading ? root.hovered ? Constants.downloadbtn_download_text_hovered_color
                                               : Constants.downloadbtn_download_text_default_color
                                : root.hovered ? Constants.downloadbtn_finished_text_hovered_color
                                               : Constants.downloadbtn_finished_text_default_color
      text: root.downloadTaskCount
    }

    Image {
      anchors.centerIn: parent

      visible: !root.isDownloading

      width: 12 * screenScaleFactor
      height: 16 * screenScaleFactor

      source: !root.hovered ? Constants.downloadbtn_image : Constants.downloadbtn_image_hovered
    }
  }

  Rectangle {
    id: tip_rect

    property int topMargin: 50 * screenScaleFactor

    anchors.top: root.bottom
    anchors.topMargin: this.topMargin
    anchors.horizontalCenter: root.horizontalCenter

    width: 60 * screenScaleFactor
    height: 60 * screenScaleFactor

    radius: height / 2
    color: Constants.downloadbtn_tip_color
    opacity: 0

    Image {
      anchors.centerIn: parent

      width: 20 * screenScaleFactor
      height: 26 * screenScaleFactor

      source: Constants.downloadbtn_tip_image
    }

    SequentialAnimation {
      id: tip_animation

      loops: 2

      NumberAnimation {
        target: tip_rect
        property: "opacity"
        to: 100
        duration: 300
      }

      NumberAnimation {
        target: tip_rect
        property: "topMargin"
        from: 60 * screenScaleFactor
        to: 10 * screenScaleFactor
        duration: 300
      }

      NumberAnimation {
        target: tip_rect
        property: "opacity"
        to: 0
        duration: 300
      }

      NumberAnimation {
        target: tip_rect
        property: "topMargin"
        from: 10 * screenScaleFactor
        to: 60 * screenScaleFactor
        duration: 300
      }
    }
  }
}
