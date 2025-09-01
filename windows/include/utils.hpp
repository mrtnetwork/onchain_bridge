#pragma once

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
        auto p = args->find(param);
        if (p == args->end())
            return std::nullopt;
        return std::get<std::string>(p->second);
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
};
