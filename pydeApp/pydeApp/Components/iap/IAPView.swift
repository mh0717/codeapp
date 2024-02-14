//
//  *.swift
//  pydeApp
//
//  Created by Huima on 2024/1/28.
//

import SwiftUI


private struct PkgCell: View {
    let title: String
    
    var body: some View {
        Label(title, systemImage: "shippingbox")
    }
}


struct IAPView: View {
    
    @State private var tabSelection = 0
    
    let resourceBundle = Bundle(path: Bundle.main.bundlePath + "/pyde_pyde.bundle")
    
    var body: some View {
        HStack {
            VStack {
                Text("Pyde Premium").font(.largeTitle)
                Text("解锁使用Pyde全功能版")
                TabView() {
                    VStack {
                        
                        List {
                            Section(header: Text("数据分析")) {
                                PkgCell(title: "Numpy")
                                PkgCell(title: "Pandas")
                                PkgCell(title: "Matplotlib")
                                PkgCell(title: "Scipy")
                                PkgCell(title: "SKLearn")
                                PkgCell(title: "StatsModels")
                                PkgCell(title: "PYSistent")
                                PkgCell(title: "pyemd")
                                PkgCell(title: "lxml")
                                PkgCell(title: "yaml")
                            }
                            Section(header: Text("图像处理")) {
                                PkgCell(title: "Pillow")
                                PkgCell(title: "OpenCV")
                                PkgCell(title: "SKImage")
                                PkgCell(title: "PyCairo")
                                PkgCell(title: "contourpy")
                                
                            }
                            Section(header: Text("游戏开发")) {
                                PkgCell(title: "SDL2")
                                PkgCell(title: "PyGame")
                            }
                            Section(header: Text("UI开发")) {
                                PkgCell(title: "Kivy")
                                PkgCell(title: "Imgui")
                                PkgCell(title: "Flet")
                            }
                            Section(header: Text("生物信息学 ")) {
                                PkgCell(title: "BioPython")
                            }
                            Section(header: Text("天文学")) {
                                PkgCell(title: "PyErfa")
                                PkgCell(title: "astropy")
                            }
                            Section(header: Text("自然语言处理")) {
                                PkgCell(title: "pygensim")
                            }
                            Section(header: Text("地理信息系统 GIS")) {
                                PkgCell(title: "pyproj")
                                PkgCell(title: "rasterstats")
                                PkgCell(title: "fiona")
                                PkgCell(title: "pyproj")
                                PkgCell(title: "rasterio")
                            }
                            Section(header: Text("量子计算")) {
                                PkgCell(title: "qutip")
                            }
                            Section(header: Text("信号分解")) {
                                PkgCell(title: "pyemd")
                            }
                            Section(header: Text("其它")) {
                                PkgCell(title: "pyzmq")
                                PkgCell(title: "psutil")
                            }
                        }
                        .listStyle(.sidebar)
                        .listRowSeparator(.hidden)
                        Text("25+ C扩展库").padding()
                        Text("")
                        Text("")
                    }
                    VStack {
                        
                        List {
                            Text("numpy")
                            Text("pandas")
                            Text("matplotlib")
                            Text("scipy")
                            Text("sdl2")
                            Text("pygame")
                            Text("kivy")
                            Text("numpy")
                            Text("pandas")
                            Text("matplotlib")
                            Text("scipy")
                            Text("sdl2")
                            Text("pygame")
                            Text("kivy")
                        }
                        Text("100+ 常用库").padding()
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
                        Text("Pip安装纯Python库").padding()
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
                        Text("本地运行Python代码").padding()
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
                        Text("语法高亮及代码补全").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_outline1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_outline2.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("大纲").padding()
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
                        Text("10+主题").padding()
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
                        Text("本地运行Jupyter Notebook").padding()
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
                        Text("全局搜索").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_git1.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_git2.png", in: resourceBundle, with: nil)!,
                            UIImage(named: "iap_git3.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("Git版本控制 | Clone, Commit, Push").padding()
                        Text("")
                        Text("")
                    }
                    
                    VStack {
                        ImageSquenceAnimation(images: [
                            UIImage(named: "iap_cmd1.png", in: resourceBundle, with: nil)!,
                        ])
                        Text("内置终端,100+命令").padding()
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
                
                
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                    Text("解锁会员: $9.9")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }).buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.horizontal)
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                    Text("恢复")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                })
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal)
            }
            .frame(maxWidth: 480)
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

