/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the Qt Quick Controls 2 module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL3$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPLv3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or later as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file. Please review the following information to
** ensure the GNU General Public License version 2.0 requirements will be
** met: http://www.gnu.org/licenses/gpl-2.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12

import "../qml"

ScrollView {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    property int verticalWidth: 10
    property int horizontalHeight: 10

    property bool hpolicyVisible: false
    property alias hpolicyindicator: idHScroll.contentItem

    property bool bgVisible: false
    property bool vpolicyVisible: true
    property alias vpolicyindicator: idVScroll.contentItem

    property alias hSize: idHScroll.size
    property alias vSize: idVScroll.size
    property alias hPosition: idHScroll.position
    property alias vPosition: idVScroll.position
    property alias hPolicy: idHScroll.policy
    property alias vPolicy: idVScroll.policy
    hoverEnabled: true

    function setVScrollBarPosition(value){
        idVScroll.position = value
    }

    ScrollBar.vertical: ScrollBar {
        id: idVScroll
        parent: control
        x: control.mirrored ? 0 : control.width - width
        y: control.topPadding
        visible: vpolicyVisible
        width: verticalWidth
        height: control.availableHeight
        active: control.ScrollBar.horizontal.active
        policy: ScrollBar.AlwaysOn
    }

    ScrollBar.horizontal: ScrollBar {
        id: idHScroll
        parent: control
        x: control.leftPadding
        y: control.height - height
        visible: hpolicyVisible
        width: control.availableWidth
        height: horizontalHeight
        active: control.ScrollBar.vertical.active
        policy: ScrollBar.AlwaysOn
    }

    background: Rectangle
    {
        visible: bgVisible
        color: Constants.itemBackgroundColor
        border.width:1
        border.color:hovered ? Constants.textRectBgHoveredColor : Constants.dialogItemRectBgBorderColor
    }
}
