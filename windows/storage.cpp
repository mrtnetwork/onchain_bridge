#include "include/storage.hpp"
#include "include/utils.hpp" // Make sure ELEMENT_PREFERENCES_KEY_PREFIX is defined here
#include <windows.h>
#include <string>
#include <atlconv.h> // For CA2W
const int ELEMENT_PREFERENCES_KEY_PREFIX_LENGTH = (sizeof SECURE_STORAGE_KEY_PREFIX) - 1;
const std::string ELEMENT_PREFERENCES_KEY_PREFIX = SECURE_STORAGE_KEY_PREFIX;
const std::string ELEMENT_PREFERENCES_KEY_PREFIX_WITH_WILDCARD = ELEMENT_PREFERENCES_KEY_PREFIX + '*';
const CA2W CREDENTIAL_FILTER(ELEMENT_PREFERENCES_KEY_PREFIX_WITH_WILDCARD.c_str());
static inline void rtrim(std::wstring &s)
{
    s.erase(std::find_if(s.rbegin(), s.rend(), [](wchar_t ch)
                         { return !std::isspace(ch); })
                .base(),
            s.end());
}

static inline std::optional<std::vector<std::string>> GetListValueKey(const flutter::EncodableMap *args)
{
    // Retrieve the list of strings using the key "key"
    auto list = OnChainWindowsUtils::GetStringListArg("keys", args);
    if (list.has_value())
    {
        // If the list is found, return it prefixed by ELEMENT_PREFERENCES_KEY_PREFIX
        std::vector<std::string> prefixedList;
        prefixedList.reserve(list->size());

        for (const std::string &value : list.value())
        {
            prefixedList.push_back(ELEMENT_PREFERENCES_KEY_PREFIX + value);
        }

        return prefixedList;
    }

    // If not found, return std::nullopt
    return std::nullopt;
}
static inline std::optional<std::string> GetValueKey(const flutter::EncodableMap *args)
{
    auto key = OnChainWindowsUtils::GetStringArg("key", args);
    if (key.has_value())
        return ELEMENT_PREFERENCES_KEY_PREFIX + key.value();
    return std::nullopt;
}
// Storage::Storage() {}
std::string Storage::RemoveKeyPrefix(const std::string &key)
{
    return key.substr(ELEMENT_PREFERENCES_KEY_PREFIX_LENGTH);
}

bool Storage::PathExists(const std::wstring &path)
{
    struct _stat info;
    if (_wstat(path.c_str(), &info) != 0)
    {
        return false;
    }
    return (info.st_mode & _S_IFDIR) != 0;
}
bool Storage::MakePath(const std::wstring &path)
{
    int ret = _wmkdir(path.c_str());
    if (ret == 0)
    {
        return true;
    }
    switch (errno)
    {
    case ENOENT:
    {
        size_t pos = path.find_last_of('/');
        if (pos == std::wstring::npos)
            pos = path.find_last_of('\\');
        if (pos == std::wstring::npos)
            return false;
        if (!MakePath(path.substr(0, pos)))
            return false;
    }
        return 0 == _wmkdir(path.c_str());
    case EEXIST:
        return PathExists(path);
    default:
        return false;
    }
}

std::wstring Storage::SanitizeDirString(std::wstring string)
{
    std::wstring sanitizedString = std::regex_replace(string, std::wregex(L"[<>:\"/\\\\|?*]"), L"_");
    rtrim(sanitizedString);
    sanitizedString = std::regex_replace(sanitizedString, std::wregex(L"[.]+$"), L"");
    return sanitizedString;
}

