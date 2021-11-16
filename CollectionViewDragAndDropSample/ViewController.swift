//
//  ViewController.swift
//  CollectionViewDragAndDropSample
//
//  Created by Fumitaka Imamura on 2021/11/13.
//

import UIKit

enum Model {
    case simple(text: String)
    case availableToDropAtEnd
}

class ViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    private var data = [["0A", "0B", "0C", "0D", "0E"],["1A", "2B"],["2A", "2C", "3C"]]
        .map { $0.map { return Model.simple(text: $0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
        let cellSize = view.bounds.width / 3 - 20
        layout.itemSize = CGSize(width: cellSize, height: cellSize)
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 50)
        collectionView.collectionViewLayout = layout

        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        data.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data[section].count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! CollectionReusableView
        header.label.text = "Section\(indexPath.section)"
        return header
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        switch data[indexPath.section][indexPath.item] {
        case Model.simple(text: let text):
            cell.label.text = text
            cell.backgroundColor = .green
        case Model.availableToDropAtEnd:
            cell.label.text = "仮"
            cell.backgroundColor = .lightGray
        }
        return cell
    }
}

extension ViewController: UICollectionViewDragDelegate {
    // drag中のアニメーション
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let itemProvider = NSItemProvider(object: "\(indexPath)" as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = data[indexPath.section][indexPath.item]
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        var itemsToInsert = [IndexPath]()
        (0 ..< data.count).forEach {
            itemsToInsert.append(IndexPath(item: data[$0].count, section: $0))
            data[$0].append(.availableToDropAtEnd)
        }
        collectionView.insertItems(at: itemsToInsert)
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        var removeItems = [IndexPath]()
        for section in 0 ..< data.count {
            for item in 0 ..< data[section].count {
                switch data[section][item] {
                case .availableToDropAtEnd:
                    removeItems.append(IndexPath(item: item, section: section))
                case .simple:
                    break
                }
            }
        }
        removeItems.forEach { indexPath in
            data[indexPath.section].remove(at: indexPath.item)
        }
        collectionView.deleteItems(at: removeItems)
    }
}

extension ViewController: UICollectionViewDropDelegate {
    // Dropしたときの動作
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        if let destinationIndexPath = coordinator.destinationIndexPath {
            reorderItems(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        }
    }

    // Drop中の動作
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }

    private func reorderItems(coordinator: UICollectionViewDropCoordinator,
                              destinationIndexPath: IndexPath,
                              collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1,
           let item = items.first,
           let sourceIndexPath = item.sourceIndexPath,
           let localObject = item.dragItem.localObject as? Model {
            collectionView.performBatchUpdates({
                data[sourceIndexPath.section].remove(at: sourceIndexPath.item)
                data[destinationIndexPath.section].insert(localObject, at: destinationIndexPath.item)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            })
        }
    }
}

