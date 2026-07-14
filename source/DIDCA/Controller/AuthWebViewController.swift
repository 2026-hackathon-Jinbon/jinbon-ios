/*
 * Copyright 2025 JinBon.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import WebKit

protocol AuthWebViewDelegate: AnyObject {
    func authDidComplete(tokenData: AuthTokenData)
    func authDidCancel()
    func signupIdentityDidComplete(data: SignupIdentityData)
}

extension AuthWebViewDelegate {
    func signupIdentityDidComplete(data: SignupIdentityData) {}
}

class AuthWebViewController: UIViewController {

    enum Mode { case login, signup }

    private var webView: WKWebView!
    weak var delegate: AuthWebViewDelegate?
    var mode: Mode = .login

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = mode == .signup ? "회원가입 본인인증" : "로그인"

        setupNavigationBar()
        setupWebView()
        loadAuthPage()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "authCallback")
        contentController.add(self, name: "openDeepLink")
        config.userContentController = contentController
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadAuthPage() {
        let authURL = "\(URLs.JINBON_URL)/auth.html?mode=\(mode == .signup ? "signup" : "login")"
        if let url = URL(string: authURL) {
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                    timeoutInterval: 15))
        }
    }

    @objc private func cancelTapped() {
        delegate?.authDidCancel()
        dismiss(animated: true)
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "authCallback")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "openDeepLink")
    }
}

// MARK: - WKScriptMessageHandler

extension AuthWebViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? String else { return }

        if message.name == "openDeepLink" {
            guard let url = URL(string: body) else { return }
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:]) { [weak self] success in
                    if !success { self?.showLoadError("모바일 신분증 앱을 열 수 없습니다.") }
                }
            }
            return
        }

        guard message.name == "authCallback",
              let data = body.data(using: .utf8) else { return }

        do {
            if mode == .signup {
                let signupData = try JSONDecoder().decode(SignupIdentityData.self, from: data)
                Properties.setSignupToken(signupData.signupToken)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.dismiss(animated: true) { [weak self] in
                        self?.delegate?.signupIdentityDidComplete(data: signupData)
                    }
                }
            } else {
                let tokenData = try JSONDecoder().decode(AuthTokenData.self, from: data)
                JinBonAPIClient.shared.saveSession(tokenData)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.dismiss(animated: true) { [weak self] in
                        self?.delegate?.authDidComplete(tokenData: tokenData)
                    }
                }
            }
        } catch {
            print("Failed to parse auth callback: \(error)")
        }
    }
}

// MARK: - WKNavigationDelegate

extension AuthWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.domain == WKError.errorDomain && nsError.code == 102 { return }
        showLoadError("인증 화면을 불러오지 못했습니다.\n\(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showLoadError("인증 화면 연결이 끊어졌습니다.\n\(error.localizedDescription)")
    }

    private func showLoadError(_ message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "연결 오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "다시 시도", style: .default) { [weak self] _ in
            self?.loadAuthPage()
        })
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // oacx:// 딥링크 → 외부 앱으로 열기
        if url.scheme == "oacx" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