DWORD Storage::GetApplicationSupportPath(std::wstring &path)
{
    std::wstring companyName;
    std::wstring productName;
    TCHAR nameBuffer[MAX_PATH + 1]{};
    char *infoBuffer;
    DWORD versionInfoSize;
    DWORD resVal;
    UINT queryLen;
    LPVOID queryVal;
    LPWSTR appdataPath;
    std::wostringstream stream;

    SHGetKnownFolderPath(FOLDERID_RoamingAppData, KF_FLAG_DEFAULT, NULL, &appdataPath);

    if (nameBuffer == NULL)
    {
        return ERROR_OUTOFMEMORY;
    }

    resVal = GetModuleFileName(NULL, nameBuffer, MAX_PATH);
    if (resVal == 0)
    {
        return GetLastError();
    }

    versionInfoSize = GetFileVersionInfoSize(nameBuffer, NULL);
    if (versionInfoSize != 0)
    {
        infoBuffer = (char *)calloc(versionInfoSize, sizeof(char));
        if (infoBuffer == NULL)
        {
            return ERROR_OUTOFMEMORY;
        }
        if (GetFileVersionInfo(nameBuffer, 0, versionInfoSize, infoBuffer) == 0)
        {
            free(infoBuffer);
            infoBuffer = NULL;
        }
        else
        {

            if (VerQueryValue(infoBuffer, TEXT("\\StringFileInfo\\040904e4\\CompanyName"), &queryVal, &queryLen) != 0)
            {
                companyName = SanitizeDirString(std::wstring((const TCHAR *)queryVal));
            }
            if (VerQueryValue(infoBuffer, TEXT("\\StringFileInfo\\040904e4\\ProductName"), &queryVal, &queryLen) != 0)
            {
                productName = SanitizeDirString(std::wstring((const TCHAR *)queryVal));
            }
        }
        stream << appdataPath << "\\" << companyName << "\\" << productName;
        path = stream.str();
    }
    else
    {
        return GetLastError();
    }
    return ERROR_SUCCESS;
}
PBYTE Storage::GetEncryptionKey()
{
    const size_t KEY_SIZE = 16;
    DWORD credError = 0;
    PBYTE AesKey;
    PCREDENTIALW pcred;
    CA2W target_name(("key_" + ELEMENT_PREFERENCES_KEY_PREFIX).c_str());

    AesKey = (PBYTE)HeapAlloc(GetProcessHeap(), 0, KEY_SIZE);
    if (NULL == AesKey)
    {
        return NULL;
    }

    bool ok = CredReadW(target_name.m_psz, CRED_TYPE_GENERIC, 0, &pcred);
    if (ok)
    {
        if (pcred->CredentialBlobSize != KEY_SIZE)
        {
            CredFree(pcred);
            CredDeleteW(target_name.m_psz, CRED_TYPE_GENERIC, 0);
            goto NewKey;
        }
        memcpy(AesKey, pcred->CredentialBlob, KEY_SIZE);
        CredFree(pcred);
        return AesKey;
    }
    credError = GetLastError();
    if (credError != ERROR_NOT_FOUND)
    {
        return NULL;
    }
NewKey:
    if (BCryptGenRandom(NULL, AesKey, KEY_SIZE, BCRYPT_USE_SYSTEM_PREFERRED_RNG) != ERROR_SUCCESS)
    {
        return NULL;
    }
    CREDENTIALW cred = {0};
    cred.Type = CRED_TYPE_GENERIC;
    cred.TargetName = target_name.m_psz;
    cred.CredentialBlobSize = KEY_SIZE;
    cred.CredentialBlob = AesKey;
    cred.Persist = CRED_PERSIST_LOCAL_MACHINE;

    ok = CredWriteW(&cred, 0);
    if (!ok)
    {
        std::cerr << "Failed to write encryption key" << std::endl;
        return NULL;
    }
    return AesKey;
}
std::string Storage::NtStatusToString(const CHAR *operation, NTSTATUS status)
{
    std::ostringstream oss;
    oss << operation << ", 0x" << std::hex << status;

    switch (status)
    {
    case 0xc0000000:
        oss << " (STATUS_SUCCESS)";
        break;
    case 0xC0000008:
        oss << " (STATUS_INVALID_HANDLE)";
        break;
    case 0xc000000d:
        oss << " (STATUS_INVALID_PARAMETER)";
        break;
    case 0xc00000bb:
        oss << " (STATUS_NOT_SUPPORTED)";
        break;
    case 0xC0000225:
        oss << " (STATUS_NOT_FOUND)";
        break;
    }
    return oss.str();
}

