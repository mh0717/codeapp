//
//  SubIAPView.swift
//  iPyDE
//
//  Created by Huima on 2024/4/29.
//

import SwiftUI
import RMStore
import pydeCommon
import RevenueCat






private struct PkgCell: View {
    let title: String
    
    var body: some View {
        Label(title, systemImage: "shippingbox")
    }
}

func isCN() -> Bool {
    return UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first?.hasSuffix("CN") == true
}


struct SubIAPView: View {
    
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var iapManager: SubIapManager
//    @State var iapManager: SubIapManager = SubIapManager.instance
    
    @State private var tabSelection = 0
    
    @State private var showNotPayAlert = false
    @State private var showPaySucessAlert = false
    @State private var showPayFailedAlert = false
    @State private var showRestoreSucessAlert = false
    @State private var showRestoreFailedAlert = false
    
    @State private var cellWidth = 100.0
    
    let resourceBundle = Bundle(path: Bundle.main.bundlePath + "/pyde_pyde.bundle")
    
    private func computeSixOff() -> String? {
        guard let monthly = iapManager.monthly, let sixMonth = iapManager.sixMonth else {
            return nil
        }
        
        let off = 1.0 - (sixMonth.storeProduct.price as Decimal) / ((monthly.storeProduct.price as Decimal) * 6.0)
        if off <= 0 || off >= 1 {
            return nil
        }
        if isCN() {
            return String(format: "%.0f%% 折", Double(truncating: (1.0 - off) as NSNumber) * 100)
        }
        return String(format: "%.0f%% OFF", Double(truncating: off as NSNumber) * 100)
    }
    
    private func computeYearOff() -> String? {
        guard let monthly = iapManager.monthly, let year = iapManager.annual else {
            return nil
        }
        
        let off = 1.0 - (year.storeProduct.price as Decimal) / ((monthly.storeProduct.price as Decimal) * 12.0)
        if off <= 0 || off >= 1 {
            return nil
        }
        if isCN() {
            return String(format: "%.0f%% 折扣", Double(truncating: (1.0 - off) as NSNumber) * 100)
        }
        return String(format: "%.0f%% OFF", Double(truncating: off as NSNumber) * 100.0)
    }
    
