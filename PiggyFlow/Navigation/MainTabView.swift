import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            
            Tab("Home", systemImage: "house.fill"){
                HomeView()
            }
            
            Tab("Stats", systemImage: "chart.xyaxis.line"){
                StatsView()
            }
            
            Tab("Scan", systemImage: "qrcode.viewfinder"){
                ScanView()
            }
            
            Tab("Settings", systemImage: "gearshape.fill"){
                SettingsView()
            }
            
        }
        .accentColor(.green)
    }
}
