#pragma once
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Security.Credentials.UI.h>

enum class BiometricStatusEnum
{
    available,
    notEnrolled,
    notAvailable
};

struct BiometricStatus
{
    BiometricStatusEnum value;
    BiometricStatus(BiometricStatusEnum v = BiometricStatusEnum::notAvailable) : value(v) {}
    std::string name() const
    {
        switch (value)
        {
        case BiometricStatusEnum::available:
            return "available";
        case BiometricStatusEnum::notEnrolled:
            return "notEnrolled";
        case BiometricStatusEnum::notAvailable:
            return "notAvailable";
        default:
            return "unknown";
        }
    }
};

enum class BiometricResultEnum
{
    success,
    cancelled,
    notAvailable,
    failed,
    lockedOut
};

struct BiometricResult
{
    BiometricResultEnum value;
    BiometricResult(BiometricResultEnum v = BiometricResultEnum::failed) : value(v) {}
    std::string name() const
    {
        switch (value)
        {
        case BiometricResultEnum::success:
            return "success";
        case BiometricResultEnum::cancelled:
            return "cancelled";
        case BiometricResultEnum::notAvailable:
            return "notAvailable";
        case BiometricResultEnum::failed:
            return "failed";
        case BiometricResultEnum::lockedOut:
            return "lockedOut";
        default:
            return "unknown";
        }
    }
};

class Biometric
{
public:
    using CallbackStatus = std::function<void(BiometricStatus)>;
    using CallbackResult = std::function<void(BiometricResult)>;

    static winrt::Windows::Foundation::IAsyncAction checkStatusAsync(CallbackStatus callback)
    {
        winrt::apartment_context ctx;
        co_await ctx;
        using namespace winrt::Windows::Security::Credentials::UI;
        winrt::Windows::Security::Credentials::UI::UserConsentVerifierAvailability availability =
            co_await UserConsentVerifier::CheckAvailabilityAsync();
        BiometricStatus status;
        switch (availability)
        {
        case UserConsentVerifierAvailability::DeviceBusy:
        case UserConsentVerifierAvailability::Available:
            status = BiometricStatus(BiometricStatusEnum::available);
            break;
        case UserConsentVerifierAvailability::DisabledByPolicy:
        case UserConsentVerifierAvailability::NotConfiguredForUser:
            status = BiometricStatus(BiometricStatusEnum::notEnrolled);
            break;
        default:
            status = BiometricStatus(BiometricStatusEnum::notAvailable);
        }
        if (callback)
            callback(status);
    }
    static winrt::Windows::Foundation::IAsyncAction authenticateAsync(CallbackResult callback)
    {
        winrt::apartment_context ctx;
        co_await ctx;

        using namespace winrt::Windows::Security::Credentials::UI;
        auto consentResult = co_await UserConsentVerifier::RequestVerificationAsync(L"Authenticate");
        BiometricResult result;
        switch (consentResult)
        {
        case UserConsentVerificationResult::Verified:
            result = BiometricResult(BiometricResultEnum::success);
            break;
        case UserConsentVerificationResult::NotConfiguredForUser:
        case UserConsentVerificationResult::DisabledByPolicy:
        case UserConsentVerificationResult::DeviceNotPresent:
            result = BiometricResult(BiometricResultEnum::notAvailable);
            break;
        case UserConsentVerificationResult::RetriesExhausted:
            result = BiometricResult(BiometricResultEnum::lockedOut);
            break;
        case UserConsentVerificationResult::Canceled:
            result = BiometricResult(BiometricResultEnum::cancelled);
            break;
        default:
            result = BiometricResult(BiometricResultEnum::failed);
            break;
        }

        if (callback)
            callback(result);
    }
};
