//
//  Factory.swift
//  TaylorSource
//
//  Created by Daniel Thorpe on 28/03/2016.
//
//

import Foundation

/// Errors used by Factory classes
public enum FactoryError<CellIndex: IndexPathIndexType, SupplementaryIndex: IndexPathIndexType>: ErrorType, Equatable {
    case NoCellRegisteredAtIndex(CellIndex)
    case InvalidCellRegisteredAtIndexWithIdentifier(CellIndex, String)
}

public func == <CellIndex: IndexPathIndexType, SupplementaryIndex: IndexPathIndexType>(lhs: FactoryError<CellIndex, SupplementaryIndex>, rhs: FactoryError<CellIndex, SupplementaryIndex>) -> Bool {
    switch (lhs, rhs) {
    case let (.NoCellRegisteredAtIndex(lhsIndex), .NoCellRegisteredAtIndex(rhsIndex)):
        return lhsIndex == rhsIndex
    case let (.InvalidCellRegisteredAtIndexWithIdentifier(lhsIndex, lhsString), .InvalidCellRegisteredAtIndexWithIdentifier(rhsIndex, rhsString)):
        return lhsIndex == rhsIndex && lhsString == rhsString
    default:
        return false
    }
}

/**
 Factory. This is the most abstract concrete class which conforms to FactoryType.
 
 - see: FactoryType
*/
public class Factory<Item, Cell, SupplementaryView, View, CellIndex, SupplementaryIndex where View: CellBasedViewType, CellIndex: IndexPathIndexType, SupplementaryIndex: IndexPathIndexType>: FactoryType {

    public typealias ItemType = Item
    public typealias CellType = Cell
    public typealias SupplementaryViewType = SupplementaryView
    public typealias ViewType = View
    public typealias CellIndexType = CellIndex
    public typealias SupplementaryIndexType = SupplementaryIndex
    public typealias TextType = String

    public typealias Error = FactoryError<CellIndex, SupplementaryIndex>

    public typealias CellConfig = (cell: Cell, item: Item, index: CellIndex) -> Void
    public typealias SupplementaryViewConfig = (supplementaryView: SupplementaryView, index: SupplementaryIndex) -> Void
    public typealias SupplementaryTextConfig = (index: SupplementaryIndex) -> String?

    public typealias GetCellKey = (item: Item, index: CellIndex) -> String
    public typealias GetSupplementaryKey = (index: SupplementaryIndex) -> String

    internal typealias ReuseIdentifierType = String

    internal let getCellKey: GetCellKey?
    internal let getSupplementaryKey: GetSupplementaryKey?

    internal var cells = [String: (reuseIdentifier: ReuseIdentifierType, configure: CellConfig)]()
    internal var views = [SupplementaryElementIndex: (reuseIdentifier: ReuseIdentifierType, configure: SupplementaryViewConfig)]()
    internal var texts = [SupplementaryElementKind: SupplementaryTextConfig]()

    public init(cell: GetCellKey? = .None, supplementary: GetSupplementaryKey? = .None) {
        getCellKey = cell
        getSupplementaryKey = supplementary
    }
}

extension Factory: FactoryCellRegistrarType {

    public func registerCell(descriptor: ReusableViewDescriptor, inView view: View, withKey key: String, configuration: CellConfig) {
        descriptor.registerInView(view)
        cells[key] = (descriptor.identifier, configuration)
    }
}

extension Factory: FactorySupplementaryViewRegistrarType {

    public func registerSupplementaryView(descriptor: ReusableViewDescriptor, kind: SupplementaryElementKind, inView view: View, withKey key: String, configuration: SupplementaryViewConfig) {
        descriptor.registerInView(view, kind: kind)
        let index = SupplementaryElementIndex(kind: kind, key: key)
        views[index] = (descriptor.identifier, configuration)
    }
}

extension Factory: FactorySupplementaryTextRegistrarType {

    public func registerSupplementaryTextWithKind(kind: SupplementaryElementKind, configuration: SupplementaryTextConfig) {
        texts[kind] = configuration
    }
}

extension Factory: FactoryCellVendorType {

    public func cellForItem(item: Item, inView view: View, atIndex index: CellIndex) throws -> Cell {

        let key = getCellKey?(item: item, index: index) ?? defaultCellKey
        let indexPath = index.indexPath

        guard let (identifier, configure) = cells[key] else {
            throw Error.NoCellRegisteredAtIndex(index)
        }

        guard let cell = view.dequeueCellWithIdentifier(identifier, atIndexPath: indexPath) as? Cell else {
            throw Error.InvalidCellRegisteredAtIndexWithIdentifier(index, identifier)
        }

        configure(cell: cell, item: item, index: index)
        
        return cell
    }
}

/**
 A Basic factory which uses NSIndexPath for its cell and supplementary view indexes. But
 is otherwise as customizable as Factory.
 - see: Factory
 - see: FactoryType
*/
public class BasicFactory<Item, Cell, SupplementaryView, View where View: CellBasedViewType>: Factory<Item, Cell, SupplementaryView, View, NSIndexPath, NSIndexPath> {

    public override init(cell: GetCellKey? = .None, supplementary: GetSupplementaryKey? = .None) {
        super.init(cell: cell, supplementary: supplementary)
    }
}

