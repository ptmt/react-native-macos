extern crate jsc;

/// ---------------- Executor
pub trait JavaScriptExecutor {
    fn test_js_env(&self) -> bool;
    fn load_application_script(&self, script: String, url: String);
}


pub struct JSCExecutor {
    context: jsc::JSCContext
}

impl JSCExecutor {
    pub fn init() -> JSCExecutor {
        unsafe {
            let context = jsc::JSCContext::init_context().unwrap();
            JSCExecutor { context: context }
        }
    }
}

impl JavaScriptExecutor for JSCExecutor {

    fn test_js_env(&self) -> bool {
        let js_code = "var a = 1; var b = 2; a + b";
        unsafe {
            //let context = jsc::JSCContext::init_context().unwrap();
            let result = self.context.evaluate_script(js_code.to_string(), "".to_string());
            result.unwrap() == "3"
        }
    }
    fn load_application_script(&self, script: String, url: String) {
        unsafe {
            let result = self.context.evaluate_script(script.to_string(), url);
        }
    }
}
// impl BridgeModule for JSCExecutor {
//     fn name(&self) -> &str { "JSCExecutor" }
//     fn methods(&self) {
//         println!("nothing");
//     }
//     fn init(&self) {
//         println!("module init");
//     }
// }

#[test]
fn test_js_env() {
    let jsc_executor = JSCExecutor::init();
    assert!(jsc_executor.test_js_env());
}

#[test]
fn test_loading_application_script() {
    let js_text = "
    var Bridge = {
        callFunctionReturnFlushedQueue: function (module, method, args) {
            return [[module + 1], [method + 1], [args]];
        }
    }
    function require() { return Bridge; }".to_string();

    let jsc_executor = JSCExecutor::init();
    jsc_executor.load_application_script(js_text, "".to_string());
}