    private func trialPeriod(_ package: Package?) -> String? {
        guard let discount = package?.storeProduct.introductoryDiscount else {
            return nil
        }
        
        var unit = "Day"
        switch discount.subscriptionPeriod.unit {
        case .day:
            unit = "iap.period.Day"
            break
        case .week:
            unit = "iap.period.Week"
            break
        case .month:
            unit = "iap.period.Month"
            break
        case .year:
            unit = "iap.period.Year"
            break
        }
        unit = NSLocalizedString(unit, comment: "iap.period.unit")
        return "\(discount.subscriptionPeriod.value) \(unit)"
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("Python3IDE Premium").font(.largeTitle)
                if !iapManager.isPro {
                    Text("Unlock Preminum to get access to all these features")
                }
                
                if iapManager.isPro && iapManager.proEntitlement?.periodType == .trial {
                    HStack {
                        Text("Trial period: ")
                        Text(iapManager.proEntitlement?.expirationDate?.formatted() ?? "")
                    }
                }
                
                if iapManager.isPro && iapManager.proEntitlement?.periodType == .normal {
                    HStack {
                        Text("Membership expiration: ")
                        Text(iapManager.proEntitlement?.expirationDate?.formatted() ?? "")
                    }
                }
                
                if iapManager.isPro && iapManager.proEntitlement?.periodType == .intro {
                    HStack {
                        Text("Grace period(please renew): ")
                        Text(iapManager.proEntitlement?.expirationDate?.formatted() ?? "")
                    }
                }
                
                TabView() {
                    VStack {
                        List {
                            Section(header: Text("Data Analysis")) {
                                PkgCell(title: "Numpy")
                                PkgCell(title: "Pandas")
                                PkgCell(title: "Matplotlib")
                                PkgCell(title: "Scipy")
                                PkgCell(title: "SKLearn")
                                PkgCell(title: "StatsModels")
                                PkgCell(title: "pyrsistent")
                                PkgCell(title: "pyemd")
                                PkgCell(title: "lxml")
                                PkgCell(title: "yaml")
                            }
                            Section(header: Text("Image Processing")) {
                                PkgCell(title: "Pillow")
                                PkgCell(title: "OpenCV")
                                PkgCell(title: "SKImage")
                                PkgCell(title: "PyCairo")
                                PkgCell(title: "contourpy")
                                
                            }
                            Section(header: Text("Game Develop")) {
                                PkgCell(title: "SDL2")
                                PkgCell(title: "PyGame")
                            }
                            Section(header: Text("UI Develop")) {
                                PkgCell(title: "PyGame_gui")
                                PkgCell(title: "Kivy")
                                PkgCell(title: "KivyMD")
                                PkgCell(title: "Imgui")
                                PkgCell(title: "Flet")
                                PkgCell(title: "Toga")
                            }
                            Section(header: Text("Bioinformatics")) {
                                PkgCell(title: "BioPython")
                            }
                            Section(header: Text("Astronomy")) {
                                PkgCell(title: "PyErfa")
                                PkgCell(title: "astropy")
                            }
                            Section(header: Text("Natural Language Processing")) {
                                PkgCell(title: "pygensim")
                            }
                            Section(header: Text("GIS")) {
                                PkgCell(title: "pyproj")
                                PkgCell(title: "rasterstats")
                                PkgCell(title: "fiona")
                                PkgCell(title: "pyproj")
                                PkgCell(title: "rasterio")
                            }
                            Section(header: Text("Quantum Computing")) {
                                PkgCell(title: "qutip")
                            }
                            Section(header: Text("Signal Decomposition")) {
                                PkgCell(title: "pyemd")
                                PkgCell(title: "pywt")
                            }
                            Section(header: Text("Other")) {
                                PkgCell(title: "cffi")
                                PkgCell(title: "pyzmq")
                                PkgCell(title: "pyobjus")
                                PkgCell(title: "markupsafe")
                                PkgCell(title: "psutil")
                                PkgCell(title: "fontTools")
                            }
                        }
                        .listStyle(.sidebar)
                        .listRowSeparator(.hidden)
                        Text("40+ C extension library").padding()
                        Text("")
                        Text("")
                    }
                    VStack {
                        
                        List {
                            ForEach(pipBundledPackage) {pkg in
                                HStack {
                                    Image(systemName: "shippingbox")
                                    Text(pkg.name).foregroundColor(.primary)
                                    Spacer()
                                    Text(pkg.version).foregroundColor(.secondary)
                                }
                            }
//                            Text("numpy")
//                            Text("pandas")
//                            Text("matplotlib")
//                            Text("scipy")
//                            Text("sdl2")
//                            Text("pygame")
//                            Text("kivy")
//                            Text("numpy")
//                            Text("pandas")
//                            Text("matplotlib")
//                            Text("scipy")
//                            Text("sdl2")
//                            Text("pygame")
//                            Text("kivy")
                        }
                        Text("200+ bundled libraries").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_pip1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_pip2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_pip3.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_pip4.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_pip5.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Pip installation of pure Python libraries").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_run1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run7.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run3.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run8.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run4.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run9.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run5.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run10.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_run6.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Run Python code locally").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_code1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_code2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_code3.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_code4.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_code5.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_code6.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_code7.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Highlighting and Completion").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_outline1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_outline2.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Generate outline using ctags").padding()
                        Text("")
                        Text("")
                    }

                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_theme1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_theme2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_theme3.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_theme4.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_theme5.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_theme6.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_theme7.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("10+ Themes").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_nb1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_nb2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_nb3.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_nb4.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Run Jupyter Notebook locally").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_search0.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_search1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_search2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_search3.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_search4.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Multifile Search").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_git1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_git2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_git3.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Git Version Control | Clone, Commit, Push").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_cmd1.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Built in Terminal, 100+ commands").padding()
                        Text("")
                        Text("")
                    }
                    
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_python.jpg", in: resourceBundle, with: nil)!,
                        ])
                        Text("Life is short, use Python").padding()
                        Text("")
                        Text("")
                    }
                }
                .padding(.horizontal)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    //            .background(.orange)
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = .orange
                    UIPageControl.appearance().pageIndicatorTintColor = .gray
                }
                
                HStack(spacing: 20) {
                    
                    ProductCell(title: "1", subTitle: "iap.month", price: iapManager.monthly?.localizedPriceString ?? "?", discount: nil, selected: iapManager.selectedPackage == iapManager.monthly, width: cellWidth).onTapGesture {
                        iapManager.selectedPackage = iapManager.monthly
                    }
                    
                    ProductCell(title: "1", subTitle: "iap.year", price: iapManager.annual?.localizedPriceString ?? "?", discount: computeYearOff(), selected: iapManager.selectedPackage == iapManager.annual, width: cellWidth).onTapGesture {
                        iapManager.selectedPackage = iapManager.annual
                    }
                    
                    ProductCell(title: "6", subTitle: "iap.months", price: iapManager.sixMonth?.localizedPriceString ?? "?", discount: computeSixOff(), selected: iapManager.selectedPackage == iapManager.sixMonth, width: cellWidth).onTapGesture {
                        iapManager.selectedPackage = iapManager.sixMonth
                    }
                }
                
                if /*!iapManager.isPro, */let trial = trialPeriod(iapManager.selectedPackage) {
                    HStack {
        //                Text("Trial period: 1 week for FREE")
                        Text("Trial period: ")
                        Text(trial).fontWeight(.bold)
                        Text(" for FREE").fontWeight(.bold)
                    }
                }
                
                
                Button {
                    if !Purchases.canMakePayments() {
                        showNotPayAlert.toggle()
                        return
                    }
                    
                    if iapManager.purchasing || iapManager.restoring {
                        return
                    }
                    
                    Task {
                        let result = await iapManager.purchase()
                        if result {
                            showPaySucessAlert.toggle()
                        } else {
                            showPayFailedAlert.toggle()
                        }
                    }
                    
                }
                label: {
                    Label(title: {
                        Text("CONTINUE")
                    }) {
                        if iapManager.purchasing {
                            PYActivityIndicator(isAnimating: .constant(true), style: .medium, color: UIColor.white)
                        }
                    }
                        .frame(maxWidth: .infinity)
                        .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }.background(Color.init(hex: 0xE93C06))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .cornerRadius(20)
                
                Button(action: {
                    if iapManager.restoring || iapManager.purchasing {
                        return
                    }
                    
                    Task {
                        let result = await iapManager.restore()
                        print(result)
                        if result {
                            showRestoreSucessAlert.toggle()
                        } else {
                            showRestoreFailedAlert.toggle()
                        }
                    }
                }, label: {
                    Label(title: {
                        Text("iap.restore")
                    }) {
                        if iapManager.restoring {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        }
                    }
                        .foregroundColor(.primary)
                }).frame(maxWidth: .infinity)
            }
            .frame(maxWidth: 480)
            .padding(.vertical)
        }.onAppear {
            iapManager.updateRevenucat()
        }
        .onSize(in: { size in
            DispatchQueue.main.async {
                self.cellWidth = (size.width - 60) / 3.0
            }
        })
        .toast(isPresenting: $showNotPayAlert) {
            AlertToast(displayMode: .alert, type: .regular, title: "In-App Purchase Not Allowed", subTitle: "Please goto【Setting】open In-App Purchase")
        }
        .toast(isPresenting: $showPaySucessAlert) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: "Purchase Succeed")
        }
        .toast(isPresenting: $showPayFailedAlert) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Purchase failed", subTitle: iapManager.errorMsg)
            
        }
        .toast(isPresenting: $showRestoreSucessAlert) {
            AlertToast(displayMode: .alert, type: .complete(.green), title: "Restore Succeed")
        }
        .toast(isPresenting: $showRestoreFailedAlert) {
            AlertToast(displayMode: .alert, type: .error(.red), title: "Restore failed", subTitle: iapManager.errorMsg)
        }
    }
}

