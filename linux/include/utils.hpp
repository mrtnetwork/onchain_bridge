#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <gtk/gtk.h>
#include <glib.h>
#include <fstream>
class OnChainBridgeUtils
{
public:
    OnChainBridgeUtils();
    bool launch_url(const char *url);
    FlMethodResponse *handle_utils_calls(const gchar *method, FlValue *data);
    gchar *pick_file(const gchar *extension, const gchar *mime_type, const gchar *title);
    bool save_file(const gchar *file_path, const gchar *fileName, const gchar *extension, const gchar *title);
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

gchar *OnChainBridgeUtils::pick_file(const gchar *extension, const gchar *mime_type, const gchar *title)
{
    GtkWidget *dialog;
    gchar *result = nullptr;

    // If title is null, use default
    const gchar *dialogTitle = title != nullptr ? title : "Select a file";

    dialog = gtk_file_chooser_dialog_new(
        dialogTitle,
        NULL,
        GTK_FILE_CHOOSER_ACTION_OPEN,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Open", GTK_RESPONSE_ACCEPT,
        NULL);

    // Optional: restrict by extension
    if (extension != nullptr)
    {
        GtkFileFilter *filter = gtk_file_filter_new();
        std::string pattern = "*." + std::string(extension); // e.g. "*.txt"
        gtk_file_filter_add_pattern(filter, pattern.c_str());
        gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);
    }

    // Optional: restrict by MIME type
    if (mime_type != nullptr)
    {
        GtkFileFilter *filter = gtk_file_filter_new();
        gtk_file_filter_add_mime_type(filter, mime_type);
        gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);
    }

    if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT)
    {
        char *filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));
        result = g_strdup(filename); // caller owns memory
        g_free(filename);
    }

    gtk_widget_destroy(dialog);
    while (g_main_context_iteration(NULL, FALSE))
        ;

    return result; // nullptr if cancelled
}

bool OnChainBridgeUtils::save_file(const gchar *file_path, const gchar *fileName, const gchar *extension, const gchar *title)
{
    GtkWidget *dialog;
    gchar *result = nullptr;
    const gchar *dialogTitle = title != nullptr ? title : "Select a file";
    dialog = gtk_file_chooser_dialog_new(
        dialogTitle,
        NULL,
        GTK_FILE_CHOOSER_ACTION_SAVE,
        "_Cancel", GTK_RESPONSE_CANCEL,
        "_Save", GTK_RESPONSE_ACCEPT,
        NULL);

    gtk_file_chooser_set_do_overwrite_confirmation(GTK_FILE_CHOOSER(dialog), TRUE);

    // Set default file name
    if (fileName != nullptr)
    {
        gtk_file_chooser_set_current_name(GTK_FILE_CHOOSER(dialog), fileName);
    }

    // Optional: filter by extension
    if (extension != nullptr)
    {
        GtkFileFilter *filter = gtk_file_filter_new();
        std::string pattern = "*." + std::string(extension); // e.g. "*.txt"
        gtk_file_filter_add_pattern(filter, pattern.c_str());
        gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(dialog), filter);
    }

    if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT)
    {
        char *destPath = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(dialog));

        // Copy the file from file_path -> destPath
        if (file_path != nullptr && destPath != nullptr)
        {
            std::ifstream src(file_path, std::ios::binary);
            std::ofstream dst(destPath, std::ios::binary);
            dst << src.rdbuf(); // copy content
        }

        result = g_strdup(destPath); // duplicate so caller owns memory
        g_free(destPath);
    }

    gtk_widget_destroy(dialog);
    while (g_main_context_iteration(NULL, FALSE))
        ;

    return result != nullptr; // nullptr if canceled
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
    else if (strcmp(method, "pick_file") == 0)
    {
        FlValue *extension = fl_value_lookup_string(data, "extension");
        FlValue *mime_type = fl_value_lookup_string(data, "mime_type");
        FlValue *title = fl_value_lookup_string(data, "title");
        const gchar *string_extension = nullptr;
        const gchar *string_mime_type = nullptr;
        const gchar *string_title = nullptr;

        if (extension != nullptr && fl_value_get_type(extension) == FL_VALUE_TYPE_STRING)
        {
            string_extension = (gchar *)fl_value_get_string(extension);
        }

        if (mime_type != nullptr && fl_value_get_type(mime_type) == FL_VALUE_TYPE_STRING)
        {
            string_mime_type = (gchar *)fl_value_get_string(mime_type);
        }
        if (title != nullptr && fl_value_get_type(title) == FL_VALUE_TYPE_STRING)
        {
            string_title = (gchar *)fl_value_get_string(title);
        }
        const gchar *path = pick_file(string_extension, string_mime_type, string_title);
        if (path == nullptr)
        {
            g_autoptr(FlValue) result = fl_value_new_null();
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
        g_autoptr(FlValue) result = fl_value_new_string(path);
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(method, "save_file") == 0)
    {
        FlValue *file_path = fl_value_lookup_string(data, "file_path");
        FlValue *file_name = fl_value_lookup_string(data, "file_name");
        FlValue *extension = fl_value_lookup_string(data, "extension");
        FlValue *title = fl_value_lookup_string(data, "title");

        if (file_path != nullptr && fl_value_get_type(file_path) == FL_VALUE_TYPE_STRING &&
            file_name != nullptr && fl_value_get_type(file_name) == FL_VALUE_TYPE_STRING &&
            extension != nullptr && fl_value_get_type(extension) == FL_VALUE_TYPE_STRING)
        {
            const gchar *string_title = nullptr;
            const gchar *string_file_path = fl_value_get_string(file_path);
            const gchar *string_file_name = fl_value_get_string(file_name);
            const gchar *string_extension = fl_value_get_string(extension);

            if (title != nullptr && fl_value_get_type(title) == FL_VALUE_TYPE_STRING)
            {
                string_title = (gchar *)fl_value_get_string(title);
            }
            bool save = save_file(string_file_path, string_file_name, string_extension, string_title);
            g_autoptr(FlValue) result = fl_value_new_bool(save);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENT",          // Error code
        "Some key or value missing", // Error message
        nullptr                      // No additional error details
        ));
}