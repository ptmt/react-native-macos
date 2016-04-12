extern crate gtk;
extern crate libc;
extern crate rustc_serialize;
extern crate time;

use rustc_serialize::json;
use gtk::prelude::*;
use std::ffi::CString;
use std::ptr;

type JSContextGroup = std::os::raw::c_void;
type JSClassRef = std::os::raw::c_void;
type JSGlobalContextRef = std::os::raw::c_void;

//#[repr(C)]
type CUTFString = CString;
type JSStringRef = std::os::raw::c_void;

type JSObjectRef = std::os::raw::c_void;
type JSValueRef = std::os::raw::c_void;

#[link(name = "JavaScriptCore", kind = "framework")]
#[allow(non_snake_case)]
extern {

    fn JSContextGroupCreate() -> *mut JSContextGroup;
    fn JSGlobalContextCreateInGroup(group: *mut JSContextGroup, globalObjectClass: *const JSClassRef) -> *mut JSGlobalContextRef;
    fn JSStringCreateWithUTF8CString(string: CUTFString) -> *mut JSStringRef;

    fn JSEvaluateScript(ctx: *mut JSGlobalContextRef,
        script: *mut JSStringRef,
        thisObject: *mut JSObjectRef,
        sourceURL: *mut JSStringRef,
        startingLineNumber: libc::c_int,
        exception: *mut JSValueRef) -> *mut JSValueRef;

    fn JSValueCreateJSONString(ctx: *mut JSGlobalContextRef,
        value: *mut JSValueRef,
        indent: libc::c_int,
        exception: *mut JSValueRef) -> *mut JSStringRef;

    fn JSStringGetMaximumUTF8CStringSize(string: *mut JSStringRef) -> libc::size_t;
    fn JSStringGetUTF8CString(string: *mut JSStringRef, buffer: *mut u8, bufferSize: libc::size_t) -> libc::size_t;

    fn JSStringRelease(string: *mut JSStringRef);
    fn JSGlobalContextRelease(ctx: *mut JSGlobalContextRef);
    fn JSContextGroupRelease(ctx: *mut JSContextGroup);
}

unsafe fn convert_jsstring_to_string(string: *mut JSStringRef) -> String {
    let reserved = JSStringGetMaximumUTF8CStringSize(string);

    //let bytes = Vec::with_capacity(reserved); //: *mut
    let mut bytes: Box<u8> = Box::new(reserved as u8);
    let bytes_ptr: *mut u8 = &mut *bytes; //&bytes as *mut std::os::raw::c_void
    let length = JSStringGetUTF8CString(string, bytes_ptr, reserved) - 1;

    //std::unique_ptr<char[]> retainedBytes(bytes);
    //String::from("ad")
    String::from_raw_parts(bytes_ptr, length, reserved)
    //let result = CString::from_raw(bytes as *mut i8).to_str();
    // Result<&str, core::result::Utf8Error>
    // match result {
    //     Ok(value) => value,
    //     Err(_) => "",
    // }
}
fn main() {
    if gtk::init().is_err() {
        println!("Failed to initialize GTK.");
        return;
    }

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

    execute_js();
}

fn execute_js() {
    println!("jsc -> Run execute_js");
    let js_code = "var a = 1; var b = 2; a + b";
    unsafe {
      let group = JSContextGroupCreate();
      let context = JSGlobalContextCreateInGroup(group, ptr::null());

      if !context.is_null() {
         println!("jsc -> Context created");
      }
      println!("jsc -> Converting string to JSString {}", js_code);
      let script = JSStringCreateWithUTF8CString(CString::new(js_code).unwrap());
      println!("jsc -> JSString created");
      let error: *mut JSValueRef = ptr::null_mut();
      let value = JSEvaluateScript(context, script, ptr::null_mut(), ptr::null_mut(), 0, error);
      println!("jsc -> JSValue returned");
      if error.is_null() {
          println!("jsc -> JSError is null");
      }
      if !value.is_null() {
          println!("jsc -> JSValue is not null");
      }

      let json_js_string = JSValueCreateJSONString(context, value, 0, ptr::null_mut());
      let json_string = convert_jsstring_to_string(json_js_string);
      println!("jsc -> Raw JSON {}", json_string);

      let start = time::PreciseTime::now();
      while start.to(time::PreciseTime::now()) < time::Duration::milliseconds(2) {
        let json_js_string = JSValueCreateJSONString(context, value, 0, ptr::null_mut());
        let json_string = convert_jsstring_to_string(json_js_string);
        JSStringRelease(json_js_string);

        let decoded: i8 = json::decode(&json_string).unwrap();
        print!("{}", decoded);
      }

      println!("jsc -> JSON parse time {} ns", start.to(time::PreciseTime::now()).num_nanoseconds().unwrap());

      JSStringRelease(script);
      JSGlobalContextRelease(context);
      JSContextGroupRelease(group);
    }

}
