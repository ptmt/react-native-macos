extern crate jsc;

#[test]
fn public_it_correctly_evaluate_simple_js_expression() {
    let js_code = "var a = 1; var b = 2; a + b".to_string();
    unsafe {
        let context = jsc::JSCContext::init_context().unwrap();
        let result = context.evaluate_script(js_code, "".to_string());
        assert_eq!(result.unwrap(), "3");
    }
}