void Storage::Write(const std::string &key, const std::string &val)
{
    // The recommended size for AES-GCM IV is 12 bytes
    const DWORD NONCE_SIZE = 12;
    const DWORD KEY_SIZE = 16;

    NTSTATUS status;
    BCRYPT_ALG_HANDLE algo = NULL;
    BCRYPT_KEY_HANDLE keyHandle = NULL;
    DWORD bytesWritten = 0,
          ciphertextSize = 0;
    PBYTE ciphertext = NULL,
          iv = (PBYTE)HeapAlloc(GetProcessHeap(), 0, NONCE_SIZE),
          encryptionKey = GetEncryptionKey();
    BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO authInfo{};
    BCRYPT_AUTH_TAG_LENGTHS_STRUCT authTagLengths{};
    std::basic_ofstream<BYTE> fs;
    std::wstring appSupportPath;
    std::string error;

    if (iv == NULL)
    {
        error = "IV HeapAlloc Failed";
        goto err;
    }
    if (encryptionKey == NULL)
    {
        error = "encryptionKey is NULL";
        goto err;
    }
    status = BCryptOpenAlgorithmProvider(&algo, BCRYPT_AES_ALGORITHM, NULL, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        error = NtStatusToString("BCryptOpenAlgorithmProvider", status);
        goto err;
    }
    status = BCryptSetProperty(algo, BCRYPT_CHAINING_MODE, (PUCHAR)BCRYPT_CHAIN_MODE_GCM, sizeof(BCRYPT_CHAIN_MODE_GCM), 0);
    if (!BCRYPT_SUCCESS(status))
    {
        error = NtStatusToString("BCryptSetProperty", status);
        goto err;
    }
    status = BCryptGetProperty(algo, BCRYPT_AUTH_TAG_LENGTH, (PBYTE)&authTagLengths, sizeof(BCRYPT_AUTH_TAG_LENGTHS_STRUCT), &bytesWritten, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        error = NtStatusToString("BCryptGetProperty", status);
        goto err;
    }
    BCRYPT_INIT_AUTH_MODE_INFO(authInfo);
    authInfo.pbNonce = (PUCHAR)HeapAlloc(GetProcessHeap(), 0, NONCE_SIZE);
    if (authInfo.pbNonce == NULL)
    {
        error = "pbNonce HeapAlloc Failed";
        goto err;
    }
    authInfo.cbNonce = NONCE_SIZE;
    status = BCryptGenRandom(NULL, iv, authInfo.cbNonce, BCRYPT_USE_SYSTEM_PREFERRED_RNG);
    if (!BCRYPT_SUCCESS(status))
    {
        error = NtStatusToString("BCryptGenRandom", status);
        goto err;
    }
    // copy the original IV into the authInfo, we can't write the IV directly into the authInfo because it will change after calling BCryptEncrypt and we still need to write the IV to file
    memcpy(authInfo.pbNonce, iv, authInfo.cbNonce);
    // We do not use additional authenticated data
    authInfo.pbAuthData = NULL;
    authInfo.cbAuthData = 0;
    // Make space for the authentication tag
    authInfo.pbTag = (PUCHAR)HeapAlloc(GetProcessHeap(), 0, authTagLengths.dwMaxLength);
    if (authInfo.pbTag == NULL)
    {
        error = "pbTag HeapAlloc Failed";
        goto err;
    }
    authInfo.cbTag = authTagLengths.dwMaxLength;
    status = BCryptGenerateSymmetricKey(algo, &keyHandle, NULL, 0, encryptionKey, KEY_SIZE, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        error = NtStatusToString("BCryptGenerateSymmetricKey", status);
        goto err;
    }
    // First call to BCryptEncrypt to get size of ciphertext
    status = BCryptEncrypt(keyHandle, (PUCHAR)val.c_str(), (ULONG)val.length() + 1, (PVOID)&authInfo, NULL, 0, NULL, 0, &bytesWritten, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        error = NtStatusToString("BCryptEncrypt1", status);
        goto err;
    }
    ciphertextSize = bytesWritten;
    ciphertext = (PBYTE)HeapAlloc(GetProcessHeap(), 0, ciphertextSize);
    if (ciphertext == NULL)
    {
        error = "CipherText HeapAlloc failed";
        goto err;
    }
    // Actual encryption
    status = BCryptEncrypt(keyHandle, (PUCHAR)val.c_str(), (ULONG)val.length() + 1, (PVOID)&authInfo, NULL, 0, ciphertext, ciphertextSize, &bytesWritten, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        error = NtStatusToString("BCryptEncrypt2", status);
        goto err;
    }
    GetApplicationSupportPath(appSupportPath);
    if (!PathExists(appSupportPath))
    {
        MakePath(appSupportPath);
    }
    fs = std::basic_ofstream<BYTE>(appSupportPath + L"\\" + std::wstring(key.begin(), key.end()) + L".secure", std::ios::binary | std::ios::trunc);
    if (!fs)
    {
        error = "Failed to open output stream";
        goto err;
    }
    fs.write(iv, NONCE_SIZE);
    fs.write(authInfo.pbTag, authInfo.cbTag);
    fs.write(ciphertext, ciphertextSize);
    fs.close();
    HeapFree(GetProcessHeap(), 0, iv);
    HeapFree(GetProcessHeap(), 0, encryptionKey);
    HeapFree(GetProcessHeap(), 0, authInfo.pbNonce);
    HeapFree(GetProcessHeap(), 0, authInfo.pbTag);
    HeapFree(GetProcessHeap(), 0, ciphertext);
    return;
err:
    if (iv)
    {
        HeapFree(GetProcessHeap(), 0, iv);
    }
    if (encryptionKey)
    {
        HeapFree(GetProcessHeap(), 0, encryptionKey);
    }
    if (authInfo.pbNonce)
    {
        HeapFree(GetProcessHeap(), 0, authInfo.pbNonce);
    }
    if (authInfo.pbTag)
    {
        HeapFree(GetProcessHeap(), 0, authInfo.pbTag);
    }
    if (ciphertext)
    {
        HeapFree(GetProcessHeap(), 0, ciphertext);
    }
    throw std::runtime_error(error);
}

