//
//  LoginViewController.swift
//  KeychainExample
//
//  Created by Zvonimir Medak on 19.03.2021..
//

import Foundation
import UIKit
import RxSwift
import LocalAuthentication
import SnapKit
import RxCocoa

struct Credentials {
    var username: String
    var password: String
}

struct KeychainError: Error {
    var status: OSStatus
    
    var localizedDescription: String {
        return SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error."
    }
}

class LoginViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    
    let emailInput: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.borderStyle = .line
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.placeholder = "Username"
        return textField
    }()
    
    let passwordInput: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.borderStyle = .line
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.placeholder = "Password"
        return textField
    }()
    
    let registrationButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 20
        button.setTitle("Register to keychain", for: .normal)
        return button
    }()
    
    let loginButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 20
        button.setTitle("Prefill with keychain", for: .normal)
        return button
    }()
    
    let deleteButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 20
        button.setTitle("Delete from keychain", for: .normal)
        return button
    }()
    
    let authenticateUserButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 20
        button.setTitle("Delete from keychain", for: .normal)
        return button
    }()
    
    
    let biometricAuthentication = BiometricsAuthentication()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        registrationButton.isHidden = !biometricAuthentication.canEvaluatePolicy()
        loginButton.isHidden = !biometricAuthentication.canEvaluatePolicy()
        deleteButton.isHidden = !biometricAuthentication.canEvaluatePolicy()
        authenticateUserButton.isHidden = !biometricAuthentication.canEvaluatePolicy()
    }
}

private extension LoginViewController {
    
    func setupUI() {
        view.addSubview(passwordInput)
        view.addSubview(emailInput)
        view.addSubview(registrationButton)
        view.addSubview(loginButton)
        view.addSubview(deleteButton)
        view.addSubview(authenticateUserButton)
        setupConstraints()
        initializeObservers()
    }
    
    func setupConstraints() {
        emailInput.snp.makeConstraints { (maker) in
            maker.top.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 80, left: 15, bottom: 0, right: 15))
            maker.height.equalTo(40)
        }
        
        passwordInput.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(15)
            maker.top.equalTo(emailInput.snp.bottom).inset(-20)
            maker.height.equalTo(40)
        }
        
        registrationButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(50)
            maker.bottom.equalToSuperview().inset(50)
            maker.height.equalTo(40)
        }
        
        loginButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(50)
            maker.bottom.equalTo(registrationButton.snp.top).inset(-30)
            maker.height.equalTo(40)
        }
        
        deleteButton.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(50)
            maker.bottom.equalTo(loginButton.snp.top).inset(-30)
            maker.height.equalTo(40)
        }
    }
    
    func initializeObservers() {
        registrationButton.rx.tap.subscribe(onNext: { [unowned self] in
            do {
                guard let safeEmail = emailInput.text, let safePassword = passwordInput.text else {return}
                try addCredentials(Credentials(username: safeEmail, password:  safePassword), server: "www.example.com")
                emailInput.text = ""
                passwordInput.text = ""
            } catch {
                print(error.localizedDescription)
            }
        }).disposed(by: disposeBag)
        
        loginButton.rx.tap.subscribe(onNext: { [unowned self] in
            do {
                let credentials = try readCredentials(server: "www.example.com")
                emailInput.text = credentials.username
                passwordInput.text = credentials.password
            } catch {
                print(error.localizedDescription)
            }
        }).disposed(by: disposeBag)
        
        deleteButton.rx.tap.subscribe(onNext: { [unowned self] in
            do {
                try deleteCredentials(server: "www.example.com")
            } catch {
                if let error = error as? KeychainError {
                    print(error.localizedDescription)
                }
            }
            
        }).disposed(by: disposeBag)
        
        authenticateUserButton.rx.tap.subscribe(onNext: {[unowned self] in
            biometricAuthentication.authenticateUser { (errorMessage) in
                if let error = errorMessage {
                    print(error)
                } else {
                    print("Authenticated")
                    //do whatever you like :)
                }
            }
        }).disposed(by: disposeBag)
    }
}

private extension LoginViewController {
    func addCredentials(_ credentials: Credentials, server: String) throws {
        let account = credentials.username
        let password = credentials.password.data(using: String.Encoding.utf8)!
        let access = SecAccessControlCreateWithFlags(nil,
                                                     kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                     .userPresence,
                                                     nil)
        let context = LAContext()
        context.localizedReason = "Want to save credentials to keychain?"
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: server,
                                    kSecAttrAccessControl as String: access as Any,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecValueData as String: password]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
    
    func readCredentials(server: String) throws -> Credentials {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        
        guard let existingItem = item as? [String: Any],
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8),
              let account = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError(status: errSecInternalError)
        }
        
        return Credentials(username: account, password: password)
    }
    
    func deleteCredentials(server: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
}
