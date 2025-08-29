
// // #include <libsecret/secret.h>
// // // #include <glib.h>
// // // #include <iostream>
// // #define SECRET_SCHEMA "org.example.MySecretSchema"
// // #define SECRET_SCHEMA_ATTRIBUTES "secret_key"

// // class Storage
// // {
// // public:
// //     Storage();  // Constructor to initialize schema
// //     ~Storage(); // Destructor to free schema memory
// //     FlMethodResponse *hanadle_storage_call(FlValue *data);

// //     gboolean store_secret(const gchar *key, const gchar *value);
// //     gchar *retrieve_secret(const gchar *key);
// //     // gboolean remove_secret(const gchar *key);

// // private:
// //     SecretSchema *schema; // Secret schema for storing/retrieving secrets
// // };
// // // Constructor: Initialize the schema
// // Storage::Storage()
// // {
// //     // g_print("My string: %s\n", 'Storage');
// //     schema = g_new0(SecretSchema, 1); // Allocate memory for schema

// //     // Define the schema for storing the secret
// //     schema = secret_schema_new(
// //         SECRET_SCHEMA,      // Schema name
// //         SECRET_SCHEMA_NONE, // Schema flags
// //         SECRET_SCHEMA_ATTRIBUTE_STRING,
// //         NULL);
// // }

// // // Destructor: Free the schema memory
// // Storage::~Storage()
// // {
// //     if (schema)
// //     {
// //         g_free(schema); // Free the schema memory when done
// //     }
// // }

// // gboolean Storage::store_secret(const gchar *key, const gchar *value)

// // {
// //     g_autoptr(GError) error = nullptr;
// //     gboolean result = secret_password_store_sync(
// //         schema,                         // Use the custom schema
// //         "default",                      // Collection name (usually "default")
// //         key,                            // Secret label
// //         value,                          // The secret value to store
// //         NULL,                           // Cancellable (NULL means no cancellation)
// //         &error,                         // Error pointer for reporting errors
// //         SECRET_SCHEMA_ATTRIBUTE_STRING, // First attribute name
// //         SECRET_SCHEMA_ATTRIBUTE_STRING, // First attribute value
// //         NULL                            // Sentinel to mark the end of the argument list
// //     );

// //     if (error)
// //     {
// //         g_print("My string: %s\n", error->message);

// //         // std::cerr << "Error storing secret: " << error->message << std::endl;
// //     }

// //     return result;
// // }

// // gchar *Storage::retrieve_secret(const gchar *key)
// // {

// //     GError *error = NULL;
// //     gchar *value = secret_password_lookup_sync(
// //         schema,
// //         NULL,
// //         &error,
// //         SECRET_SCHEMA_ATTRIBUTE_STRING, // First attribute name
// //         SECRET_SCHEMA_ATTRIBUTE_STRING, // First attribute value
// //         key,
// //         NULL);

// //     if (value != nullptr)
// //     {
// //         g_print("Secret retrieved: %s\n", value);
// //         g_free(value); // Don't forget to free the value when done
// //     }
// //     else
// //     {
// //         g_warning("Failed to retrieve secret: %s", error->message);
// //         g_error_free(error);
// //     }

// //     return value;
// // }

// // FlMethodResponse *Storage::hanadle_storage_call(FlValue *data)
// // {
// //     // Parse the map (retrieve values)
// //     FlValue *type = fl_value_lookup_string(data, "type");
// //     FlValue *key = fl_value_lookup_string(data, "key");
// //     FlValue *value = fl_value_lookup_string(data, "value");
// //     // Check if the values exist and are of the correct type (e.g., string, int, etc.)
// //     if (type == nullptr || key == nullptr ||
// //         fl_value_get_type(type) != FL_VALUE_TYPE_STRING ||
// //         fl_value_get_type(key) != FL_VALUE_TYPE_STRING)
// //     {
// //         return FL_METHOD_RESPONSE(fl_method_error_response_new(
// //             "INVALID_ARGUMENT", // Error code
// //             "Expected a map",   // Error message
// //             nullptr             // No additional error details
// //             ));
// //     }
// //     const gchar *string_type = fl_value_get_string(type);
// //     const gchar *string_key = fl_value_get_string(key);

// //     if (strcmp(string_type, "write") == 0)
// //     {
// //         const gchar *string_value = fl_value_get_string(value);
// //         gboolean store = store_secret(string_key, string_value);
// //         if (store)
// //         {
// //             g_print("store: %s\n", string_value);
// //         }
// //     }
// //     else if (strcmp(string_type, "read") == 0)
// //     {
// //         gchar *store = retrieve_secret(string_key);
// //         if (store != nullptr)
// //         {
// //             g_print("read store: %s\n", store);
// //         }
// //     }
// //     g_print("type: %s\n", string_type);
// //     g_print("type: %s\n", string_key);
// //     // g_print("type: %s\n", string_value);

// //     return FL_METHOD_RESPONSE(fl_method_error_response_new(
// //         "INVALID_ARGUMENT", // Error code
// //         "Expected a map",   // Error message
// //         nullptr             // No additional error details
// //         ));
// // }

// #include <libsecret/secret.h>
// // Function to free key-value pairs

// class GHashTableWrapper
// {

// public:
//     GHashTable *table;
//     // Constructor: Creates a new GHashTable
//     GHashTableWrapper()
//     {
//         // Create a new GHashTable with string keys and values (using g_str_hash and g_str_equal)
//         // Also specify custom functions to free memory for the keys and values
//         table = g_hash_table_new_full(g_str_hash, NULL, g_free, g_free);
//     }

//     // Destructor: Frees the GHashTable
//     ~GHashTableWrapper()
//     {
//         if (table != nullptr)
//         {
//             g_hash_table_destroy(table);
//         }
//     }

//     // Write (insert) a key-value pair into the hash table
//     // Returns true if insertion was successful, false if the key already exists
//     bool write(const char *key, const char *value)
//     {
//         g_hash_table_insert(table, g_strdup(key), g_strdup(value));
//         return true; // Successfully inserted
//     }

//     // Read (retrieve) a value by its key
//     const char *read(const char *key)
//     {
//         return static_cast<const char *>(g_hash_table_lookup(table, key));
//     }

//     // Check if a key exists in the hash table
//     bool contains(const char *key)
//     {
//         return g_hash_table_contains(table, key);
//     }

//     // Remove a key-value pair from the hash table
//     bool remove(const char *key)
//     {
//         return g_hash_table_remove(table, key);
//     }
// };