std::optional<std::string> Storage::Read(const std::string &key)
{
    const DWORD NONCE_SIZE = 12;
    const DWORD KEY_SIZE = 16;

    NTSTATUS status;
    BCRYPT_ALG_HANDLE algo = NULL;
    BCRYPT_KEY_HANDLE keyHandle = NULL;
    BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO authInfo{};
    BCRYPT_AUTH_TAG_LENGTHS_STRUCT authTagLengths{};

    PBYTE encryptionKey = GetEncryptionKey(),
          ciphertext = NULL,
          fileBuffer = NULL,
          plaintext = NULL;
    DWORD plaintextSize = 0,
          bytesWritten = 0,
          ciphertextSize = 0;
    std::wstring appSupportPath;
    std::basic_ifstream<BYTE> fs;
    std::streampos fileSize;
    std::optional<std::string> returnVal = std::nullopt;

    if (encryptionKey == NULL)
    {
        std::cerr << "encryptionKey is NULL" << std::endl;
        goto cleanup;
    }
    GetApplicationSupportPath(appSupportPath);
    if (!PathExists(appSupportPath))
    {
        MakePath(appSupportPath);
    }
    // Read full file into a buffer
    fs = std::basic_ifstream<BYTE>(appSupportPath + L"\\" + std::wstring(key.begin(), key.end()) + L".secure", std::ios::binary);
    if (!fs.good())
    {
        // Backwards comp.
        PCREDENTIALW pcred;
        CA2W target_name(key.c_str());
        bool ok = CredReadW(target_name.m_psz, CRED_TYPE_GENERIC, 0, &pcred);
        if (ok)
        {
            auto val = std::string((char *)pcred->CredentialBlob);
            CredFree(pcred);
            returnVal = val;
        }
        goto cleanup;
    }
    fs.unsetf(std::ios::skipws);
    fs.seekg(0, std::ios::end);
    fileSize = fs.tellg();
    fs.seekg(0, std::ios::beg);
    fileBuffer = (PBYTE)HeapAlloc(GetProcessHeap(), 0, fileSize);
    if (NULL == fileBuffer)
    {
        std::cerr << "fileBuffer HeapAlloc failed" << std::endl;
        goto cleanup;
    }
    fs.read(fileBuffer, fileSize);
    fs.close();

    status = BCryptOpenAlgorithmProvider(&algo, BCRYPT_AES_ALGORITHM, NULL, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        std::cerr << NtStatusToString("BCryptOpenAlgorithmProvider", status) << std::endl;
        goto cleanup;
    }
    status = BCryptSetProperty(algo, BCRYPT_CHAINING_MODE, (PUCHAR)BCRYPT_CHAIN_MODE_GCM, sizeof(BCRYPT_CHAIN_MODE_GCM), 0);
    if (!BCRYPT_SUCCESS(status))
    {
        std::cerr << NtStatusToString("BCryptOpenAlgorithmProvider", status) << std::endl;
        goto cleanup;
    }
    status = BCryptGetProperty(algo, BCRYPT_AUTH_TAG_LENGTH, (PBYTE)&authTagLengths, sizeof(BCRYPT_AUTH_TAG_LENGTHS_STRUCT), &bytesWritten, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        std::cerr << NtStatusToString("BCryptGetProperty", status) << std::endl;
        goto cleanup;
    }

    BCRYPT_INIT_AUTH_MODE_INFO(authInfo);
    authInfo.pbNonce = (PUCHAR)HeapAlloc(GetProcessHeap(), 0, NONCE_SIZE);
    if (authInfo.pbNonce == NULL)
    {
        std::cerr << "pbNonce HeapAlloc Failed" << std::endl;
        goto cleanup;
    }
    authInfo.cbNonce = NONCE_SIZE;
    // Check if file is at least long enough for iv and authentication tag
    if (fileSize <= static_cast<long long>(NONCE_SIZE) + authTagLengths.dwMaxLength)
    {
        std::cerr << "File is too small" << std::endl;
        goto cleanup;
    }
    authInfo.pbTag = (PUCHAR)HeapAlloc(GetProcessHeap(), 0, authTagLengths.dwMaxLength);
    if (authInfo.pbTag == NULL)
    {
        std::cerr << "pbTag HeapAlloc Failed" << std::endl;
        goto cleanup;
    }
    ciphertextSize = (DWORD)fileSize - NONCE_SIZE - authTagLengths.dwMaxLength;
    ciphertext = (PBYTE)HeapAlloc(GetProcessHeap(), 0, ciphertextSize);
    if (ciphertext == NULL)
    {
        std::cerr << "ciphertext HeapAlloc failed" << std::endl;
        goto cleanup;
    }
    // Copy different parts needed for decryption from filebuffer
#pragma warning(push)
#pragma warning(disable : 6385)
    memcpy(authInfo.pbNonce, fileBuffer, NONCE_SIZE);
#pragma warning(pop)
    memcpy(authInfo.pbTag, &fileBuffer[NONCE_SIZE], authTagLengths.dwMaxLength);
    memcpy(ciphertext, &fileBuffer[NONCE_SIZE + authTagLengths.dwMaxLength], ciphertextSize);
    authInfo.cbTag = authTagLengths.dwMaxLength;

    status = BCryptGenerateSymmetricKey(algo, &keyHandle, NULL, 0, encryptionKey, KEY_SIZE, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        std::cerr << NtStatusToString("BCryptGenerateSymmetricKey", status) << std::endl;
        goto cleanup;
    }
    // First call is to determine size of plaintext
    status = BCryptDecrypt(keyHandle, ciphertext, ciphertextSize, (PVOID)&authInfo, NULL, 0, NULL, 0, &bytesWritten, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        std::cerr << NtStatusToString("BCryptDecrypt1", status) << std::endl;
        goto cleanup;
    }
    plaintextSize = bytesWritten;
    plaintext = (PBYTE)HeapAlloc(GetProcessHeap(), 0, plaintextSize);
    if (NULL == plaintext)
    {
        std::cerr << "plaintext HeapAlloc failed" << std::endl;
        goto cleanup;
    }
    // Actuual decryption
    status = BCryptDecrypt(keyHandle, ciphertext, ciphertextSize, (PVOID)&authInfo, NULL, 0, plaintext, plaintextSize, &bytesWritten, 0);
    if (!BCRYPT_SUCCESS(status))
    {
        std::cerr << NtStatusToString("BCryptDecrypt2", status) << std::endl;
        goto cleanup;
    }
    returnVal = (char *)plaintext;
cleanup:
    if (encryptionKey)
    {
        HeapFree(GetProcessHeap(), 0, encryptionKey);
    }
    if (ciphertext)
    {
        HeapFree(GetProcessHeap(), 0, ciphertext);
    }
    if (plaintext)
    {
        HeapFree(GetProcessHeap(), 0, plaintext);
    }
    if (fileBuffer)
    {
        HeapFree(GetProcessHeap(), 0, fileBuffer);
    }
    if (authInfo.pbNonce)
    {
        HeapFree(GetProcessHeap(), 0, authInfo.pbNonce);
    }
    if (authInfo.pbTag)
    {
        HeapFree(GetProcessHeap(), 0, authInfo.pbTag);
    }
    return returnVal;
}

