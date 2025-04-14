#  PYDE

# Features

rich traceback


# Setting

rich traceback (locals)



# 1. 解除隔离属性
sudo xattr -rd com.apple.quarantine files.framework

# 2. 手动签名（使用自己的证书）
codesign --sign "Developer ID Application" --timestamp files.framework


# Entitlements, 检查沙盒权限
