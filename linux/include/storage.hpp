
#include <libsecret/secret.h>
#include "json.hpp"
#define SECRET_SCHEMA "com.mrtnetwork"
#define SECRET_VALUE "com.mrtnetwork.OnChainBridge"
#define SECRET_SCHEME_LABLE "default"
#define STORAGE_TYPE_WRITE "write"
#define STORAGE_TYPE_REMOVE "remove"
#define STORAGE_TYPE_REMOVE_ALL "removeAll"
#define STORAGE_TYPE_READ "read"
#define STORAGE_TYPE_CONTAINS_KEY "containsKey"
#define STORAGE_TYPE_READ_ALL "readAll"
#define STORAGE_TYPE_READ_KEYS "readKeys"
#define STORAGE_TYPE_READ_MULTIPLE "readMultiple"
#define STORAGE_TYPE_REMOVE_MULTIPLE "removeMultiple"

class Storage
{
public:
    Storage();
    FlMethodResponse *hanadle_storage_call(FlValue *data);
    void setup();
    nlohmann::json read_json();
    bool store_json(nlohmann::json data);
    std::string read_key(const char *key);
    bool write_key_pair(const char *key, const char *value);
    bool remove_key(const char *key);
    bool remove_all();
    bool remove_multiple_keys(const std::vector<std::string> &keys);
    std::map<std::string, std::string> read_all();
    std::vector<std::string> read_keys(const char *prefix = "");
    std::map<std::string, std::string> read_multiple_items(const std::vector<std::string> &keys);

private:
    SecretSchema schema;
    GHashTable *table;
};
// Constructor: Initialize the schema
Storage::Storage()
{
    // Define the schema for storing the secret
    schema = {SECRET_SCHEME_LABLE,
              SECRET_SCHEMA_NONE,
              {{"wallet_id", SECRET_SCHEMA_ATTRIBUTE_STRING}}};
    table = g_hash_table_new_full(g_str_hash, NULL, g_free, g_free);
}

void Storage::setup()
{
    // g_autofree gchar *wId = g_strdup(SECRET_VALUE);
    g_hash_table_insert(table, g_strdup("wallet_id"), g_strdup(SECRET_VALUE));
}

nlohmann::json Storage::read_json()
{
    nlohmann::json data;
    g_autoptr(GError) error = nullptr;
    gchar *result = secret_password_lookupv_sync(&schema, table, nullptr, &error);
    if (error)
    {
        throw error->message;
    }
    if (result != NULL && strcmp(result, "") != 0)
    {
        data = nlohmann::json::parse(result);
    }
    // Manually free the result after use
    if (result != NULL)
    {
        secret_password_free(result); // Clean up the allocated memory
    }
    return data;
}

bool Storage::store_json(nlohmann::json data)
{
    const std::string dataStr = data.dump(0);
    g_autoptr(GError) error = nullptr;
    bool result = secret_password_storev_sync(
        &schema, table, nullptr, SECRET_SCHEME_LABLE, dataStr.c_str(), nullptr, &error);
    if (error)
    {
        throw error->message;
    }
    return result;
}

std::string Storage::read_key(const char *key)
{
    nlohmann::json json = read_json();
    nlohmann::json value = json[key];
    if (value.is_string())
    {
        return value.get<std::string>();
    }
    return "";
}
// Function to read all key-value pairs as a map<string, string>
std::map<std::string, std::string> Storage::read_all()
{
    nlohmann::json json = read_json();
    std::map<std::string, std::string> result;

    // Iterate over all key-value pairs in the JSON object using an iterator
    for (nlohmann::json::iterator it = json.begin(); it != json.end(); ++it)
    {
        if (it.value().is_string())
        {
            result[it.key()] = it.value().get<std::string>();
        }
    }

    return result;
}

