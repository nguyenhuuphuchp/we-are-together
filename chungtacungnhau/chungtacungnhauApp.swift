//
//  chungtacungnhauApp.swift
//  chungtacungnhau
//
//  Created by Nguyễn Hữu Phúc on 24/4/25.
//

import SwiftUI

import SwiftUI
import Firebase

//@main
//struct chungtacungnhauApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}


import SwiftUI
import Firebase

@main
struct chungtacungnhauApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
