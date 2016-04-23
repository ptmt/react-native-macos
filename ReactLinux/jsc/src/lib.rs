extern crate libc;

use std::fmt;
use std::ptr;
use std::ffi::{CString};
use std::os::raw::c_char;


type JSContextGroup = std::os::raw::c_void;
type JSClassRef = std::os::raw::c_void;
type JSGlobalContextRef = std::os::raw::c_void;
type JSStringRef = std::os::raw::c_void;
type JSObjectRef = std::os::raw::c_void;
type JSValueRef = std::os::raw::c_void;

#[cfg_attr(not(target_os = "macos"), link(name = "javascriptcoregtk-3.0") )]
#[cfg_attr(target_os = "macos", link(name = "JavaScriptCore", kind = "framework") )]
#[allow(non_snake_case)]
extern {

    fn JSContextGroupCreate() -> *const JSContextGroup;
    fn JSGlobalContextCreateInGroup(group: *const JSContextGroup, globalObjectClass: *const JSClassRef) -> *const JSGlobalContextRef;
    fn JSStringCreateWithUTF8CString(string: *const i8) -> *const JSStringRef;

    fn JSEvaluateScript(ctx: *const JSGlobalContextRef,
        script: *const JSStringRef,
        thisObject: *const JSObjectRef,
        sourceURL: *const JSStringRef,
        startingLineNumber: libc::c_int,
        exception: *mut JSValueRef) -> *const JSValueRef;

    fn JSValueCreateJSONString(ctx: *const JSGlobalContextRef,
        value: *const JSValueRef,
        indent: libc::c_int,
        exception: *mut JSValueRef) -> *const JSStringRef;

    fn JSStringGetMaximumUTF8CStringSize(string: *const JSStringRef) -> libc::size_t;
    // JS_EXPORT size_t JSStringGetUTF8CString( JSStringRef string, char *buffer, size_t bufferSize);
    fn JSStringGetUTF8CString(string: *const JSStringRef, buffer: *const c_char, bufferSize: libc::size_t) -> libc::size_t;

    fn JSStringRelease(string: *const JSStringRef);
    fn JSGlobalContextRelease(ctx: *const JSGlobalContextRef);
    fn JSContextGroupRelease(ctx: *const JSContextGroup);
}

unsafe fn convert_jsstring_to_string(string: *const JSStringRef) -> String {
    let reserved = JSStringGetMaximumUTF8CStringSize(string);
    let bytes: Vec<c_char> = Vec::with_capacity(reserved);
    let length = JSStringGetUTF8CString(string, bytes.as_ptr(), reserved) - 1;
    String::from_raw_parts(bytes.as_ptr() as *mut u8, length, reserved)
}

pub struct JSCContext {
    context_group: *const JSContextGroup,
    context: *const JSContextGroup,
}

impl JSCContext {
    pub unsafe fn init_context() -> Result<JSCContext, String> {
        let group = JSContextGroupCreate();
        let context = JSGlobalContextCreateInGroup(group, ptr::null());
        match context.is_null() {
            true => Err("JSCContext could not be created TODO: rich Error".to_string()),
            false => Ok(JSCContext { context_group: group, context: context })
        }

    }

    pub unsafe fn evaluate_script(&self, js_code: String, script_url: String) -> Result<String, String>  {
        let script = JSStringCreateWithUTF8CString(CString::new(js_code).unwrap().as_ptr());
        let url = JSStringCreateWithUTF8CString(CString::new(script_url).unwrap().as_ptr());
        let error: *mut JSValueRef = ptr::null_mut();
        let value = JSEvaluateScript(self.context, script, url, ptr::null_mut(), 0, error);
        let json_js_string = JSValueCreateJSONString(self.context, value, 0, ptr::null_mut());
        let json_string = convert_jsstring_to_string(json_js_string);
        JSStringRelease(script);
        JSStringRelease(json_js_string);
        match error.is_null() {
            true => Ok(json_string),
            false => Err("TODO: rich error message about failed evaluated".to_string())
        }
    }
}

impl fmt::Debug for JSCContext {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", !self.context.is_null())
    }
}

impl Drop for JSCContext {
    fn drop(&mut self) {
        println!("Dropping JSCContext");
        unsafe {
            JSGlobalContextRelease(self.context);
            JSContextGroupRelease(self.context_group);
        }
    }
}

#[test]
#[ignore]
fn private_allocate_string_release() {
        let scriptref = unsafe { JSStringCreateWithUTF8CString(CString::new("var a = 1").unwrap().as_ptr()) };
        assert!(!scriptref.is_null());
        let reserved = unsafe { JSStringGetMaximumUTF8CStringSize(scriptref) };
        assert_eq!(reserved, 28);
        unsafe { JSStringRelease(scriptref); }
        println!("END1");
}


#[test]

fn private_it_could_convert_string_in_both_way() {
    unsafe {
        let scriptref = JSStringCreateWithUTF8CString(CString::new("var a = 1").unwrap().as_ptr());
        assert!(!scriptref.is_null());
        let reserved = JSStringGetMaximumUTF8CStringSize(scriptref);
        assert_eq!(reserved, 28);
        let bytes: Vec<c_char> = Vec::with_capacity(reserved);
        let length = JSStringGetUTF8CString(scriptref, bytes.as_ptr(), reserved) - 1;
        //JSStringRelease(scriptref);
        assert_eq!(length, 9);
        let str_converted_back = String::from_raw_parts(bytes.as_ptr() as *mut u8, length, reserved);
        assert_eq!(str_converted_back, "var a = 1");
    }
    println!("END2");
}

#[test]
#[ignore]
fn private_it_correctly_evaluates_simple_js_expression() {
    unsafe {
        let js_code = "var a = 1; var b = 2; a + b";
        let group = JSContextGroupCreate();
        let context = JSGlobalContextCreateInGroup(group, ptr::null());

        if !context.is_null() {
           println!("jsc -> Context created");
        }
        println!("jsc -> Converting string to JSString {}", "");
        let script = JSStringCreateWithUTF8CString(CString::new(js_code).unwrap().as_ptr());
        println!("jsc -> JSString created");
        let error: *mut JSValueRef = ptr::null_mut();
        let value = JSEvaluateScript(context, script, ptr::null_mut(), ptr::null_mut(), 0, error);
        JSStringRelease(script);
        println!("jsc -> JSValue returned");
        if error.is_null() {
            println!("jsc -> JSError is null");
        }
        if !value.is_null() {
            println!("jsc -> JSValue is not null");
        }

        let json_js_string = JSValueCreateJSONString(context, value, 0, ptr::null_mut());
        let json_string = convert_jsstring_to_string(json_js_string);
        JSStringRelease(json_js_string);
        println!("jsc -> json_string = {}", json_string);
        assert_eq!(json_string, "3");

        JSGlobalContextRelease(context);
        JSContextGroupRelease(group);
    }

}
