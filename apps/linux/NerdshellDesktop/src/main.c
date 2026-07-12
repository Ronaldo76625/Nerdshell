#include <gtk/gtk.h>
#include <vte/vte.h>
#include <glib/gstdio.h>
#include <pwd.h>
#include <sys/types.h>
#include <unistd.h>

#define APP_ID "io.github.nerdshell.desktop"
#define APP_NAME "Nerdshell"
#define PROFILE_SOURCE "/usr/share/nerdshell-desktop/configs"

typedef struct {
    GtkApplication *app;
    GtkWidget *window;
    GtkWidget *notebook;
} NerdshellWindow;

static const char *css =
    "window { background: #0a0e16; }"
    "notebook header { background: #17171b; border: 0; }"
    "notebook tab { padding: 6px 12px; color: #c0caf5; }"
    "notebook tab:checked { background: #30233f; }";

static gboolean copy_file(const gchar *source, const gchar *destination, GError **error)
{
    GFile *src = g_file_new_for_path(source);
    GFile *dst = g_file_new_for_path(destination);
    gboolean result = g_file_copy(src, dst, G_FILE_COPY_OVERWRITE, NULL, NULL, NULL, error);
    g_object_unref(src);
    g_object_unref(dst);
    return result;
}

static gboolean prepare_profile(gchar **profile_out, GError **error)
{
    gchar *profile = g_build_filename(g_get_user_data_dir(), "nerdshell", "profiles", "default", NULL);
    gchar *zdotdir = g_build_filename(profile, "zdotdir", NULL);
    gchar *eza = g_build_filename(profile, "eza", NULL);

    if (g_mkdir_with_parents(zdotdir, 0700) != 0 || g_mkdir_with_parents(eza, 0700) != 0) {
        g_set_error(error, G_FILE_ERROR, g_file_error_from_errno(errno), "Could not create Nerdshell profile: %s", g_strerror(errno));
        g_free(profile); g_free(zdotdir); g_free(eza);
        return FALSE;
    }

    struct { const char *source; const char *name; const char *subdir; } files[] = {
        { "zsh/zshrc", ".zshrc", "zdotdir" },
        { "zsh/zprofile", ".zprofile", "zdotdir" },
        { "zsh/zshenv", ".zshenv", "zdotdir" },
        { "starship/starship.toml", "starship.toml", NULL },
        { "eza/theme.yml", "theme.yml", "eza" }
    };

    for (guint i = 0; i < G_N_ELEMENTS(files); i++) {
        gchar *src = g_build_filename(PROFILE_SOURCE, files[i].source, NULL);
        gchar *dst = files[i].subdir
            ? g_build_filename(profile, files[i].subdir, files[i].name, NULL)
            : g_build_filename(profile, files[i].name, NULL);
        gboolean ok = copy_file(src, dst, error);
        g_free(src); g_free(dst);
        if (!ok) {
            g_free(profile); g_free(zdotdir); g_free(eza);
            return FALSE;
        }
    }

    gchar *zshrc = g_build_filename(zdotdir, ".zshrc", NULL);
    FILE *file = g_fopen(zshrc, "a");
    if (file) {
        fputs("\n# Nerdshell Desktop isolation overrides\n"
              "export HISTFILE=\"$NERDSHELL_PROFILE/history\"\n"
              "export EZA_CONFIG_DIR=\"$NERDSHELL_PROFILE/eza\"\n", file);
        fclose(file);
    }

    g_free(zshrc); g_free(zdotdir); g_free(eza);
    *profile_out = profile;
    return TRUE;
}

static gchar *get_shell(void)
{
    const gchar *configured = g_getenv("SHELL");
    if (configured && g_file_test(configured, G_FILE_TEST_IS_EXECUTABLE)) return g_strdup(configured);
    struct passwd *pw = getpwuid(getuid());
    if (pw && pw->pw_shell && g_file_test(pw->pw_shell, G_FILE_TEST_IS_EXECUTABLE)) return g_strdup(pw->pw_shell);
    return g_strdup("/bin/zsh");
}

static VteTerminal *current_terminal(NerdshellWindow *state)
{
    gint page = gtk_notebook_get_current_page(GTK_NOTEBOOK(state->notebook));
    if (page < 0) return NULL;
    GtkWidget *child = gtk_notebook_get_nth_page(GTK_NOTEBOOK(state->notebook), page);
    return child ? VTE_TERMINAL(child) : NULL;
}

