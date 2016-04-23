pub mod bridge;

#[cfg(test)]
mod tests {
    use bridge::Bridge;

    #[test]
    fn bridge_could_be_initialized() {
        let batched_bridge = Bridge::init("sourceURL".to_string());
        assert_eq!(batched_bridge.source_url, "sourceURL");
    }

    // #[test]
    // fn bridge_could_execute_some_js() {
    //     let batched_bridge = Bridge::init("sourceURL".to_string());
    //     assert_eq!(batched_bridge.source_url, "sourceURL");
    // }
}
