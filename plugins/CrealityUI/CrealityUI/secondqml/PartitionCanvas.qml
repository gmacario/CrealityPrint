import QtQuick 2.13

import QtQml 2.13

import "./"
import "../qml"

Canvas {
  id: root

  enum Shape {
    NONE             ,
    SEGMENT          ,
    RAY              ,
    LINEAR           ,
    HORIZONTAL_LINEAR,
    VERTICAL_LINEAR  ,
    GRID             ,
    STAGGERED_GRID
  }

  property double scaleFactor: 1.0
  property bool reverseYAxis: true
  property bool drawHistoryShape: true
  property int currentShapeType: PartitionCanvas.Shape.NONE
  property double gridLikeShapeWidth: 200.0
  property double gridLikeShapeHeight: 100.0

  property int fps: 60
  property string cursorColor: "rgb(255, 28, 28)"
  property string unfinishedShapeColor: "rgb(63, 238, 28)"
  property string finishedShapeColor: "rgb(105, 62, 255)"

  signal newSegmentAdded()

  readonly property real cursorX: mouse.mouseX - 0.5
  readonly property real cursorY: mouse.mouseY - 0.5

  function clearShape() {
    _decideShapeStack = []
    _revokeShapeStack = []
    _currentShape = null
  }

  function makeSegmentList() {
    let segment_list = []

    let push_segment = (segment) => {
      if (!segment) {
        return
      }

      for (let point of segment) {
        if (reverseYAxis) {
          point.y = -point.y + height
        }

        if (scaleFactor !== 1) {
          point.x *= scaleFactor
          point.y *= scaleFactor
        }
      }

      segment_list.push(segment)
    }

    for (let shape of _decideShapeStack) {
      if (typeof shape.toSegment === "function") {
        push_segment(shape.toSegment())
        continue
      }

      if (typeof shape.toSegmentList === "function") {
        for (let segment of shape.toSegmentList()) {
          push_segment(segment)
        }
        continue
      }

      for (let segment of shape.toSegmentList()) {
        push_segment(segment)
      }
    }
    return segment_list
  }

  function makeLineFx(first_point, second_point) {
    if (first_point.x == second_point.x) {
      return () => { return null }
    }

    if (first_point.y == second_point.y) {
      return () => { return first_point.y }
    }

    return (x) => {
      let x1 = first_point.x
      let y1 = first_point.y
      let x2 = second_point.x
      let y2 = second_point.y
      return ((y2 - y1) * x - x1 * y2 + x2 * y1) / (x2 - x1)
    }
  }

  function makeLineFy(first_point, second_point) {
    if (first_point.y == second_point.y) {
      return (y) => { return null }
    }

    if (first_point.x == second_point.x) {
      return (y) => { return first_point.x }
    }

    return (y) => {
      let x1 = first_point.x
      let y1 = first_point.y
      let x2 = second_point.x
      let y2 = second_point.y
      return ((x2 - x1) * y + x1 * y2 - x2 * y1) / (y2 - y1)
    }
  }

  property var _decideShapeStack: []
  property var _revokeShapeStack: []
  property var _currentShape: null

  antialiasing: true

  onCurrentShapeTypeChanged: {
    _currentShape = null
  }

  Component.onCompleted: {
    getContext("2d")
  }

  onPaint: {
    context.clearRect(0, 0, width, height)

    if (root.drawHistoryShape) {
      for (let shape of _decideShapeStack) {
        shape.draw()
      }
    }

    if (_currentShape) {
      _currentShape.draw()
    }

    if (root.currentShapeType != PartitionCanvas.Shape.NONE) {
      drawCursor()
    }
  }

  function createSegmentShape() {
    return {
      vaild: false,
      type: PartitionCanvas.Shape.SEGMENT,

      points: [
        { vaild: false, x: -1, y: -1 },
        { vaild: false, x: -1, y: -1 },
      ],

      toSegment: function() {
        if (!this.vaild) { return null; }
        return [
          Qt.point(this.points[0].x, this.points[0].y),
          Qt.point(this.points[1].x, this.points[1].y),
        ]
      },

      draw: function() {
        if (this.points[0].vaild) {
          root.context.beginPath()
          root.context.moveTo(this.points[0].x, this.points[0].y)
          root.context.lineTo(this.points[1].x, this.points[1].y)
          root.context.closePath()
          root.context.strokeStyle = this.vaild ? root.finishedShapeColor
                                                : root.unfinishedShapeColor
          root.context.stroke()
        }
      },

      click: function(mouse) {
        if (mouse.button == Qt.LeftButton) {
          if (!this.points[0].vaild) {
            this.points[0].x = this.points[1].x = cursorX
            this.points[0].y = this.points[1].y = cursorY
            this.points[0].vaild = true
          } else if (!this.points[1].vaild) {
            this.points[1].vaild = true
          }
        } else if (mouse.button == Qt.RightButton) {
          this.points[0].vaild = false
          this.points[1].vaild = false
        }

        this.vaild = this.points[0].vaild && this.points[1].vaild
      },

      move: function(mouse) {
        if (!this.points[0].vaild || this.points[1].vaild) {
          return
        }

        this.points[1].x = cursorX
        this.points[1].y = cursorY
      },
    }
  }

  function createRayShape() {
    return {
      vaild: false,
      type: PartitionCanvas.Shape.RAY,

      points: [
        { vaild: false, x: -1, y: -1 },
        { vaild: false, x: -1, y: -1 },
      ],

      toSegment: function() {
        if (!this.vaild) { return null; }
        return [
          Qt.point(this.points[0].x, this.points[0].y),
          Qt.point(this.points[1].x, this.points[1].y),
        ]
      },

      draw: function() {
        if (this.points[0].vaild) {
          root.context.beginPath()
          root.context.moveTo(this.points[0].x, this.points[0].y)
          root.context.lineTo(this.points[1].x, this.points[1].y)
          root.context.closePath()
          root.context.strokeStyle = this.vaild ? root.finishedShapeColor
                                                : root.unfinishedShapeColor
          root.context.stroke()
        }
      },

      click: function(mouse) {
        if (mouse.button == Qt.LeftButton) {
          if (!this.points[0].vaild) {
            this.points[0].x = this.points[1].x = cursorX
            this.points[0].y = this.points[1].y = cursorY
            this.points[0].vaild = true
          } else if (!this.points[1].vaild) {
            this.points[1].vaild = true
          }
        } else if (mouse.button == Qt.RightButton) {
          this.points[0].vaild = false
          this.points[1].vaild = false
        }

        this.vaild = this.points[0].vaild && this.points[1].vaild
      },

      move: function(mouse) {
        if (!this.points[0].vaild || this.points[1].vaild) {
          return
        }

        this.points[1].x = cursorX
        this.points[1].y = cursorY

        const fy = makeLineFy(this.points[0], this.points[1])

        const top_point = { x: fy(0), y: 0 }
        if (top_point.x && 0 <= top_point.x && top_point.x <= root.width &&
            top_point.y <= this.points[1].y && this.points[1].y <= this.points[0].y) {
          this.points[1].x = top_point.x
          this.points[1].y = top_point.y
          return
        }

        const bottom_point = { x: fy(root.height), y: root.height }
        if (bottom_point.x && 0 <= bottom_point.x && bottom_point.x <= root.width &&
            this.points[0].y <= this.points[1].y && this.points[1].y <= bottom_point.y) {
          this.points[1].x = bottom_point.x
          this.points[1].y = bottom_point.y
          return
        }

        const fx = makeLineFx(this.points[0], this.points[1])

        const left_point = { x: 0, y: fx(0) }
        if (left_point.y && 0 <= left_point.y && left_point.y <= root.width &&
            left_point.x <= this.points[1].x && this.points[1].x <= this.points[0].x) {
          this.points[1].x = left_point.x
          this.points[1].y = left_point.y
          return
        }

        const right_point = { x: root.width, y: fx(root.width) }
        if (right_point.y && 0 <= right_point.y && right_point.y <= root.width &&
            this.points[0].x <= this.points[1].x && this.points[1].x <= right_point.x) {
          this.points[1].x = right_point.x
          this.points[1].y = right_point.y
          return
        }
      },
    }
  }

  function createLinearShape() {
    return {
      vaild: false,
      type: PartitionCanvas.Shape.LINEAR,

      points: [
        { vaild: false, x: -1, y: -1 },
        { vaild: false, x: -1, y: -1 },
        { vaild: false, x: -1, y: -1 },
      ],

      toSegment: function() {
        if (!this.vaild) { return null; }
        return [
          Qt.point(this.points[0].x, this.points[0].y),
          Qt.point(this.points[1].x, this.points[1].y),
        ]
      },

      draw: function() {
        if (this.points[2].vaild) {
          root.context.beginPath()
          root.context.moveTo(this.points[0].x, this.points[0].y)
          root.context.lineTo(this.points[1].x, this.points[1].y)
          root.context.closePath()
          root.context.strokeStyle = this.vaild ? root.finishedShapeColor
                                                : root.unfinishedShapeColor
          root.context.stroke()
        }
      },

      click: function(mouse) {
        if (mouse.button == Qt.LeftButton) {
          if (!this.points[2].vaild) {
            this.points[2].x = cursorX
            this.points[2].y = cursorY
            this.points[2].vaild = true
          } else if (!this.points[1].vaild || !this.points[0].vaild) {
            this.points[1].vaild = true
            this.points[0].vaild = true
          }
        } else if (mouse.button == Qt.RightButton) {
          this.points[2].vaild = false
          this.points[1].vaild = false
          this.points[0].vaild = false
        }

        this.vaild = this.points[0].vaild && this.points[1].vaild && this.points[2].vaild
      },

      move: function(mouse) {
        if (!this.points[2].vaild || this.points[1].vaild || this.points[0].vaild) {
          return
        }

        this.points[1].x = cursorX
        this.points[1].y = cursorY

        const fy = makeLineFy(this.points[2], this.points[1])
        const fx = makeLineFx(this.points[2], this.points[1])

        const top_point = { x: fy(0), y: 0 }
        const bottom_point = { x: fy(root.height), y: root.height }
        const left_point = { x: 0, y: fx(0) }
        const right_point = { x: root.width, y: fx(root.width) }

        if (top_point.x && 0 <= top_point.x && top_point.x <= root.width &&
            top_point.y <= this.points[1].y && this.points[1].y <= this.points[0].y) {
          this.points[1].x = top_point.x
          this.points[1].y = top_point.y
          this.points[0].x = bottom_point.x
          this.points[0].y = bottom_point.y
          return
        }

        if (bottom_point.x && 0 <= bottom_point.x && bottom_point.x <= root.width &&
            this.points[0].y <= this.points[1].y && this.points[1].y <= bottom_point.y) {
          this.points[1].x = bottom_point.x
          this.points[1].y = bottom_point.y
          this.points[0].x = top_point.x
          this.points[0].y = top_point.y
          return
        }

        if (left_point.y && 0 <= left_point.y && left_point.y <= root.width &&
            left_point.x <= this.points[1].x && this.points[1].x <= this.points[0].x) {
          this.points[1].x = left_point.x
          this.points[1].y = left_point.y
          this.points[0].x = right_point.x
          this.points[0].y = right_point.y
          return
        }

        if (right_point.y && 0 <= right_point.y && right_point.y <= root.width &&
            this.points[0].x <= this.points[1].x && this.points[1].x <= right_point.x) {
          this.points[1].x = right_point.x
          this.points[1].y = right_point.y
          this.points[0].x = left_point.x
          this.points[0].y = left_point.y
          return
        }
      },
    }
  }

  function createHorizontalLinearShape() {
    let shape = createLinearShape()

    shape.type = PartitionCanvas.Shape.HORIZONTAL_LINEAR
    shape.move = function(mouse) {
      if (!this.points[2].vaild || this.points[1].vaild || this.points[0].vaild) {
        return
      }

      this.points[0].x = 0
      this.points[0].y = cursorY
      this.points[1].x = root.width
      this.points[1].y = cursorY
      this.points[2].x = cursorX
      this.points[2].y = cursorY
    }

    return shape
  }

  function createVerticalLinearShape() {
    let shape = createLinearShape()

    shape.type = PartitionCanvas.Shape.VERTICAL_LINEAR
    shape.move = function(mouse) {
      if (!this.points[2].vaild || this.points[1].vaild || this.points[0].vaild) {
        return
      }

      this.points[0].x = cursorX
      this.points[0].y = 0
      this.points[1].x = cursorX
      this.points[1].y = root.height
      this.points[2].x = cursorX
      this.points[2].y = cursorY
    }

    return shape
  }

  function createGridShape() {
    return {
      vaild: false,
      type: PartitionCanvas.Shape.GRID,

      width: 200,
      height: 100,
      segments: [],

      update: function() {
        this.segments = []
        let make_segment = (x1, y1, x2, y2) => {
          let segment = root.createSegmentShape()
          segment.points[0].vaild = true
          segment.points[0].x = x1
          segment.points[0].y = y1
          segment.points[1].vaild = true
          segment.points[1].x = x2
          segment.points[1].y = y2
          return segment
        }

        let origin_rect = {
          x: root.cursorX - this.width / 2,
          y: root.cursorY - this.height / 2,
          w: this.width,
          h: this.height,
        }

        // 横线
        for (let y = origin_rect.y; y < root.height; y += this.height) {
          this.segments.push(make_segment(0, y, root.width, y))
        }

        for (let y = origin_rect.y - this.height; y > 0; y -= this.height) {
          this.segments.push(make_segment(0, y, root.width, y))
        }

        // 竖线
        for (let x = origin_rect.x; x < root.width; x += this.width) {
          this.segments.push(make_segment(x, 0, x, root.height))
        }

        for (let x = origin_rect.x - this.width; x > 0; x -= this.width) {
          this.segments.push(make_segment(x, 0, x, root.height))
        }
      },

      toSegmentList: function() {
        let segment_list = []
        for (let segment of this.segments) {
          segment_list.push(segment.toSegment())
        }
        return segment_list
      },

      draw: function() {
        for (let segment of this.segments) {
          segment.draw()
        }
      },

      move: function(mouse) {
        if (!this.vaild) {
          this.width = root.gridLikeShapeWidth / root.scaleFactor
          this.height = root.gridLikeShapeHeight / root.scaleFactor
          this.update()
        }
      },

      click: function(mouse) {
        if (mouse.button == Qt.RightButton) {
          root._currentShape = null
          this.segments.length = []
          this.vaild = false
        }

        if (this.vaild || this.segments.length === 0) {
          return
        }

        for (let index = 0; index < this.segments.length; ++index) {
          this.segments[index].vaild = true
        }

        this.vaild = true
      },
    }
  }

  function createStaggeredGridShape() {
    return {
      vaild: false,
      type: PartitionCanvas.Shape.STAGGERED_GRID,

      width: 200,
      height: 100,
      segments: [],

      update: function() {
        this.segments = []
        let make_segment = (x1, y1, x2, y2) => {
          let segment = root.createSegmentShape()
          segment.points[0].vaild = true
          segment.points[0].x = x1
          segment.points[0].y = y1
          segment.points[1].vaild = true
          segment.points[1].x = x2
          segment.points[1].y = y2
          return segment
        }

        let origin_rect = {
          x: root.cursorX - this.width / 2,
          y: root.cursorY - this.height / 2,
          w: this.width,
          h: this.height,
        }

        let offset_rect = {
          x: root.cursorX,
          y: root.cursorY + this.height / 2,
          w: this.width,
          h: this.height,
        }

        let y_list = []
        const first_row_origin = (Math.ceil(origin_rect.y / origin_rect.h) + 1) % 2 !== 0

        // 横线
        for (let y = origin_rect.y; y < root.height; y += this.height) {
          this.segments.push(make_segment(0, y, root.width, y))

          // 竖线
          const current_rows = Math.ceil(y / origin_rect.h) + 1
          const current_origin = first_row_origin ? current_rows % 2 !== 0 : current_rows % 2 === 0
          const current_x = current_origin ? origin_rect.x : offset_rect.x;
          for (let x = current_x; x < root.width; x += this.width) {
            this.segments.push(make_segment(x, y, x, y + offset_rect.h))
          }
          for (let x = current_x - this.width; x > 0; x -= this.width) {
            this.segments.push(make_segment(x, y, x, y + offset_rect.h))
          }
        }

        for (let y = origin_rect.y - this.height; y > -this.height; y -= this.height) {
          this.segments.push(make_segment(0, y, root.width, y))

          // 竖线
          const current_rows = Math.ceil(y / origin_rect.h) + 1
          const current_origin = first_row_origin ? current_rows % 2 !== 0 : current_rows % 2 === 0
          const current_x = current_origin ? origin_rect.x : offset_rect.x;
          for (let x = current_x; x < root.width; x += this.width) {
            this.segments.push(make_segment(x, y, x, y + offset_rect.h))
          }
          for (let x = current_x - this.width; x > 0; x -= this.width) {
            this.segments.push(make_segment(x, y, x, y + offset_rect.h))
          }
        }
      },

      toSegmentList: function() {
        let segment_list = []
        for (let segment of this.segments) {
          segment_list.push(segment.toSegment())
        }
        return segment_list
      },

      draw: function() {
        for (let segment of this.segments) {
          segment.draw()
        }
      },

      move: function(mouse) {
        if (!this.vaild) {
          this.width = root.gridLikeShapeWidth / root.scaleFactor
          this.height = root.gridLikeShapeHeight / root.scaleFactor
          this.update()
        }
      },

      click: function(mouse) {
        if (mouse.button == Qt.RightButton) {
          root._currentShape = null
          this.segments.length = []
          this.vaild = false
        }

        if (this.vaild || this.segments.length === 0) {
          return
        }

        for (let index = 0; index < this.segments.length; ++index) {
          this.segments[index].vaild = true
        }

        this.vaild = true
      },
    }
  }

  function drawCursor() {
    context.beginPath()
    context.arc(cursorX, cursorY, 7.5, 0, Math.PI * 2, false)
    context.moveTo(cursorX - 10, cursorY)
    context.lineTo(cursorX + 10, cursorY)
    context.moveTo(cursorX, cursorY - 10)
    context.lineTo(cursorX, cursorY + 10)
    context.closePath()

    context.strokeStyle = root.cursorColor
    context.stroke()
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    enabled: root.currentShapeType != PartitionCanvas.Shape.NONE

    hoverEnabled: enabled
    cursorShape: enabled ? Qt.BlankCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: function(mouse) {
      if (!root._currentShape) {
        switch (root.currentShapeType) {
          case PartitionCanvas.Shape.NONE:
            root._currentShape = null
            break
          case PartitionCanvas.Shape.SEGMENT:
            root._currentShape = root.createSegmentShape()
            break
          case PartitionCanvas.Shape.RAY:
            root._currentShape = root.createRayShape()
            break
          case PartitionCanvas.Shape.LINEAR:
            root._currentShape = root.createLinearShape()
            break
          case PartitionCanvas.Shape.HORIZONTAL_LINEAR:
            root._currentShape = root.createHorizontalLinearShape()
            break
          case PartitionCanvas.Shape.VERTICAL_LINEAR:
            root._currentShape = root.createVerticalLinearShape()
            break
          case PartitionCanvas.Shape.GRID:
            root._currentShape = root.createGridShape()
            break
          case PartitionCanvas.Shape.STAGGERED_GRID:
            root._currentShape = root.createStaggeredGridShape()
            break
          default:
            break
        }
      }

      if (!root._currentShape) {
        return
      }

      // root._revokeShapeStack = []

      root._currentShape.click(mouse)

      if (!root._currentShape) {
        return
      }

      if (root._currentShape.vaild) {
        root._decideShapeStack.push(root._currentShape)
        root._currentShape = null
        root.newSegmentAdded()
      }
    }

    onPositionChanged: function(mouse) {
      if (!root._currentShape) {
        return
      }

      root._currentShape.move(mouse)
    }
  }

  // Shortcut {
  //   sequence: StandardKey.Undo
  //   onActivated: {
  //     if (root._decideShapeStack.length > 0) {
  //       root._revokeShapeStack.push(root._decideShapeStack.pop())
  //     }
  //   }
  // }

  // Shortcut {
  //   sequence: StandardKey.Redo
  //   onActivated: {
  //     if (root._revokeShapeStack.length > 0) {
  //       root._decideShapeStack.push(root._revokeShapeStack.pop())
  //     }
  //   }
  // }

  Timer {
    repeat: true
    running: root.visible
    interval: 1000 / root.fps
    onTriggered: root.requestPaint()
  }
}
