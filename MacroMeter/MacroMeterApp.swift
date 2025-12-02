//
//  MacroMeterApp.swift
//  MacroMeter
//
//  Created by Andy Huoy on 12/2/25.
//

import SwiftUI

@main
struct MacroMeterApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(viewModel)
        }
    }
}