private struct ProductCell: View {
    @Environment(\.colorScheme) var colorScheme
    var isLight: Bool {
        colorScheme == .light
    }
    
    let title: String
    let subTitle: String
    let price: String
    let discount: String?
    let selected: Bool
//    @State var selected = false
    let width: Double
    var body: some View {
        var offColor: UInt = 0x000000
        var offAlpha = discount == nil ? 0.0 : 1.0
        if isLight {
            offColor = selected ? 0x009400 : 0xDFDFDF
        } else {
            offColor = selected ? 0x009400 : 0x5F6463
        }
        
        let offTextColor: UInt = selected ? 0xFFFFFF : (isLight ? 0x000000 : 0xFFFFFF)
        
        return ZStack(alignment: .top) {
            VStack() {

            }.frame(idealWidth: width, idealHeight: 100)
                .fixedSize()
                .background(Color.init(hex: offColor, alpha: offAlpha))
                .cornerRadius(20)
            
            VStack(spacing: 0) {
                Text(discount ?? "").font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.init(hex: offTextColor))
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                VStack {
                    Text(title).font(.system(size: 25, weight: .heavy)).minimumScaleFactor(0.5).lineLimit(1)
                    Text(NSLocalizedString(subTitle, comment: "")).font(.system(size: 13, weight: .heavy)).minimumScaleFactor(0.5).lineLimit(1)
                    Text(price).font(.system(size: 20, weight: .heavy)).minimumScaleFactor(0.5).lineLimit(1)
                }
                .frame(idealWidth: width, idealHeight: 100)
                .fixedSize()
                .overlay(alignment: .topTrailing, content: {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Color.init(hex: offColor))
                            .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 5))
                    }
                })
                .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.init(hex: offColor), lineWidth: 2)
                            .padding(EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
                                
                    )
            }
            
        }
    }
}

