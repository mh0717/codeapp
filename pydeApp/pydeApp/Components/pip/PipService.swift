//
//  PipService.swift
//  pydeApp
//
//  Created by Huima on 2023/11/26.
//

import Foundation
import pydeCommon

public class PipService {
    static func fetchIndexPackages() async -> [String] {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return xcpreview_packages
        }
        #endif
        let index = ConstantManager.libraryURL.appendingPathComponent("pypi_index.html")
        if (FileManager.default.fileExists(atPath: index.path)) {
            do {
                let content = try String(contentsOf: index)
                let lines = content.components(separatedBy: "\n")
                var packages = [String]()
                for line in lines {
                    if line.contains("/simple/"), let name = line.slice(from: "/\">", to: "<") {
                        packages.append(name)
                    }
                }
                return packages
            } catch {
                print(error.localizedDescription)
            }
            return []
        }
        
        do {
            let content = try String(contentsOf: ConstantManager.PYPI_INDEX_URL)
            let lines = content.components(separatedBy: "\n")
            return lines
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    static func fetchInstalledPackages() async -> [PipPackage]  {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return xcpreview_installPackages
        }
        #endif
        let output = await executeCommand("remote pip3 list --format json --no-color --disable-pip-version-check --no-python-version-warning")
        guard let output, !output.isEmpty else {return []}
        
        var outputJson: String = ""
        do {
            let pattern = "\\[\\{.*\\}\\]"
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(output.startIndex..., in: output)
            let matchRange = regex.firstMatch(in: output, options: [], range: range)?.range
            if let range = matchRange {
                let result = output[Range(range, in: output)!]
                outputJson = String(result)
            } else {
                return []
            }
        } catch {
            print("Invalid regular expression: \(error.localizedDescription)")
            return []
        }
        
        if let packages = try? JSONSerialization.jsonObject(with: outputJson.data(using: .utf8) ?? Data()) as? [[String:String]] {
            var list = [PipPackage]()
            for package in packages {
                if let name = package["name"], let version = package["version"] {
                    if !pipBundledPackage.contains(where: {$0.name == name && $0.version == version}) {
                        list.append(PipPackage(name, version))
                    }
                }
            }
            return list
        } else {
            return []
        }
    }
    
    static func fetchUpdatablePackages() async -> [PipPackage] {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return xcpreview_updatablePackages
        }
        #endif
        
        let output = await executeCommand("pip3 list --outdated --format json --no-color --disable-pip-version-check --no-python-version-warning")
        guard let output else {return []}
        
        var outputJson: String = ""
        do {
            let pattern = "\\[\\{.*\\}\\]"
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(output.startIndex..., in: output)
            let matchRange = regex.firstMatch(in: output, options: [], range: range)?.range
            if let range = matchRange {
                let result = output[Range(range, in: output)!]
                outputJson = String(result)
            } else {
                return []
            }
        } catch {
            print("Invalid regular expression: \(error.localizedDescription)")
            return []
        }
        
        let installed = outputJson
        
