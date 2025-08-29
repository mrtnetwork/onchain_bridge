#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
class OnChainBridgeUtils
{
public:
    OnChainBridgeUtils();
    bool launch_url(const char *url);
    FlMethodResponse *handle_utils_calls(const gchar *method, FlValue *data);
};

// Constructor: Initialize the schema
OnChainBridgeUtils::OnChainBridgeUtils()
{
}

bool OnChainBridgeUtils::launch_url(const char *url)

{
    if (!url)
        return -1;

    pid_t pid = fork();
    if (pid == 0)
    {
        // Child process: execute xdg-open
        execlp("xdg-open", "xdg-open", url, (char *)NULL);

        // If execlp fails
        perror("execlp");
        exit(1);
    }
    else if (pid < 0)
    {
        // Fork failed
        perror("fork");
        return false;
    }
    return true;
}

FlMethodResponse *OnChainBridgeUtils::handle_utils_calls(const gchar *method, FlValue *data)
{

    if (strcmp(method, "lunch_uri") == 0)
    {
        FlValue *uri = fl_value_lookup_string(data, "uri");
        if (uri != nullptr &&
            fl_value_get_type(uri) == FL_VALUE_TYPE_STRING)
        {
            const gchar *string_uri = fl_value_get_string(uri);
            // const gchar *string_value = fl_value_get_string(value);
            bool success = launch_url(string_uri);
            g_autoptr(FlValue) result = fl_value_new_bool(success);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }

    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENT",          // Error code
        "Some key or value missing", // Error message
        nullptr                      // No additional error details
        ));
}