private struct PYActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    let color: UIColor

    func makeUIView(context: UIViewRepresentableContext<PYActivityIndicator>) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: style)
        view.color = color
        return view
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<PYActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        uiView.color = color
    }
}


extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct SizeCalculator: ViewModifier {
    
    let onSize:  (_ size: CGSize) -> Void
    
    private func handlResize(_ size: CGSize) -> Color {
        onSize(size)
        return Color.clear
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    self.handlResize(proxy.size)
                }
            )
    }
}

extension View {
    func onSize(in onSize: @escaping (_ size: CGSize) -> Void) -> some View {
        modifier(SizeCalculator(onSize: onSize))
    }
}


//struct ImageSquenceAnimation: UIViewRepresentable {
//    
//    let images: [UIImage]
//
//    func makeUIView(context: Self.Context) -> UIView {
//        let someView = UIView()
//        someView.layer.cornerRadius = 20
//        someView.clipsToBounds = true
//        let someImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 360, height: 180))
//        someImage.contentMode = UIView.ContentMode.scaleAspectFit
//        someImage.image = UIImage.animatedImage(with: images, duration: TimeInterval(images.count))
//        
//        someView.addSubview(someImage)
//        someImage.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            someImage.widthAnchor.constraint(equalTo: someView.widthAnchor),
//            someImage.heightAnchor.constraint(equalTo: someView.heightAnchor),
////            someImage.topAnchor.constraint(equalTo: someView.topAnchor),
////            someImage.leftAnchor.constraint(equalTo: someView.leadingAnchor)
//        ])
//        return someView
//    }
//
//    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<ImageSquenceAnimation>) {
//        
//    }
//}


#Preview {
    IAPView()
}


