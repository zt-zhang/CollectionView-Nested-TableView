//
//  ViewController.swift
//  Demo
//
//  Created by zhangtian on 2020/12/7.
//

import UIKit
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height

class ViewController: UIViewController {
    lazy var layout: UICollectionViewFlowLayout = {
        let ly = UICollectionViewFlowLayout()
        ly.estimatedItemSize = CGSize(width: SCREEN_WIDTH, height: 10)
        return ly
    }()
    lazy var collectionView: UICollectionView = {
        let co = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        co.backgroundColor = .init(white: 0.8, alpha: 1)
        co.register(TDTableViewCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(TDListModel.self))
        co.register(TDCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(TDModel.self))
        return co
    }()
    let viewModel = TDViewModel()
    let disposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appendUI()
        layoutUI()
        handler()
    }
    func appendUI() {
        self.view.addSubview(collectionView)
    }
    func layoutUI() {
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    func handler() {
        self.viewModel.data.bind(to: self.collectionView.rx.items) { co, row, item in
            let ip = IndexPath(row: row, section: 0)
            let cell = co.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(type(of: item)), for: ip) as! TDBaseCollectionViewCell<Any>
            cell.setView(item)
            return cell
        }.disposed(by: disposeBag)
        self.viewModel.updates?.subscribe(onNext: {[weak self] _ in
            //self?.collectionView.performBatchUpdates(nil)
            self?.collectionView.reloadData()
        }).disposed(by: disposeBag)
        
        self.collectionView.rx.itemSelected.subscribe(onNext: {[weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
    }
    deinit {
        print(self)
    }
}

extension ViewController: UITableViewDelegate {
    
}

class TDModel: NSObject {
    var title: String?
    init(_ title: String?) {
        self.title = title
        super.init()
    }
}
class TDListModel: NSObject {
    var data: [TDModel]?
    var updates = PublishRelay<Void?>()
    init(_ data: [TDModel]?) {
        self.data = data
        super.init()
    }
}

class TDViewModel {
    var data = BehaviorRelay<[NSObject]>(value: [])
    var updates: Observable<Void?>?
    
    init() {loadData()}
    
    func loadData() {
        var data: [NSObject] = [Int](0..<5).map{TDModel("Collection View Cell: \($0) 行")}
        let tbData = [Int](0..<10).map{TDModel("Table View Cell: \($0) 行")}
        let listModel = TDListModel(tbData)
        data.append(listModel)
        
        self.updates = listModel.updates.asObservable()
        self.data.accept(data)
    }
}

class TDBaseCollectionViewCell<T>: UICollectionViewCell {
    var disposeBag = DisposeBag()
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    override init(frame: CGRect) {
        super.init(frame: frame)
        styleConfig()
        appendUI()
        layoutUI()
    }
    func styleConfig(){}
    func appendUI(){}
    func layoutUI(){}
    func setView(_ data: T?) {}
}

class TDTableViewCollectionViewCell: TDBaseCollectionViewCell<Any> {
    override func styleConfig() {
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true
    }
    override func appendUI() {
        self.contentView.addSubview(tableView)
    }
    override func layoutUI() {
        tableView.snp.makeConstraints { (make) in
            make.left.top.equalTo(10)
            make.right.bottom.equalTo(-10).priority(999)
            make.width.equalTo(SCREEN_WIDTH - 30)
            make.height.equalTo(50)
        }
    }
    override func setView(_ data: Any?) {
        guard let model = data as? TDListModel else { return }
        if self.superview == nil {
            DispatchQueue.main.async {
                self.tableViewReloadData(model)
            }
        }else {
            self.tableViewReloadData(model)
        }
    }
    func tableViewReloadData(_ model: TDListModel) {
        guard let data = model.data else { return }
        let observable = Observable.of(data)
        
        observable.bind(to: self.tableView.rx.items) { tb, ip, item in
            let cell = tb.dequeueReusableCell(withIdentifier: "cell") as! TDTableViewCell
            cell.setView(item)
            return cell
        }.disposed(by: disposeBag)
        self.tableView.rx.didEndDisplayingCell.subscribe(onNext: {[weak self] rs in
            guard let `self` = self else {return}
            //let height = self.tableView.contentSize.height
            let height: CGFloat = CGFloat(data.count * 65)
            if self.tableView.frame.size.height == height {return}
            self.tableView.snp.updateConstraints { (make) in
                make.height.equalTo(height)
            }
            model.updates.accept(nil)
        }).disposed(by: disposeBag)
    }
    
    lazy var tableView: UITableView = {
        let tb = UITableView()
        tb.showsVerticalScrollIndicator = false
        tb.isScrollEnabled = false
        tb.separatorStyle = .none
        tb.register(TDTableViewCell.self, forCellReuseIdentifier: "cell")
        return tb
    }()
}

class TDTableViewCell: UITableViewCell {
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        styleConfig()
        appendUI()
        layoutUI()
    }
    func styleConfig() {
        self.selectionStyle = .none
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true
    }
    func appendUI() {
        self.contentView.addSubview(bgView)
        self.contentView.addSubview(titleLabel)
    }
    func layoutUI() {
        bgView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            make.height.equalTo(45).priority(999)
            
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(bgView).offset(20)
            make.centerY.equalTo(bgView)
        }
    }
    func setView(_ data: Any?) {
        guard let data = data as? TDModel else { return }
        self.titleLabel.text = data.title
    }
    
    lazy var bgView: UIView = {
        let v = UIView()
        v.backgroundColor = .init(white: 0.95, alpha: 1)
        return v
    }()
    let titleLabel = UILabel()
}

class TDCollectionViewCell: TDBaseCollectionViewCell<Any> {
    override func styleConfig() {
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true
    }
    override func appendUI() {
        self.contentView.addSubview(bgView)
        self.contentView.addSubview(titleLabel)
    }
    override func layoutUI() {
        bgView.snp.makeConstraints { (make) in
            make.left.top.equalTo(10)
            make.right.bottom.equalTo(-10).priority(999)
            make.width.equalTo(SCREEN_WIDTH - 30)
            make.height.equalTo(50)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(bgView).offset(20)
            make.centerY.equalTo(bgView)
        }
    }
    override func setView(_ data: Any?) {
        guard let data = data as? TDModel else { return }
        self.titleLabel.text = data.title
    }
    
    lazy var bgView: UIView = {
        let v = UIView()
        v.backgroundColor = .init(white: 0.95, alpha: 1)
        return v
    }()
    let titleLabel = UILabel()
}