flutter::EncodableMap Storage::ReadAll()
{
    WIN32_FIND_DATA searchRes;
    HANDLE hFile;
    std::wstring appSupportPath;

    GetApplicationSupportPath(appSupportPath);
    if (!PathExists(appSupportPath))
    {
        MakePath(appSupportPath);
    }
    hFile = FindFirstFile((appSupportPath + L"\\*.secure").c_str(), &searchRes);
    if (hFile == INVALID_HANDLE_VALUE)
    {
        return flutter::EncodableMap();
    }

    flutter::EncodableMap creds;

    do
    {
        std::wstring fileName(searchRes.cFileName);
        size_t pos = fileName.find(L".secure");
        fileName.erase(pos, 7);
        char *out = new char[fileName.length() + 1];
        size_t charsConverted = 0;
        wcstombs_s(&charsConverted, out, fileName.length() + 1, fileName.c_str(), fileName.length() + 1);
        std::optional<std::string> val = Read(out);
        auto key = RemoveKeyPrefix(out);
        if (val.has_value())
        {
            creds[key] = val.value();
            continue;
        }
    } while (FindNextFile(hFile, &searchRes) != 0);

    // Backwards comp.
    PCREDENTIALW *pcreds;
    DWORD cred_count = 0;
    bool ok = CredEnumerateW(CREDENTIAL_FILTER.m_psz, 0, &cred_count, &pcreds);
    if (!ok)
    {
        return creds;
    }
    for (DWORD i = 0; i < cred_count; i++)
    {
        auto pcred = pcreds[i];
        std::string target_name = std::string(CW2A(pcred->TargetName));
        auto val = std::string((char *)pcred->CredentialBlob);
        auto key = RemoveKeyPrefix(target_name);
        // If the key exists then data was already read from a file, which implies that the data read from the credential system is outdated
        if (creds.find(key) == creds.end())
        {
            creds[key] = val;
        }
    }

    CredFree(pcreds);
    return creds;
}