// Function to read multiple items by a list of keys
std::map<std::string, std::string> Storage::read_multiple_items(const std::vector<std::string> &keys)
{
    nlohmann::json json = read_json();
    std::map<std::string, std::string> result;

    // Iterate over the list of keys provided
    for (const std::string &key : keys)
    {
        if (json.contains(key) && json[key].is_string())
        {
            result[key] = json[key].get<std::string>(); // Add the key-value pair to the result
        }
    }

    return result;
}
// Modified read_keys function to handle empty string prefix
std::vector<std::string> Storage::read_keys(const char *prefix)
{
    nlohmann::json json = read_json();
    std::vector<std::string> keys;

    // Iterate over all key-value pairs in the JSON object
    for (nlohmann::json::iterator it = json.begin(); it != json.end(); ++it)
    {
        if (it.value().is_string())
        {
            // If a prefix is provided and the key starts with that prefix
            if (prefix[0] != '\0' && std::string(it.key()).rfind(prefix, 0) == 0)
            {
                keys.push_back(it.key()); // Add the key to the list if it matches the prefix
            }
            // If no prefix is provided (empty string), add all keys
            else if (prefix[0] == '\0')
            {
                keys.push_back(it.key());
            }
        }
    }

    return keys;
}
bool Storage::write_key_pair(const char *key, const char *value)
{
    nlohmann::json json = read_json();
    json[key] = value;
    return store_json(json);
}

bool Storage::remove_key(const char *key)
{
    nlohmann::json json = read_json();
    if (json.is_null())
    {
        return false;
    }
    json.erase(key);
    return store_json(json);
}
bool Storage::remove_multiple_keys(const std::vector<std::string> &keys)
{
    nlohmann::json json = read_json();
    if (json.is_null())
    {
        return false; // JSON object is empty or null
    }

    // Iterate over the list of keys and remove them from the JSON object
    for (const std::string &key : keys)
    {
        json.erase(key); // Remove the key from the JSON
    }

    // Store the modified JSON back to the storage
    return store_json(json);
}
bool Storage::remove_all()
{

    return store_json(nlohmann::json());
}

