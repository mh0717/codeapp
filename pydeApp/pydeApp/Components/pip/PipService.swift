//
//  PipService.swift
//  pydeApp
//
//  Created by Huima on 2023/11/26.
//

import Foundation
import pydeCommon

class PipService {
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
                    if !bundledPackage.contains(where: {$0.name == name && $0.version == version}) {
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
                    if !bundledPackage.contains(where: {$0.name == name && $0.version == version}) {
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
        
        let output = await executeCommand("remote pip3 uninstall -y \(name)  --no-color --disable-pip-version-check --no-python-version-warning")
        return true
    }
    
    static func updatePackages(_ packages: [String]) async -> Bool {
        #if DEBUG
        if isXCPreview() {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return true
        }
        #endif

        let output = await executeCommand("remote pip3 update \(packages.joined(separator: " "))  --no-color --disable-pip-version-check --no-python-version-warning")
        return true
    }
    
    static func installPackage(_ package: String) async -> Bool {
    #if DEBUG
    if isXCPreview() {
        try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
        return true
    }
    #endif

    let output = await executeCommand("remote pip3 install --user \(package)  --no-color --disable-pip-version-check --no-python-version-warning")
    return true
    }
    
    static var bundledPackage: [PipPackage] = [
        PipPackage("anyio", "3.7.0"),
        PipPackage("appnope", "0.1.3"),
        PipPackage("argon2-cffi", "21.3.0"),
        PipPackage("argon2-cffi-bindings", "21.2.1.dev66"),
        PipPackage("arrow", "1.2.3"),
        PipPackage("astropy", "5.2.1"),
        PipPackage("asttokens", "2.2.1"),
        PipPackage("attrs", "23.1.0"),
        PipPackage("backcall", "0.2.0"),
        PipPackage("beautifulsoup4", "4.12.2"),
        PipPackage("biopython", "1.81"),
        PipPackage("bleach", "6.0.0"),
        PipPackage("certifi", "2022.12.7"),
        PipPackage("certifi", "2023.5.7"),
        PipPackage("cffi", "1.15.1"),
        PipPackage("charset-normalizer", "3.1.0"),
        PipPackage("comm", "0.1.3"),
        PipPackage("contourpy", "1.0.8.dev1"),
        PipPackage("cppy", "1.2.1"),
        PipPackage("cycler", "0.11.0"),
        PipPackage("debugpy", "1.6.7"),
        PipPackage("decorator", "5.1.1"),
        PipPackage("defusedxml", "0.7.1"),
        PipPackage("docutils", "0.20.1"),
        PipPackage("executing", "1.2.0"),
        PipPackage("fastjsonschema", "2.17.1"),
        PipPackage("Fiona", "1.9.2"),
        PipPackage("fonttools", "4.39.2"),
        PipPackage("fqdn", "1.5.1"),
        PipPackage("gensim", "4.3.0"),
        PipPackage("idna", "3.4"),
        PipPackage("idna", "3.4"),
        PipPackage("imgui", "2.0.0"),
        PipPackage("importlib-resources", "5.12.0"),
        PipPackage("ios", "1.1"),
        PipPackage("ipykernel", "6.23.1"),
        PipPackage("ipython", "8.14.0"),
        PipPackage("ipython-genutils", "0.2.0"),
        PipPackage("isoduration", "20.11.0"),
        PipPackage("jedi", "0.18.2"),
        PipPackage("Jinja2", "3.1.2"),
        PipPackage("jsonpointer", "2.3"),
        PipPackage("jsonschema", "4.17.3"),
        PipPackage("jupyter_client", "8.2.0"),
        PipPackage("jupyter_core", "5.3.0"),
        PipPackage("jupyter-events", "0.6.3"),
        PipPackage("jupyter_server", "2.6.0"),
        PipPackage("jupyter_server_terminals", "0.4.4"),
        PipPackage("jupyterlab-pygments", "0.2.2"),
        PipPackage("Kivy", "2.2.0rc1"),
        PipPackage("Kivy-Garden", "0.1.5"),
        PipPackage("kiwisolver", "1.4.4"),
        PipPackage("lxml", "4.9.2"),
        PipPackage("MarkupSafe", "2.1.2"),
        PipPackage("matplotlib", "3.7.2.dev49+g2f25614599"),
        PipPackage("matplotlib-inline", "0.1.6"),
        PipPackage("mistune", "2.0.5"),
        PipPackage("nbclassic", "1.0.0"),
        PipPackage("nbclient", "0.8.0"),
        PipPackage("nbconvert", "7.4.0"),
        PipPackage("nbformat", "5.9.0"),
        PipPackage("nest-asyncio", "1.5.6"),
        PipPackage("notebook", "6.5.4"),
        PipPackage("notebook_shim", "0.2.3"),
        PipPackage("numpy", "1.24.2+23.gf14cd4457"),
        PipPackage("overrides", "7.3.1"),
        PipPackage("packaging", "23.0"),
        PipPackage("pandas", "2.0.0rc1+10.geccf9bd802.dirty"),
        PipPackage("pandocfilters", "1.5.0"),
        PipPackage("parso", "0.8.3"),
        PipPackage("pexpect", "4.8.0"),
        PipPackage("pickleshare", "0.7.5"),
        PipPackage("Pillow", "9.4.0"),
        PipPackage("pip", "23.2.1"),
        PipPackage("platformdirs", "3.5.3"),
        PipPackage("prometheus-client", "0.17.0"),
        PipPackage("prompt-toolkit", "3.0.38"),
        PipPackage("ptyprocess", "0.7.0"),
        PipPackage("pure-eval", "0.2.2"),
        PipPackage("pycparser", "2.21"),
        PipPackage("pyemd", "0.5.1"),
        PipPackage("pyerfa", "2.0.0.3.post1.dev0+ge33ee55.d20230610"),
        PipPackage("pygame", "2.4.0"),
        PipPackage("pyproject-toml", "0.0.10"),
        PipPackage("Pygments", "2.15.1"),
        PipPackage("Pygments", "2.15.1"),
        PipPackage("pyobjus", "1.2.2"),
        PipPackage("pyparsing", "3.0.9"),
        PipPackage("pyproj", "3.4.1"),
        PipPackage("pyrsistent", "0.19.3"),
        PipPackage("python-dateutil", "2.8.2"),
        PipPackage("python-json-logger", "2.0.7"),
        PipPackage("pytz", "2022.7.1"),
        PipPackage("PyWavelets", "1.4.1"),
        PipPackage("PyYAML", "6.0"),
        PipPackage("pyzmq", "25.1.0"),
        PipPackage("qutip", "4.7.1"),
        PipPackage("rasterio", "1.3.6"),
        PipPackage("requests", "2.28.2"),
        PipPackage("requests", "2.31.0"),
        PipPackage("rfc3339-validator", "0.1.4"),
        PipPackage("rfc3986-validator", "0.1.1"),
        PipPackage("rubicon-objc", "0.4.6"),
        PipPackage("scikit-learn", "1.3.dev0"),
        PipPackage("setuptools", "68.2.2"),
        PipPackage("SciPy", "1.10.2.dev0+2408.7f2ac69"),
        PipPackage("Send2Trash", "1.8.2"),
        PipPackage("six", "1.16.0"),
        PipPackage("sniffio", "1.3.0"),
        PipPackage("soupsieve", "2.4.1"),
        PipPackage("stack-data", "0.6.2"),
        PipPackage("statsmodels", "0.13.5"),
        PipPackage("terminado", "0.17.1"),
        PipPackage("tinycss2", "1.2.1"),
        PipPackage("toml", "0.10.2"),
        PipPackage("tornado", "6.3.2"),
        PipPackage("traitlets", "5.9.0"),
        PipPackage("tzdata", "2022.7"),
        PipPackage("uri-template", "1.2.0"),
        PipPackage("urllib3", "1.26.15"),
        PipPackage("urllib3", "2.0.2"),
        PipPackage("wcwidth", "0.2.6"),
        PipPackage("webcolors", "1.13"),
        PipPackage("webencodings", "0.5.1"),
        PipPackage("websocket-client", "1.5.3"),
        PipPackage("wheel", "0.36.2")
    ]
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
