// BSD 3-Clause License

// Copyright 2017 German Saprykin
// All rights reserved.

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:

// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.

// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.

// * Neither the name of the copyright holder nor the names of its
//   contributors may be used to endorse or promote products derived from
//   this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#pragma once
#include <string>
#include <windows.h>
#include <dwmapi.h>
#include <shobjidl.h>
#include <wincred.h>
#include <atlstr.h>
#include <ShlObj_core.h>
#include <sys/stat.h>
#include <errno.h>
#include <direct.h>
#include <bcrypt.h>
#include <map>
#include <memory>
#include <sstream>
#include <iostream>
#include <fstream>
#include <regex>
#include <Shellapi.h>
#include <comutil.h>
// #include <netlistmgr.h>
// #include <atlbase.h>
// #include <atlcomcli.h>
// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>
#include <flutter/encodable_value.h>
#include <optional>
#include "utils.hpp"
#include <atlconv.h> // For CA2W

extern const CA2W CREDENTIAL_FILTER;
// this string is used to filter the credential storage so that only the values written
// by this plugin shows up.
class Storage
{

public:
    std::optional<flutter::EncodableValue> HandleStorageCall(const std::string &method, const flutter::EncodableMap *args);

private:
    std::string NtStatusToString(const CHAR *operation, NTSTATUS status);

    void Write(const std::string &key, const std::string &val);
    std::optional<std::string> Read(const std::string &key);
    PBYTE GetEncryptionKey();
    flutter::EncodableMap ReadAll();
    flutter::EncodableList ReadKeys(const std::string &prefix);
    void Delete(const std::string &key);
    void DeleteAll();
    bool ContainsKey(const std::string &key);
    std::wstring SanitizeDirString(std::wstring string);
    DWORD GetApplicationSupportPath(std::wstring &path);
    bool PathExists(const std::wstring &path);
    bool MakePath(const std::wstring &path);
    std::string RemoveKeyPrefix(const std::string &key);
};