flutter::EncodableList Storage::ReadKeys(const std::string &prefix)
{
    WIN32_FIND_DATA searchRes;
    HANDLE hFile;
    std::wstring appSupportPath;

    GetApplicationSupportPath(appSupportPath);
    if (!PathExists(appSupportPath))
    {
        MakePath(appSupportPath);
    }
    hFile = FindFirstFile((appSupportPath + L"\\*.secure").c_str(), &searchRes);
    if (hFile == INVALID_HANDLE_VALUE)
    {
        return flutter::EncodableList();
    }

    flutter::EncodableList keys;

    do
    {
        std::wstring fileName(searchRes.cFileName);
        size_t pos = fileName.find(L".secure");
        fileName.erase(pos, 7);
        char *out = new char[fileName.length() + 1];
        size_t charsConverted = 0;
        wcstombs_s(&charsConverted, out, fileName.length() + 1, fileName.c_str(), fileName.length() + 1);
        auto key = RemoveKeyPrefix(out);
        if (prefix.empty() || key.find(prefix) == 0) // Check if the key starts with the prefix or if no prefix is provided.
        {
            keys.push_back(key); // Add the key to the list
        }
        delete[] out;
    } while (FindNextFile(hFile, &searchRes) != 0);

    // Backwards comp.
    PCREDENTIALW *pcreds;
    DWORD cred_count = 0;
    bool ok = CredEnumerateW(CREDENTIAL_FILTER.m_psz, 0, &cred_count, &pcreds);
    if (!ok)
    {
        return keys;
    }
    for (DWORD i = 0; i < cred_count; i++)
    {
        auto pcred = pcreds[i];
        std::string target_name = std::string(CW2A(pcred->TargetName));
        auto key = RemoveKeyPrefix(target_name);
        if (prefix.empty() || key.find(prefix) == 0)
        {
            keys.push_back(key);
        }
    }

    CredFree(pcreds);
    return keys;
}

