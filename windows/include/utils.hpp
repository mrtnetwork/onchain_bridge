#pragma once
#include <fstream>
class OnChainWindowsUtils
{
public:
    inline OnChainWindowsUtils() {}

    static std::optional<std::vector<std::string>> GetStringListArg(
        const std::string &key,
        const flutter::EncodableMap *args)
    {
        // Find the key in the EncodableMap
        auto it = args->find(flutter::EncodableValue(key));
        if (it == args->end())
        {
            // Key not found, return std::nullopt
            return std::nullopt;
        }

        // Try to extract the value as a vector of strings
        if (const std::vector<flutter::EncodableValue> *list = std::get_if<std::vector<flutter::EncodableValue>>(&(it->second)))
        {
            std::vector<std::string> result;
            result.reserve(list->size());

            // Convert EncodableValue to std::string
            for (const auto &value : *list)
            {
                if (const std::string *str = std::get_if<std::string>(&value))
                {
                    result.push_back(*str);
                }
            }
            return result;
        }

        // The value is not a list of strings, return std::nullopt
        return std::nullopt;
    }
    static std::optional<std::string> GetStringArg(
        const std::string &param,
        const flutter::EncodableMap *args)
    {
        if (!args)
            return std::nullopt;

        auto it = args->find(flutter::EncodableValue(param));
        if (it == args->end())
            return std::nullopt;

        const flutter::EncodableValue &value = it->second;

        // Check if value is actually a string
        if (std::holds_alternative<std::string>(value))
        {
            return std::get<std::string>(value);
        }

        // Value is null or wrong type
        return std::nullopt;
    }

    static bool LaunchUrl(const std::string &url)
    {
        // Convert the std::string to LPCSTR
        LPCSTR urlLpcstr = url.c_str();

        // Launch the URL using ShellExecute
        HINSTANCE result = ShellExecuteA(NULL, "open", urlLpcstr, NULL, NULL, SW_SHOWNORMAL);

        // Check if the operation was successful
        if ((intptr_t)result > 32)
        {
            // Success
            return true;
        }
        else
        {
            // Failure
            return false;
        }
    }

