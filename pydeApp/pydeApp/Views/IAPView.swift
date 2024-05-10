//
//  *.swift
//  pydeApp
//
//  Created by Huima on 2024/1/28.
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


struct IAPView: View {
    
    @EnvironmentObject var App: MainApp
    @EnvironmentObject var iapManager: IapManager
    
    @State private var tabSelection = 0
    
    @State private var showNotPayAlert = false
    @State private var showPaySucessAlert = false
    @State private var showPayFailedAlert = false
    
    let resourceBundle = Bundle(path: Bundle.main.bundlePath + "/pyde_pyde.bundle")
    
    var body: some View {
        HStack {
            VStack {
                Text("iPyDE Premium").font(.largeTitle)
                Text("Unlock Preminum to get access to all these features")
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
                
                HStack {
                    VStack {
                        Text("6").font(.system(size: 20))
                        Text("月")
                        Text("$6.2")
                    }
                    
                    VStack {
                        Text("1").font(.system(size: 20))
                        Text("年")
                        Text("$13.2")
                    }
                        .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                        .background(Color.orange)
                        .cornerRadius(15)
                    
                    VStack {
                        Text("1").font(.system(size: 20))
                        Text("月")
                        Text("$3.2")
                    }
                }
                
                
                
                Button(action: {
                    if !RMStore.canMakePayments() {
                        showNotPayAlert.toggle()
                        return
                    }
                    
                    if iapManager.purchasing {
                        return
                    }
                    
                    Task {
                        let result = await iapManager.purchase()
                        if result {
                            App.notificationManager.showSucessMessage("Sucessed")
                        } else {
//                            App.notificationManager.showErrorMessage("Failed")
                            showPayFailedAlert.toggle()
                        }
                    }
                }, label: {
                    Label(title: {
                        Text(localizedString(forKey: "iap.unlock") + " " + (iapManager.product != nil ? RMStore.localizedPrice(of: iapManager.product) : "?"))
                    }) {
                        if iapManager.purchasing {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        }
                    }
                    
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }).buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.horizontal)
                    .alert(isPresented: $showNotPayAlert) {
                        Alert(title: Text("In-App Purchase Not Allowed"), message: Text("Please goto【Setting】open In-App Purchase"))
                    }
                    .alert(isPresented: $showPayFailedAlert) {
                        Alert(title: Text("Unlock failed"))
                    }
                
                HStack() {
                    Button(action: {
                        if !iapManager.isTrialed && !iapManager.isTrialing && !iapManager.isPurchased {
                            iapManager.trial()
                        }
                    }, label: {
                        Text(
                            iapManager.isTrialing ? "In trial" : iapManager.isTrialed ? "Trial ended" : "Trial"
                        )
                            .frame(maxWidth: .infinity)
                    })
                    
                    Button(action: {
                        if iapManager.restoring {
                            return
                        }
                        
                        Task {
                            let result = await iapManager.restore()
                            print(result)
                            if result {
                                
                            } else {
                                
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
                            .frame(maxWidth: .infinity)
                    })
                }
                
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal)
                
            }
            .frame(maxWidth: 480)
            .padding(.vertical)
        }
        
    }
}

struct ImageSquenceAnimation: UIViewRepresentable {
    
    let images: [UIImage]

    func makeUIView(context: Self.Context) -> UIView {
        let someView = UIView()
        someView.layer.cornerRadius = 20
        someView.clipsToBounds = true
        let someImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 360, height: 180))
        someImage.contentMode = UIView.ContentMode.scaleAspectFit
        someImage.image = UIImage.animatedImage(with: images, duration: TimeInterval(images.count))
        
        someView.addSubview(someImage)
        someImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            someImage.widthAnchor.constraint(equalTo: someView.widthAnchor),
            someImage.heightAnchor.constraint(equalTo: someView.heightAnchor),
//            someImage.topAnchor.constraint(equalTo: someView.topAnchor),
//            someImage.leftAnchor.constraint(equalTo: someView.leadingAnchor)
        ])
        return someView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<ImageSquenceAnimation>) {
        
    }
}


#Preview {
    IAPView()
}