        if let packages = try? JSONSerialization.jsonObject(with: installed.data(using: .utf8) ?? Data()) as? [[String:String]] {
            var list = [PipPackage]()
            for package in packages {
                if let name = package["name"], let version = package["version"] {
                    if !pipBundledPackage.contains(where: {$0.name == name && $0.version == version}) {
                        list.append(PipPackage(name, version))
                    }
                }
            }
            return list
        } else {
            return []
        }
    }
    
    static func fetchLocalPackageInfo(_ package: String) async -> String {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return xcpreview_localPackageInfo
        }
        #endif
        
        
        let output = await executeCommand("remote pip3 show \(package) --no-color --disable-pip-version-check --no-python-version-warning")
        guard let output else {return ""}
        
        do {
            let pattern = "Name: "
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(output.startIndex..., in: output)
            let matchRange = regex.firstMatch(in: output, options: [], range: range)?.range
            if let range = matchRange {
                let newRange = NSRange(location: range.location, length: output.count - range.location)
                let result = output[Range(newRange, in: output)!]
                return String(result)
            } else {
                return ""
            }
        } catch {
            print("Invalid regular expression: \(error.localizedDescription)")
            return ""
        }
    }
    
    static func fetchRemotePackageInfo(_ name: String) async -> PipRemotePackage? {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return xcpreview_remotePackageInfo
        }
        #endif
        var package = PipRemotePackage()
        let mirror: String
        if let _mirror = ProcessInfo.processInfo.environment["PYPI_MIRROR"] {
            var splitted = _mirror.components(separatedBy: "/")
            if splitted.last == "" {
                splitted.removeLast()
            }
            if splitted.last == "simple" {
                splitted.removeLast()
            }
            splitted.append("pypi")
            
            mirror = splitted.joined(separator: "/")
        } else {
            mirror = "https://pypi.python.org/pypi"
        }
        
        guard let url = URL(string: "\(mirror)/\(name)/json") else {
            return nil
        }
        
        do {
            async let result = try URLSession.shared.synchronousDataTask(with: URLRequest(url: url))
            
            guard let data = try await result.data else {
                return nil
            }
            
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return nil
                }
                
                guard let info = jsonResponse["info"] as? [String: Any] else {
                    return nil
                }
                                
                package.name = name
                package.description = info["summary"] as? String
                package.author = info["author"] as? String
                package.maintainer = info["maintainer"] as? String
                package.versions = ((jsonResponse["releases"] as? [String: Any])?.keys.sorted() ?? []).sorted(by: { (a, b) -> Bool in
                    let comparaison = a.compare(b, options: .numeric)
                    return (comparaison == .orderedDescending)
                })
                for version in package.versions {
                    if version.rangeOfCharacter(from: CharacterSet.letters) == nil {
                        package.stableVersion = version
                        break
                    }
                }
                var requirements = [String]()
                for requirement in (info["requires_dist"] as? [String] ?? []) {
                    requirements.append(requirement.components(separatedBy: ";")[0])
                }
                package.requirements = requirements
                
                var links = [(title: String, url: URL)]()
                for (title, value) in (info["project_urls"] as? [String:String]) ?? [:] {
                    if let url = URL(string: value) {
                        links.append((title: title, url: url))
                    }
                }
                package.links = links
                
                package.foundExtensions = (jsonResponse["urls"] as? [[String:Any]])?.contains(where: {
                    guard let filename = $0["filename"] as? String else {
                        return false
                    }
                    
                    for platform in [
                        "arm64",
                        "aarch64",
                        "x86_64",
                        "amd64",
                        "i686",
                        "",
                        "win32"
                        
                    ] {
                        if filename.contains(platform) {
                            return true
                        }
                    }
                    
                    return false
                }) == true
            } catch {
                return nil
            }
        } catch {
            return nil
        }
        return package
    }
    
    static func uninstallPackage(_ name: String) async -> Bool {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return true
        }
        #endif
        
        _ = await executeCommand("remote pip3 uninstall -y \(name)  --no-color --disable-pip-version-check --no-python-version-warning")
        return true
    }
    
    static func updatePackages(_ packages: [String]) async -> Bool {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return true
        }
        #endif

        _ = await executeCommand("remote pip3 update \(packages.joined(separator: " "))  --no-color --disable-pip-version-check --no-python-version-warning")
        return true
    }
    
    static func installPackage(_ package: String) async -> Bool {
    #if DEBUG
    if isXCPreview() {
        try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
        return true
    }
    #endif

        _ = await executeCommand("remote pythonA -m pip install --user \(package)  --no-color --disable-pip-version-check --no-python-version-warning")
    return true
    }
    
    
    static private var downloadingPyPICache = false
    static func updatePyPiCache() {
        guard !downloadingPyPICache else {
            return
        }
        
        downloadingPyPICache = true
        
        let task = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
        URLSession.shared.downloadTask(with: URL(string: "https://pypi.org/simple")!) { (fileURL, _, error) in
            
            self.downloadingPyPICache = false
            
            if let error = error {
                print(error.localizedDescription)
            } else if let url = fileURL {
                
                let cacheURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("pypi_index.html")
                if FileManager.default.fileExists(atPath: cacheURL.path) {
                    try? FileManager.default.removeItem(at: cacheURL)
                }
                
                do {
                    try FileManager.default.copyItem(at: url, to: cacheURL)
                } catch {
                    print(error.localizedDescription)
                }
                
                #if targetEnvironment(simulator)
                do {
                    let content = try String(contentsOf: url)
                    let lines = content.components(separatedBy: "\n")
                    var packages = [String]()
                    for line in lines {
                        if line.contains("/simple/"), let name = line.slice(from: "/\">", to: "<") {
                            packages.append(name)
                        }
                    }
                    let str = packages.joined(separator: "\n")
                    try str.write(to: URL(fileURLWithPath: "/Users/huima/PythonSchool/modules/pythoncc/pyde/Sources/pyde/h5/pypi_index.txt"), atomically: true, encoding: .utf8)
                } catch {
                    print(error.localizedDescription)
                }
                
                #endif
            }
            
            UIApplication.shared.endBackgroundTask(task)
        }.resume()
        
        #if targetEnvironment(simulator)
        Task {
            let packages = await fetchInstalledPackages()
            let url = URL(fileURLWithPath: "/Users/huima/PythonSchool/pydeApp/pydeApp/pydeApp/Components/pip/PipBundledPackages.swift")
            try?
            """
            //
            //  PipBundledPackages.swift
            //  iPyDE
            //
            //  Created by Huima on 2024/4/13.
            //

            import Foundation

            public let pipBundledPackage: [PipPackage] = [
            \(packages.map({"    PipPackage(\"\($0.name)\", \"\($0.version)\"),"}).joined(separator: "\n"))
            ]
            """.write(to: url, atomically: true, encoding: .utf8)
        }
        #endif
    }
    
    
}


struct PipRemotePackage {
    
    /// The name of the package.
    var name: String?
    
    /// The summary of the package.
    var description: String?
    
    /// The author of the package.
    var author: String?
    