    static flutter::EncodableMap getPaths()
    {
        flutter::EncodableMap paths;
        // Function to calculate the application-specific subdirectory
        auto getAppSpecificSubdirectory = [](const wchar_t *baseFolder, const wchar_t *subfolder) -> std::wstring
        {
            std::wstring fullPath(baseFolder);
            fullPath += L"\\";
            fullPath += subfolder;
            return fullPath;
        };
        // Document Path
        PWSTR docPath;
        if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_Documents, 0, NULL, &docPath)))
        {
            std::wstring wideDocPath(docPath);
            CoTaskMemFree(docPath);

            // Convert wide string to BSTR
            BSTR bstrDocPath = SysAllocString(wideDocPath.c_str());

            // Convert BSTR to UTF-8 string
            std::string utf8DocPath = _com_util::ConvertBSTRToString(bstrDocPath);

            // Add to paths map
            paths[flutter::EncodableValue("document")] = flutter::EncodableValue(utf8DocPath);

            // Don't forget to free the allocated BSTR
            SysFreeString(bstrDocPath);
        }

        // Cache Path (LocalAppData)
        PWSTR cachePath;
        if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, NULL, &cachePath)))
        {
            std::wstring wideCachePath(cachePath);
            CoTaskMemFree(cachePath);

            // Calculate application-specific subdirectory within LocalAppData
            std::wstring appSpecificCachePath = getAppSpecificSubdirectory(wideCachePath.c_str(), L"OnChainBridge");

            // Convert wide string to BSTR
            BSTR bstrAppSpecificCachePath = SysAllocString(appSpecificCachePath.c_str());

            // Convert BSTR to UTF-8 string
            std::string utf8AppSpecificCachePath = _com_util::ConvertBSTRToString(bstrAppSpecificCachePath);

            // Add to paths map
            paths[flutter::EncodableValue("cache")] = flutter::EncodableValue(utf8AppSpecificCachePath);

            // Don't forget to free the allocated BSTR
            SysFreeString(bstrAppSpecificCachePath);
        }

        // App Support Path (RoamingAppData)
        PWSTR appSupportPath;
        if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, NULL, &appSupportPath)))
        {
            std::wstring wideAppSupportPath(appSupportPath);
            CoTaskMemFree(appSupportPath);

            // Calculate application-specific subdirectory within RoamingAppData
            std::wstring appSpecificSupportPath = getAppSpecificSubdirectory(wideAppSupportPath.c_str(), L"OnChainBridge");

            // Convert wide string to BSTR
            BSTR bstrAppSpecificSupportPath = SysAllocString(appSpecificSupportPath.c_str());

            // Convert BSTR to UTF-8 string
            std::string utf8AppSpecificSupportPath = _com_util::ConvertBSTRToString(bstrAppSpecificSupportPath);

            // Add to paths map
            paths[flutter::EncodableValue("support")] = flutter::EncodableValue(utf8AppSpecificSupportPath);

            // Don't forget to free the allocated BSTR
            SysFreeString(bstrAppSpecificSupportPath);
        }

        return paths;
    }
    static std::wstring utf8_to_wstring(const std::string &str)
    {
        if (str.empty())
            return L"";
        int size_needed = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, nullptr, 0);
        std::wstring wstr(size_needed, 0);
        MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, &wstr[0], size_needed);
        if (!wstr.empty() && wstr.back() == L'\0')
            wstr.pop_back();
        return wstr;
    }
    static std::optional<std::string> pick_file(const std::optional<std::string> &extension,
                                                const std::optional<std::string> &mime_type)
    {
        IFileOpenDialog *pFileOpen = nullptr;
        HRESULT hr = CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_ALL,
                                      IID_IFileOpenDialog, reinterpret_cast<void **>(&pFileOpen));
        if (FAILED(hr))
            return std::nullopt;

        // Convert extension to wide string
        std::wstring wext = L"*.*";
        if (extension.has_value())
            wext = utf8_to_wstring(extension.value());

        // Convert mime_type to wide string
        std::wstring type = L"File";
        if (mime_type.has_value() && !mime_type->empty())
            type = utf8_to_wstring(mime_type.value());

        // Keep these alive while calling SetFileTypes
        COMDLG_FILTERSPEC filterSpec[1];
        filterSpec[0].pszName = type.c_str(); // safe, type is local variable
        filterSpec[0].pszSpec = wext.c_str(); // safe, wext is local variable

        pFileOpen->SetFileTypes(1, filterSpec);

        hr = pFileOpen->Show(nullptr);
        if (SUCCEEDED(hr))
        {
            IShellItem *pItem = nullptr;
            if (SUCCEEDED(pFileOpen->GetResult(&pItem)))
            {
                PWSTR pszFilePath = nullptr;
                if (SUCCEEDED(pItem->GetDisplayName(SIGDN_FILESYSPATH, &pszFilePath)))
                {
                    int size_needed = WideCharToMultiByte(CP_UTF8, 0, pszFilePath, -1, nullptr, 0, nullptr, nullptr);
                    std::string result(size_needed, 0);
                    WideCharToMultiByte(CP_UTF8, 0, pszFilePath, -1, &result[0], size_needed, nullptr, nullptr);

                    CoTaskMemFree(pszFilePath);
                    pItem->Release();
                    pFileOpen->Release();

                    if (!result.empty() && result.back() == '\0')
                        result.pop_back();
                    return result;
                }
                pItem->Release();
            }
        }

        pFileOpen->Release();
        return std::nullopt;
    }

    static bool save_file(const std::string &sourceFilePath,
                          const std::string &defaultName,
                          const std::string &extension,
                          const std::string &mimeType)
    {
        if (extension.empty())
            return false;
        IFileSaveDialog *pFileSave = nullptr;
        HRESULT hr = CoCreateInstance(CLSID_FileSaveDialog, nullptr, CLSCTX_ALL,
                                      IID_IFileSaveDialog, reinterpret_cast<void **>(&pFileSave));
        if (FAILED(hr))
            return false;

        std::wstring wDefaultName = utf8_to_wstring(defaultName);
        std::wstring wExtension = utf8_to_wstring(extension);
        std::wstring type = L"File";
        if (!mimeType.empty())
            type = utf8_to_wstring(mimeType);

        if (!wDefaultName.empty())
            pFileSave->SetFileName(wDefaultName.c_str());
        pFileSave->SetDefaultExtension(wExtension.c_str());
        std::wstring spec = wExtension;

        // Ensure the spec starts with "*." for the filter
        if (spec[0] != L'*')
        {
            if (spec[0] == L'.')
                spec = L"*" + spec;
            else
                spec = L"*." + spec;
        }

        COMDLG_FILTERSPEC filterSpec[1];
        filterSpec[0].pszName = type.c_str();
        filterSpec[0].pszSpec = spec.c_str();
        pFileSave->SetFileTypes(1, filterSpec);

        hr = pFileSave->Show(nullptr);
        if (SUCCEEDED(hr))
        {
            IShellItem *pItem = nullptr;
            if (SUCCEEDED(pFileSave->GetResult(&pItem)))
            {
                PWSTR pszFilePath = nullptr;
                if (SUCCEEDED(pItem->GetDisplayName(SIGDN_FILESYSPATH, &pszFilePath)))
                {
                    // Convert wchar_t* -> std::string (UTF-8)
                    int size_needed = WideCharToMultiByte(CP_UTF8, 0, pszFilePath, -1, nullptr, 0, nullptr, nullptr);
                    std::string destPath(size_needed, 0);
                    WideCharToMultiByte(CP_UTF8, 0, pszFilePath, -1, &destPath[0], size_needed, nullptr, nullptr);
                    if (!destPath.empty() && destPath.back() == '\0')
                        destPath.pop_back();

                    // Copy file
                    std::ifstream src(sourceFilePath, std::ios::binary);
                    std::ofstream dst(destPath, std::ios::binary);
                    bool success = src && dst && (dst << src.rdbuf());

                    CoTaskMemFree(pszFilePath);
                    pItem->Release();
                    pFileSave->Release();
                    return success;
                }
                pItem->Release();
            }
        }

        pFileSave->Release();
        return false; // cancelled or failed
    }
};
