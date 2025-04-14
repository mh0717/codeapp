#!/bin/bash
exit 0
# 配置变量
fwks=(
"pythonA"
"pythonA-python3_all"
"pythonB"
"pythonB-python3_all"
"python3_ios-zmq_all"
"python3_ios-psutil_all"
"python3_ios-fontTools_all"

"pythonA-zmq_all"
"pythonA-psutil_all"
"freetype"
"sixel"
"SDL2_ttf"
"SDL2_image"
"SDL2_mixer"

"clang"
"libLLVM"
"link"
"lld"
"lli"
"lua_ios"
"php"
"llc"
"ar"
"dis"
"nm"
"opt"
"perl"
"NodeMobile"
"ctags"

"python3_ios-numpy_all"
"python3_ios-PIL_all"
"python3_ios-cv2"
"python3_ios-skimage_all"
"python3_ios-cairo._cairo"

"python3_ios-kiwisolver._cext"
"python3_ios-matplotlib_all"
"python3_ios-pygame_all"
"python3_ios-pygame._sdl2.mixer"
"python3_ios-materialyoucolor.quantize.celebi"
"python3_ios-imgui_all"
"python3_ios-ios"
"python3_ios-pyobjus.pyobjus"
"python3_ios-kivy_all"

"python3_ios-yaml._yaml"
"python3_ios-lxml_all"
"python3_ios-markupsafe._speedups"
"python3_ios-tornado.speedups"


"python3_ios-pandas_all"
"libgfortran"
"openblas"
"python3_ios-scipy_all"
"python3_ios-statsmodels_all"
"python3_ios-sklearn_all"

"python3_ios-_argon2_cffi_bindings._ffi"
"python3_ios-gensim_all"
"python3_ios-Bio_all"
"python3_ios-pvectorc"
"python3_ios-pyemd.emd"
"python3_ios-pywt_all"
"python3_ios-erfa.ufunc"

"python3_ios-astropy_all"
"python3_ios-contourpy._contourpy"
"python3_ios-rasterio_all"
"python3_ios-qutip_all"
"python3_ios-fiona_all"
"python3_ios-pyproj_all"

) # 替换为你的框架名称数组
pathA="/Volumes/Python/PythonSchool/modules/pythoncc/XCFrameworks"                            # 替换为你的pathA实际路径
pathB="/Volumes/Python/PythonSchool/modules/pythoncc/PYXCFrameworks"                            # 替换为你的pathB实际路径

# 目标框架目录
frameworks_dir="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# 确保目标目录存在
mkdir -p "$frameworks_dir"

# 遍历所有框架
for fwk in "${fwks[@]}"; do
    # 构造候选路径
    xcframework_pathA="${pathA}/${fwk}.xcframework"
    xcframework_pathB="${pathB}/${fwk}.xcframework"
    candidate_pathA="${xcframework_pathA}/ios-arm64-maccatalyst/${fwk}.framework"
    candidate_pathB="${xcframework_pathB}/ios-arm64-maccatalyst/${fwk}.framework"
    
    # 优先级检查
    if [ -d "${candidate_pathA}" ]; then
        source_path="${candidate_pathA}"
        echo "Using pathA version for ${fwk}"
    elif [ -d "${candidate_pathB}" ]; then
        source_path="${candidate_pathB}"
        echo "Using pathB version for ${fwk}"
    else
        echo "error: Framework ${fwk} not found in:"
        echo "  - ${candidate_pathA}"
        echo "  - ${candidate_pathB}"
        exit 1
    fi

    # 目标路径检查
    framework_name="${fwk}.framework"
    dest_path="${frameworks_dir}/${framework_name}"
    
    if [ -d "$dest_path" ]; then
        echo "⚠️ ${framework_name} 已存在，跳过拷贝和签名"
        continue
    fi

    # 执行拷贝
    if cp -R "${source_path}" "${frameworks_dir}"; then
        echo "✅ 成功拷贝 ${framework_name}"
    else
        echo "error: 拷贝失败 ${framework_name}"
        exit 1
    fi

    # 代码签名
    if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" ]; then
        codesign --force \
                 --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
                 --timestamp=none \
                 --preserve-metadata=identifier,entitlements,flags \
                 --generate-entitlement-der \
                 "${dest_path}"
        echo "🔏 已签名 ${framework_name}"
    else
        echo "warning: 未找到签名证书"
    fi
done