    /// The maintainer of the package.
    var maintainer: String?
    
    /// All package versions.
    var versions: [String] = []
    
    /// The latest stable version.
    var stableVersion: String?
    
    /// The requirements of the package,
    var requirements: [String] = []
    
    /// Links of the project.
    var links = [(title: String, url: URL)]()
    
    /// `True` if download links for multiple platforms were found.
    var foundExtensions = false
}


fileprivate extension URLSession {

    func synchronousDataTask(with request: URLRequest) throws -> (data: Data?, response: HTTPURLResponse?) {

        let semaphore = DispatchSemaphore(value: 0)

        var responseData: Data?
        var theResponse: URLResponse?
        var theError: Error?

        dataTask(with: request) { (data, response, error) -> Void in

            responseData = data
            theResponse = response
            theError = error

            semaphore.signal()

        }.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        if let error = theError {
            throw error
        }

        return (data: responseData, response: theResponse as! HTTPURLResponse?)

    }

}




#if DEBUG

let xcpreview_packages = [
    "anyio2",
    "appnope2",
    "argon2-cffi2",
    "argon2-cffi-bindings2",
    "arrow2",
    "astropy2",
    "asttokens2",
    "attrs2",
    "backcall2",
    "beautifulsoup4",
    "biopython2",
    "bleach2",
    "certifi2",
    "certifi2",
    "cffi",
    "charset-normalizer2",
    "comm2",
    "contourpy2",
    "cppy2",
    "cycler2",
    "debugpy",
    "decorator",
    "defusedxml",
    "docutils",
    "executing",
    "fastjsonschema",
    "Fiona",
    "fonttools",
    "fqdn",
    "gensim",
    "idna",
    "idna",
    "imgui",
    "importlib-resources",
    "ios",
    "ipykernel",
    "ipython",
    "ipython-genutils",
    "isoduration",
    "jedi",
    "Jinja2",
    "jsonpointer",
    "jsonschema",
    "jupyter_client",
    "jupyter_core",
    "jupyter-events",
    "jupyter_server",
    "jupyter_server_terminals",
    "jupyterlab-pygments",
    "Kivy",
    "Kivy-Garden",
    "kiwisolver",
    "lxml",
    "MarkupSafe",
    "matplotlib",
    "matplotlib-inline",
    "mistune",
    "nbclassic",
    "nbclient",
    "nbconvert",
    "nbformat",
    "nest-asyncio",
    "notebook",
    "notebook_shim",
    "numpy",
    "overrides",
    "packaging",
    "pandas",
    "pandocfilters",
    "parso",
    "pexpect",
    "pickleshare",
    "Pillow",
    "pip",
    "platformdirs",
    "prometheus-client",
    "prompt-toolkit",
    "ptyprocess",
    "pure-eval",
    "pycparser",
    "pyemd",
    "pyerfa",
    "pygame",
    "Pygments",
    "Pygments",
    "pyobjus",
    "pyparsing",
    "pyproj",
    "pyrsistent",
    "python-dateutil",
    "python-json-logger",
    "pytz",
    "PyWavelets",
    "PyYAML",
    "pyzmq",
    "qutip",
    "rasterio",
    "requests",
    "requests",
    "rfc3339-validator",
    "rfc3986-validator",
    "rubicon-objc",
    "scikit-learn",
    "SciPy",
    "Send2Trash",
    "six",
    "sniffio",
    "soupsieve",
    "stack-data",
    "statsmodels",
    "terminado",
    "tinycss2",
    "tornado",
    "traitlets",
    "tzdata",
    "uri-template",
    "urllib3",
    "urllib3",
    "wcwidth",
    "webcolors",
    "webencodings",
    "websocket-client",
]

let xcpreview_installPackages = [
    PipPackage("numpy1", "1.2"),
    PipPackage("scipy1", "1.3"),
    PipPackage("matplotlib1", "2.2")
]

let xcpreview_updatablePackages = [
    PipPackage("numpy1", "1.4"),
    PipPackage("scipy1", "1.5"),
    PipPackage("matplotlib1", "2.3")
]

let xcpreview_localPackageInfo = 
    """
    Name: numpy
    Version: 1.22.3
    Summary: NumPy is the fundamental package for array computing with Python.
    Home-page: https://www.numpy.org
    Author: Travis E. Oliphant et al.
    Author-email: None
    License: BSD
    Location: /usr/local/lib/python3.9/site-packages
    Requires:
    Required-by: statsmodels, seaborn, scipy, PyWavelets, pyerfa, patsy, pandas, matplotlib, contourpy, colorspacious, astropy
    """

let xcpreview_remotePackageInfo = PipRemotePackage(
    name: "numpy",
    description: "Fundamental package for array computing in Python",
    author: "Autorh",
    maintainer: "Maintainer",
    versions: ["1.2", "1.3", "1.4"],
    stableVersion: "1.4",
    requirements: ["base"],
    links: [
        (title: "HomePage", url: URL(string: "https://www.pypi.com")!),
        (title: "github", url: URL(string: "https://www.github.com")!)
    ]
)
#endif