static void update_title(VteTerminal *terminal, gpointer user_data)
{
    NerdshellWindow *state = user_data;
    const gchar *title = vte_terminal_get_window_title(terminal);
    gtk_window_set_title(GTK_WINDOW(state->window), title && *title ? title : APP_NAME);
}

static void close_page(GtkButton *button, gpointer user_data)
{
    (void)button;
    GtkWidget *terminal = GTK_WIDGET(user_data);
    GtkNotebook *notebook = GTK_NOTEBOOK(gtk_widget_get_parent(terminal));
    gint page = gtk_notebook_page_num(notebook, terminal);
    if (page >= 0) gtk_notebook_remove_page(notebook, page);
}

static GtkWidget *tab_label(VteTerminal *terminal)
{
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    GtkWidget *label = gtk_label_new("Shell");
    GtkWidget *close = gtk_button_new_from_icon_name("window-close-symbolic", GTK_ICON_SIZE_MENU);
    gtk_button_set_relief(GTK_BUTTON(close), GTK_RELIEF_NONE);
    g_signal_connect(close, "clicked", G_CALLBACK(close_page), terminal);
    gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(box), close, FALSE, FALSE, 0);
    gtk_widget_show_all(box);
    return box;
}

static void child_exited(VteTerminal *terminal, gint status, gpointer user_data)
{
    (void)status;
    NerdshellWindow *state = user_data;
    GtkNotebook *notebook = GTK_NOTEBOOK(state->notebook);
    gint page = gtk_notebook_page_num(notebook, GTK_WIDGET(terminal));
    if (page >= 0 && gtk_notebook_get_n_pages(notebook) > 1) gtk_notebook_remove_page(notebook, page);
}

static void add_terminal(NerdshellWindow *state, const gchar *working_directory)
{
    GError *error = NULL;
    gchar *profile = NULL;
    if (!prepare_profile(&profile, &error)) {
        GtkWidget *dialog = gtk_message_dialog_new(GTK_WINDOW(state->window), GTK_DIALOG_MODAL,
            GTK_MESSAGE_ERROR, GTK_BUTTONS_CLOSE, "Could not prepare Nerdshell profile: %s", error->message);
        gtk_dialog_run(GTK_DIALOG(dialog)); gtk_widget_destroy(dialog); g_clear_error(&error);
        return;
    }

    VteTerminal *terminal = VTE_TERMINAL(vte_terminal_new());
    vte_terminal_set_scrollback_lines(terminal, 100000);
    vte_terminal_set_mouse_autohide(terminal, TRUE);
    vte_terminal_set_allow_hyperlink(terminal, TRUE);
    vte_terminal_set_word_char_exceptions(terminal, "-#%&+,./=?@\\_~");

    PangoFontDescription *font = pango_font_description_from_string("JetBrainsMono Nerd Font Mono 11");
    vte_terminal_set_font(terminal, font);
    pango_font_description_free(font);

    GdkRGBA foreground = { .red = 0.753, .green = 0.792, .blue = 0.961, .alpha = 1.0 };
    GdkRGBA background = { .red = 0.039, .green = 0.055, .blue = 0.086, .alpha = 1.0 };
    GdkRGBA cursor = { .red = 0.620, .green = 0.886, .blue = 0.545, .alpha = 1.0 };
    vte_terminal_set_colors(terminal, &foreground, &background, NULL, 0);
    vte_terminal_set_color_cursor(terminal, &cursor);

    gchar *shell = get_shell();
    gchar *argv[] = { shell, "-l", NULL };
    gchar **environment = g_get_environ();
    gchar *zdotdir = g_build_filename(profile, "zdotdir", NULL);
    gchar *starship = g_build_filename(profile, "starship.toml", NULL);
    gchar *eza = g_build_filename(profile, "eza", NULL);
    environment = g_environ_setenv(environment, "NERDSHELL", "1", TRUE);
    environment = g_environ_setenv(environment, "NERDSHELL_PROFILE", profile, TRUE);
    environment = g_environ_setenv(environment, "ZDOTDIR", zdotdir, TRUE);
    environment = g_environ_setenv(environment, "STARSHIP_CONFIG", starship, TRUE);
    environment = g_environ_setenv(environment, "EZA_CONFIG_DIR", eza, TRUE);
    environment = g_environ_setenv(environment, "TERM", "xterm-256color", TRUE);
    environment = g_environ_setenv(environment, "COLORTERM", "truecolor", TRUE);

    gint page = gtk_notebook_append_page(GTK_NOTEBOOK(state->notebook), GTK_WIDGET(terminal), tab_label(terminal));
    gtk_notebook_set_current_page(GTK_NOTEBOOK(state->notebook), page);
    gtk_widget_show(GTK_WIDGET(terminal));
    gtk_widget_grab_focus(GTK_WIDGET(terminal));

    g_signal_connect(terminal, "window-title-changed", G_CALLBACK(update_title), state);
    g_signal_connect(terminal, "child-exited", G_CALLBACK(child_exited), state);
    vte_terminal_spawn_async(terminal, VTE_PTY_DEFAULT,
        working_directory ? working_directory : g_get_home_dir(), argv, environment,
        G_SPAWN_SEARCH_PATH, NULL, NULL, NULL, -1, NULL, NULL, NULL);

    g_strfreev(environment); g_free(eza); g_free(starship); g_free(zdotdir);
    g_free(shell); g_free(profile);
}