void Storage::Delete(const std::string &key)
{
    std::wstring appSupportPath;
    GetApplicationSupportPath(appSupportPath);
    auto wstr = std::wstring(key.begin(), key.end());
    BOOL ok = DeleteFile((appSupportPath + L"\\" + wstr + L".secure").c_str());
    if (!ok)
    {
        DWORD error = GetLastError();
        if (error != ERROR_FILE_NOT_FOUND && error != ERROR_PATH_NOT_FOUND)
        {
            throw error;
        }
    }

    // Backwards comp.
    ok = CredDeleteW(wstr.c_str(), CRED_TYPE_GENERIC, 0);
    if (!ok)
    {
        auto error = GetLastError();

        // Silently ignore if we try to delete a key that doesn't exist
        if (error == ERROR_NOT_FOUND)
            return;

        throw error;
    }
}

void Storage::DeleteAll()
{

    WIN32_FIND_DATA searchRes;
    HANDLE hFile;
    std::wstring appSupportPath;

    GetApplicationSupportPath(appSupportPath);
    if (!PathExists(appSupportPath))
    {
        MakePath(appSupportPath);
    }
    hFile = FindFirstFile((appSupportPath + L"\\*.secure").c_str(), &searchRes);
    if (hFile == INVALID_HANDLE_VALUE)
    {
        return;
    }
    do
    {
        std::wstring fileName(searchRes.cFileName);
        BOOL ok = DeleteFile((appSupportPath + L"\\" + fileName).c_str());
        if (!ok)
        {
            DWORD error = GetLastError();
            if (error != ERROR_FILE_NOT_FOUND)
            {
                throw error;
            }
        }
    } while (FindNextFile(hFile, &searchRes) != 0);

    // Backwards comp.
    PCREDENTIALW *pcreds;
    DWORD cred_count = 0;

    bool read_ok = CredEnumerateW(CREDENTIAL_FILTER.m_psz, 0, &cred_count, &pcreds);
    if (!read_ok)
    {
        auto error = GetLastError();
        if (error == ERROR_NOT_FOUND)
            // No credentials to delete
            return;
        throw error;
    }

    for (DWORD i = 0; i < cred_count; i++)
    {
        auto pcred = pcreds[i];
        auto target_name = pcred->TargetName;

        bool delete_ok = CredDeleteW(target_name, CRED_TYPE_GENERIC, 0);
        if (!delete_ok)
        {
            throw GetLastError();
        }
    }

    CredFree(pcreds);
}

