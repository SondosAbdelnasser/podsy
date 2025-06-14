#include "file_picker_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include "flutter/generated_plugin_registrant.h"

int main(int argc, char** argv) {
  // Initialize GTK
  gtk_init(&argc, &argv);

  g_autoptr(FlEngine) engine = fl_engine_new_with_project(
      fl_dart_project_new());

  gtk_widget_show_all(window);
  gtk_main();

  return 0;
} 