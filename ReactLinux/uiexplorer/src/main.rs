extern crate gtk;
extern crate time;
extern crate react_gtk_rs;

use react_gtk_rs::bridge::Bridge;
use gtk::prelude::*;

fn main() {
    if gtk::init().is_err() {
        println!("Failed to initialize GTK.");
        return;
    }

    let bridge = Bridge::init("http://localhost:8081/Examples/UIExplorer/UIExplorer.linux.js");

    let window = gtk::Window::new(gtk::WindowType::Toplevel);

    window.set_title("UIExplorerGTK");
    window.set_border_width(10);
    window.set_position(gtk::WindowPosition::Center);
    window.set_default_size(350, 70);

    window.connect_delete_event(|_, _| {
        gtk::main_quit();
        Inhibit(false)
    });

    let button = gtk::Button::new_with_label("Click me!");

    window.add(&button);

    window.show_all();

    gtk::main();
}