bool Storage::ContainsKey(const std::string &key)
{
    std::wstring appSupportPath;
    GetApplicationSupportPath(appSupportPath);
    std::wstring wstr = std::wstring(key.begin(), key.end());
    if (INVALID_FILE_ATTRIBUTES == GetFileAttributes((appSupportPath + L"\\" + wstr + L".secure").c_str()))
    {
        // Backwards comp.
        PCREDENTIALW pcred;
        CA2W target_name(key.c_str());

        bool ok = CredReadW(target_name.m_psz, CRED_TYPE_GENERIC, 0, &pcred);
        if (ok)
            return true;

        auto error = GetLastError();
        if (error == ERROR_NOT_FOUND)
            return false;
        throw error;
    }
    return true;
}

std::optional<flutter::EncodableValue> Storage::HandleStorageCall(const std::string &method, const flutter::EncodableMap *args)
{
    std::wstring path;
    if (method == "secureStorage")
    {
        if (GetApplicationSupportPath(path) != ERROR_SUCCESS)
        {
            return std::nullopt;
        }
        auto methodType = OnChainWindowsUtils::GetStringArg("type", args);
        if (methodType == "write")
        {
            auto key = GetValueKey(args);
            auto val = OnChainWindowsUtils::GetStringArg("value", args);
            if (key.has_value())
            {
                if (val.has_value())
                    Write(key.value(), val.value());
                else
                    Delete(key.value());
                return flutter::EncodableValue(true);
                // result->Success(true);
            }
        }
        else if (methodType == "readMultiple")
        {
            auto keys = GetListValueKey(args);
            flutter::EncodableMap creds;
            if (keys.has_value())
            {

                // Iterate through each key in the list and attempt to delete
                for (const auto &key : keys.value())
                {
                    auto val = Read(key);
                    if (val.has_value())
                    {
                        std::string correctKey = RemoveKeyPrefix(key);
                        creds[correctKey] = val.value();
                    }
                }
                return creds;
            }
        }
        else if (methodType == "read")
        {
            auto key = GetValueKey(args);
            if (key.has_value())
            {
                auto val = Read(key.value());
                if (val.has_value())
                    return flutter::EncodableValue(val.value());
                else
                    return flutter::EncodableValue(std::monostate{});
            }
        }
        else if (methodType == "readKeys")
        {
            auto key = OnChainWindowsUtils::GetStringArg("key", args);
            if (key.has_value())
            {
                auto val = ReadKeys(key.value());
                return flutter::EncodableValue(val);
            }
        }
        else if (methodType == "readAll")
        {
            auto creds = ReadAll();
            return flutter::EncodableValue(creds);
        }
        else if (methodType == "remove")
        {
            auto key = GetValueKey(args);
            if (key.has_value())
            {
                Delete(key.value());
                return flutter::EncodableValue(true);
            }
            else
            {
                return flutter::EncodableValue(false);
            }
        }
        else if (methodType == "removeMultiple")
        {
            auto keys = GetListValueKey(args);
            if (keys.has_value() && !keys->empty())
            {

                // Iterate through each key in the list and attempt to delete
                for (const auto &key : keys.value())
                {
                    Delete(key);
                }
                // Return true if all keys were successfully deleted, otherwise false
                return flutter::EncodableValue(true);
            }
            else
            {
                return flutter::EncodableValue(false);
            }
        }
        else if (methodType == "removeAll")
        {
            DeleteAll();
            return flutter::EncodableValue(true);
        }
        else if (methodType == "containsKey")
        {
            auto key = GetValueKey(args);
            if (key.has_value())
            {
                auto contains_key = ContainsKey(key.value());
                return flutter::EncodableValue(contains_key);
            }
        }
    }
    return std::nullopt;
}