FlMethodResponse *Storage::hanadle_storage_call(FlValue *data)
{
    FlValue *type = fl_value_lookup_string(data, "type");
    FlValue *key = fl_value_lookup_string(data, "key");
    FlValue *value = fl_value_lookup_string(data, "value");
    if (type == nullptr ||
        fl_value_get_type(type) != FL_VALUE_TYPE_STRING)

    {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENT",
            "Invalid Map argument or storage operation type.", nullptr));
    }
    const gchar *string_type = fl_value_get_string(type);
    if (strcmp(string_type, STORAGE_TYPE_WRITE) == 0)
    {
        if (key != nullptr &&
            fl_value_get_type(key) == FL_VALUE_TYPE_STRING && value != nullptr && fl_value_get_type(value))
        {
            const gchar *string_key = fl_value_get_string(key);
            const gchar *string_value = fl_value_get_string(value);
            bool store = write_key_pair(string_key, string_value);
            g_autoptr(FlValue) result = fl_value_new_bool(store);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, STORAGE_TYPE_REMOVE) == 0)
    {
        if (key != nullptr &&
            fl_value_get_type(key) == FL_VALUE_TYPE_STRING)
        {
            const gchar *string_key = fl_value_get_string(key);
            bool store = remove_key(string_key);
            g_autoptr(FlValue) result = fl_value_new_bool(store);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, STORAGE_TYPE_REMOVE_ALL) == 0)
    {
        bool store = remove_all();
        g_autoptr(FlValue) result = fl_value_new_bool(store);
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, STORAGE_TYPE_READ) == 0)
    {

        if (key != nullptr &&
            fl_value_get_type(key) == FL_VALUE_TYPE_STRING)
        {
            const gchar *string_key = fl_value_get_string(key);
            std::string store = read_key(string_key);
            if (store.empty())
            {
                g_autoptr(FlValue) result = fl_value_new_null();
                return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
            }
            g_autofree gchar *gstore = g_strdup(store.c_str());
            g_autoptr(FlValue) result = fl_value_new_string(gstore);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, STORAGE_TYPE_CONTAINS_KEY) == 0)
    {

        if (key != nullptr &&
            fl_value_get_type(key) == FL_VALUE_TYPE_STRING)
        {
            const gchar *string_key = fl_value_get_string(key);
            std::string store = read_key(string_key);
            g_autoptr(FlValue) result = fl_value_new_bool(!store.empty());
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, STORAGE_TYPE_READ_ALL) == 0)
    {
        std::map<std::string, std::string> all_data = read_all();
        g_autoptr(FlValue) result = fl_value_new_map();
        // Iterate over the map using an iterator instead of structured bindings
        for (std::map<std::string, std::string>::const_iterator it = all_data.begin(); it != all_data.end(); ++it)
        {
            g_autoptr(FlValue) key_value = fl_value_new_string(it->second.c_str()); // Create FlValue from the string
            g_autoptr(FlValue) fl_key = fl_value_new_string(it->first.c_str());     // Create FlValue from the key

            fl_value_set(result, fl_key, key_value); // Set the key-value pair in the FlValue map
        }
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, STORAGE_TYPE_READ_KEYS) == 0)
    {
        if (key != nullptr &&
            fl_value_get_type(key) == FL_VALUE_TYPE_STRING)
        {
            const gchar *string_key = fl_value_get_string(key);
            std::vector<std::string> all_keys = read_keys(string_key);

            // Create a new FlValue list to store the keys
            g_autoptr(FlValue) result = fl_value_new_list();

            // Iterate over the keys and append them to the FlValue list
            for (const std::string &key : all_keys)
            {
                g_autoptr(FlValue) fl_key = fl_value_new_string(key.c_str()); // Create FlValue from the key
                fl_value_append(result, fl_key);                              // Add the key to the list
            }

            // Return the response with the list of keys
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, STORAGE_TYPE_READ_MULTIPLE) == 0)
    {
        FlValue *args = fl_value_lookup_string(data, "keys");
        if (args != nullptr &&
            fl_value_get_type(args) == FL_VALUE_TYPE_LIST)
        {
            // Parse the argument list into a vector of strings
            std::vector<std::string> keys;
            guint num_keys = fl_value_get_length(args);

            for (guint i = 0; i < num_keys; ++i)
            {
                FlValue *item = fl_value_get_list_value(args, i);
                if (fl_value_get_type(item) == FL_VALUE_TYPE_STRING)
                {
                    const gchar *key = fl_value_get_string(item);
                    keys.push_back(std::string(key)); // Add the key to the list
                }
            }
            // Call read_multiple_items with the parsed keys
            std::map<std::string, std::string> all_data = read_multiple_items(keys);

            // Create a new FlValue map to store the key-value pairs
            g_autoptr(FlValue) result = fl_value_new_map();

            // Iterate over the map and add key-value pairs to the FlValue map
            for (const auto &pair : all_data)
            {
                g_autoptr(FlValue) fl_key = fl_value_new_string(pair.first.c_str());     // Create FlValue from the key
                g_autoptr(FlValue) key_value = fl_value_new_string(pair.second.c_str()); // Create FlValue from the value
                fl_value_set(result, fl_key, key_value);                                 // Set the key-value pair in the FlValue map
            }

            // Return the response with the map of key-value pairs
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, STORAGE_TYPE_REMOVE_MULTIPLE) == 0)
    {
        FlValue *args = fl_value_lookup_string(data, "keys");
        if (args != nullptr &&
            fl_value_get_type(args) == FL_VALUE_TYPE_LIST)
        {
            // Parse the argument list into a vector of strings
            std::vector<std::string> keys;
            guint num_keys = fl_value_get_length(args);

            for (guint i = 0; i < num_keys; ++i)
            {
                FlValue *item = fl_value_get_list_value(args, i);
                if (fl_value_get_type(item) == FL_VALUE_TYPE_STRING)
                {
                    const gchar *key = fl_value_get_string(item);
                    keys.push_back(std::string(key)); // Add the key to the list
                }
            }
            bool store = remove_multiple_keys(keys);
            g_autoptr(FlValue) result = fl_value_new_bool(store);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }

    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENT",          // Error code
        "Some key or value missing", // Error message
        nullptr                      // No additional error details
        ));
}