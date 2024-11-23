/*
 * Copyright 2023 Evgeny Chesnokov <echesnokov@astralinux.ru>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

import org.kde.kirigamiaddons.tableview as Tables
import "."

Tables.AbstractTable {
    id: root

    contentWidth: header.contentWidth
    contentHeight: header.contentHeight + tableView.contentHeight
    selectionBehavior: TableView.SelectCells

    signal cellClicked(int row, int column)
    signal cellDoubleClicked(int row, int column)

    __rowCount: tableView.rows
    property Component  delegate: QQC2.ItemDelegate {
        id: delegate
        Accessible.role: Accessible.Cell
        highlighted: selected

        required property int row
        required property var index
        required property int column
        required property bool current
        required property bool selected
        required property var model

        readonly property Tables.AbstractHeaderComponent headerComponent: __columnModel.get(column).headerComponent

        // Find the quantity value from the model
        readonly property var quantityValue: {
            // Find the header component for quantity column
            for (let i = 0; i < __columnModel.count; i++) {
                let header = __columnModel.get(i).headerComponent
                if (header.textRole === "quantity") {
                    return delegate.model[header.textRole]
                }
            }
            return null
        }
        // Find the quantity value from the model
        readonly property var minStockLevelValue: {
            // Find the header component for quantity column
            for (let i = 0; i < __columnModel.count; i++) {
                let header = __columnModel.get(i).headerComponent
                if (header.textRole === "minStockLevel") {
                    return delegate.model[header.textRole]
                }
            }
            return null
        }
        background: Rectangle {
            color: {
                if (delegate.selected) {
                    return Kirigami.Theme.highlightColor
                }

                // Check if quantity is less than threshold
                if (quantityValue !== null && parseInt(quantityValue) <= parseInt(minStockLevelValue) ) {
                    return Qt.alpha(Kirigami.Theme.neutralTextColor, 0.5) // 50% opacity
                }

                // Alternating rows
                return delegate.row % 2 ? Kirigami.Theme.alternateBackgroundColor : Kirigami.Theme.backgroundColor
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: delegate.current
            color: "transparent"
            border.color: Kirigami.Theme.highlightColor
        }
        contentItem: RowLayout {
            // Only add this for the first column (checkbox column)
            Loader {
                active: column === 0  // Only active for first column
                sourceComponent: QQC2.CheckBox {
                    Layout.preferredWidth: 50
                    checked: model.checked
                    onCheckedChanged: {
                         productModel.setChecked(row, checked)
                    }
                }
            }

            // For other columns, use the existing Loader
            Loader {
                active: column > 0  // Only active for columns after first
                sourceComponent: delegate.headerComponent.itemDelegate
                readonly property var modelData: model.display ?? delegate.model[delegate.headerComponent.textRole]
                readonly property var index: delegate.index
                readonly property int row: delegate.row
                readonly property int column: delegate.column
                readonly property var model: delegate.model
            }
        }

        // contentItem: Loader {
        //     sourceComponent: delegate.headerComponent.itemDelegate
        //     readonly property var modelData: model.display ?? delegate.model[delegate.headerComponent.textRole]
        //     readonly property var index: delegate.index
        //     readonly property int row: delegate.row
        //     readonly property int column: delegate.column
        //     readonly property var model: delegate.model
        // }

        onClicked: root.cellClicked(row, column)
        onDoubleClicked: root.cellDoubleClicked(row, column)
    }
    QQC2.HorizontalHeaderView {
        id: header

        width: tableView.width
        height: root.__rowHeight

        model: root.__columnModel
        syncView: tableView
        interactive: false

        rowHeightProvider: () => root.__rowHeight

        delegate: Tables.HeaderDelegate {
            sortEnabled: headerComponent.role === root.sortRole
            sortOrder: root.sortOrder
            onClicked: root.columnClicked(column, headerComponent)
            onDoubleClicked: root.columnDoubleClicked(column, headerComponent)
        }
    }

    TableView {
        id: tableView

        anchors.fill: parent
        anchors.topMargin: header.height
        model: root.model
        interactive: false

        alternatingRows: root.alternatingRows
        selectionModel: root.selectionModel
        selectionMode: root.selectionMode
        selectionBehavior: root.selectionBehavior

        resizableColumns: false
        resizableRows: false

        rowHeightProvider: () => root.__rowHeight
        columnWidthProvider: function(column) {
            if (!isColumnLoaded(index)) {
                return;
            }

            return root.__columnWidth(column, explicitColumnWidth(column))
        }

        delegate: root.delegate
    }

    QQC2.SelectionRectangle {
        target: tableView
        topLeftHandle: null
        bottomRightHandle: null
    }

    // TableView controls selection behavior only when user interact with table using keyboard and holding shift key
    onCellClicked: function(row, column) {
        if (root.selectionBehavior === TableView.SelectCells) {
            __selectCell(row, column);
        }

        if (root.selectionBehavior === TableView.SelectRows) {
            if (__isControlModifier || __isShiftModifier) {
                __selectRow(row);
                return
            }

            root.selectionModel.clearSelection();
            root.selectionModel.clearCurrentIndex();
            for (let _column = 0; _column < root.columnCount; _column++) {
                root.selectionModel.setCurrentIndex(root.model.index(row, _column), ItemSelectionModel.Select);
            }
        }

        if (root.selectionBehavior === TableView.SelectColumns) {
            if (__isControlModifier || __isShiftModifier) {
                __selectColumn(column);
                return;
            }

            root.selectionModel.clearSelection();
            root.selectionModel.clearCurrentIndex();
            for (let _row = 0; _row < root.rowCount; _row++) {
                root.selectionModel.setCurrentIndex(root.model.index(_row, column), ItemSelectionModel.Select);
            }
        }
    }
}
