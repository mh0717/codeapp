export all_proxy=socks5://127.0.0.1:7890
xcodebuild -resolvePackageDependencies -scmProvider system
xcodebuild -resolvePackageDependencies -scmProvider xcode
xcodebuild -resolvePackageDependencies
