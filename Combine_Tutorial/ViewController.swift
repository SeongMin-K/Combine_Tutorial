//
//  ViewController.swift
//  Combine_Tutorial
//
//  Created by SeongMinK on 2021/10/12.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.tintColor = .black
        searchController.searchBar.searchTextField.accessibilityIdentifier = "mySearchBarTextField"
        return searchController
    }()

    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordConfirmTextField: UITextField!
    @IBOutlet weak var myBtn: UIButton!
    
    var viewModel: MyViewModel!
    
    private var mySubscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(#fileID, #function, "called")
        
        self.navigationItem.searchController = searchController
        searchController.isActive = true
        
        searchController.searchBar.searchTextField
            .myDebounceSearchPublisher
            .sink { [weak self] (receivedValue) in
                guard let self = self else { return }
                
                print("receivedValue: \(receivedValue)")
                self.myLabel.text = receivedValue
            }.store(in: &mySubscriptions)
        
        viewModel = MyViewModel()
        
        // 텍스트필드에서 나가는 이벤트를 뷰모델의 프로퍼티가 구독
        passwordTextField
            .myTextPublisher
            .print()
            // 스레드 - 메인에서 받음
            .receive(on: DispatchQueue.main)
            // 구독
            .assign(to: \.passwordInput, on: viewModel)
            .store(in: &mySubscriptions)
        
        passwordConfirmTextField
            .myTextPublisher
            .print()
            // 다른 스레드와 같이 작업하기 때문에 RunLoop로 돌리기
            .receive(on: RunLoop.main)
            // 구독
            .assign(to: \.passwordConfirmInput, on: viewModel)
            .store(in: &mySubscriptions)
        
        // 버튼이 뷰모델의 퍼블리셔를 구독
        viewModel.isMatchPasswordInput
            .print()
            .receive(on: RunLoop.main)
            // 구독
            .assign(to: \.isValid, on: myBtn)
            .store(in: &mySubscriptions)
    }
}

extension UISearchTextField {
    var myDebounceSearchPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(for: UISearchTextField.textDidChangeNotification, object: self)
            // 노티피케이션 센터에서 UISearchTextField 가져옴
            .compactMap{ $0.object as? UISearchTextField }
            // UISearchTextField에서 String 가져옴
            .map{ $0.text ?? "" }
            // 디바운스
            .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
            // 글자가 있을 때만 이벤트 전달
            .filter{ $0.count > 0 }
            .print()
            .eraseToAnyPublisher()
    }
}

extension UITextField {
    var myTextPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: self)
            // UITextField 가져옴
            .compactMap{ $0.object as? UITextField }
            // String 가져옴
            .map{ $0.text ?? "" }
//            .print()
            .eraseToAnyPublisher()
    }
}

extension UIButton {
    var isValid: Bool {
        get {
            backgroundColor == .green
        }
        set {
            backgroundColor = newValue ? .green : .lightGray
            isEnabled = newValue
            tintColor = newValue ? .white : .black
        }
    }
}
