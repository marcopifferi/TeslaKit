//
//  TeslaWebLoginViewContoller.swift
//  TeslaKit
//
//  Update by David Lüthi on 10.06.2021
//  based on code from Joao Nunes on 22/11/2020.
//  Copyright © 2022 David Lüthi. All rights reserved.
//

#if canImport(WebKit)
import WebKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Cocoa)
import Cocoa
#endif
import SwiftUI

#if os(macOS)
public typealias ViewControllerRepresentable = NSViewControllerRepresentable
public typealias ViewController = NSViewController
#else
public typealias ViewControllerRepresentable = UIViewControllerRepresentable
public typealias ViewController = UIViewController
#endif

public class TeslaWebLoginViewController: ViewController {
    #if os(macOS)
    var webView = WKWebView(frame: CGRect(x:0, y:0, width:300, height:600), configuration: WKWebViewConfiguration ())
    #else
    var webView = WKWebView()
    #endif
    private var continuation: CheckedContinuation<URL, Error>?

    required init?(coder: NSCoder) {
        fatalError("not supported")
    }

    init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
    }

    override public func loadView() {
        view = webView
    }

    func result() async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
}

extension TeslaWebLoginViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.absoluteString.starts(with: "https://auth.tesla.com/void/callback") {
            decisionHandler(.cancel)
            #if os(macOS)
            self.continuation?.resume(returning: url)
            self.dismiss(navigationAction)
            #else
            self.dismiss(animated: true) {
                self.continuation?.resume(returning: url)
            }
            #endif
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        #if os(macOS)
        self.dismiss(navigation)
        #else
        self.dismiss(animated: true) {
            self.continuation?.resume(throwing: TeslaError.authenticationFailed)
        }
        #endif
    }
}

extension TeslaWebLoginViewController {
    static func removeCookies() {
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}

@available(macOS 13.1, *)
public struct WebLogin: ViewControllerRepresentable {
    public var teslaAPI: TeslaAPI
    public let action: () -> Void
    
    public init(teslaAPI: TeslaAPI, action: @escaping () -> Void) {
        self.teslaAPI = teslaAPI
        self.action = action
    }
	
    #if os(macOS)
    public func makeNSViewController(context: Context) -> some TeslaWebLoginViewController {
        let (webloginViewController, result) = teslaAPI.authenticateWeb()
        guard let safeWebloginViewController = webloginViewController else {
            return TeslaWebLoginViewController(url: URL(string: "https://www.tesla.com")!)
        }
        
        Task { @MainActor in
            do {
                _ = try await result()
                self.action()
            } catch let error {
                print("Authentication failed: \(error)")
            }
        }
        return safeWebloginViewController
    }
    
    public func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
    }
    #else
    public func makeUIViewController(context: Context) -> TeslaWebLoginViewController {
        let (webloginViewController, result) = teslaAPI.authenticateWeb()
        guard let safeWebloginViewController = webloginViewController else {
            return TeslaWebLoginViewController(url: URL(string: "https://www.tesla.com")!)
        }
        
        Task { @MainActor in
            do {
                _ = try await result()
                self.action()
            } catch let error {
                print("Authentication failed: \(error)")
            }
        }
        return safeWebloginViewController
    }

    public func updateUIViewController(_ uiViewController: TeslaWebLoginViewController, context: Context) {
    }
    #endif
}