static void action_new_tab(GSimpleAction *action, GVariant *parameter, gpointer user_data)
{ (void)action; (void)parameter; add_terminal(user_data, NULL); }

static void action_close_tab(GSimpleAction *action, GVariant *parameter, gpointer user_data)
{
    (void)action; (void)parameter;
    NerdshellWindow *state = user_data;
    gint page = gtk_notebook_get_current_page(GTK_NOTEBOOK(state->notebook));
    if (page >= 0) gtk_notebook_remove_page(GTK_NOTEBOOK(state->notebook), page);
}

static void action_copy(GSimpleAction *action, GVariant *parameter, gpointer user_data)
{ (void)action; (void)parameter; VteTerminal *t = current_terminal(user_data); if (t) vte_terminal_copy_clipboard_format(t, VTE_FORMAT_TEXT); }

static void action_paste(GSimpleAction *action, GVariant *parameter, gpointer user_data)
{ (void)action; (void)parameter; VteTerminal *t = current_terminal(user_data); if (t) vte_terminal_paste_clipboard(t); }

static void action_find(GSimpleAction *action, GVariant *parameter, gpointer user_data)
{ (void)action; (void)parameter; VteTerminal *t = current_terminal(user_data); if (t) gtk_widget_grab_focus(GTK_WIDGET(t)); }

static void activate(GtkApplication *app, gpointer user_data)
{
    (void)user_data;
    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider, css, -1, NULL);
    gtk_style_context_add_provider_for_screen(
        gdk_screen_get_default(),
        GTK_STYLE_PROVIDER(provider),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
    );
    g_object_unref(provider);

    NerdshellWindow *state = g_new0(NerdshellWindow, 1);
    state->app = app;
    state->window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(state->window), APP_NAME);
    gtk_window_set_default_size(GTK_WINDOW(state->window), 1000, 680);
    gtk_window_set_icon_name(GTK_WINDOW(state->window), "nerdshell");
    state->notebook = gtk_notebook_new();
    gtk_notebook_set_scrollable(GTK_NOTEBOOK(state->notebook), TRUE);
    gtk_container_add(GTK_CONTAINER(state->window), state->notebook);

    const GActionEntry actions[] = {
        { .name = "new-tab", .activate = action_new_tab },
        { .name = "close-tab", .activate = action_close_tab },
        { .name = "copy", .activate = action_copy },
        { .name = "paste", .activate = action_paste },
        { .name = "find", .activate = action_find }
    };
    g_action_map_add_action_entries(G_ACTION_MAP(state->window), actions, G_N_ELEMENTS(actions), state);
    const gchar *new_tab[] = { "<Primary>t", NULL };
    const gchar *close_tab[] = { "<Primary>w", NULL };
    const gchar *copy[] = { "<Primary><Shift>c", NULL };
    const gchar *paste[] = { "<Primary><Shift>v", NULL };
    gtk_application_set_accels_for_action(app, "win.new-tab", new_tab);
    gtk_application_set_accels_for_action(app, "win.close-tab", close_tab);
    gtk_application_set_accels_for_action(app, "win.copy", copy);
    gtk_application_set_accels_for_action(app, "win.paste", paste);

    add_terminal(state, NULL);
    gtk_widget_show_all(state->window);
}

int main(int argc, char **argv)
{
    GtkApplication *app = gtk_application_new(APP_ID, G_APPLICATION_HANDLES_OPEN);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}
