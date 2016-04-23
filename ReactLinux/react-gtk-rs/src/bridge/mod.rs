mod executors;

use self::executors::{ JavaScriptExecutor, JSCExecutor};

// https://github.com/facebook/react-native/blob/master/ReactAndroid/src/main/java/com/facebook/react/bridge/NativeModule.java

// https://github.com/ReactWindows/react-native/blob/ReactWindows/ReactWindows/ReactNative/Bridge/NativeModuleBase.cs

// http://facebook.github.io/react-native/docs/native-modules-android.html#content
pub trait BridgeModule {
    fn name(&self) -> &str;
    fn methods(&self);
    fn init(&self);
}

// https://github.com/facebook/react-native/blob/master/ReactAndroid/src/main/java/com/facebook/react/bridge/ReactBridge.java
// https://github.com/facebook/react-native/blob/master/ReactAndroid/src/main/jni/react/Bridge.cpp
pub struct Bridge {
    pub source_url: String,
    javascript_executor: Box<JavaScriptExecutor>,
    modules: Vec<Box<BridgeModule>>,
}

// https://github.com/ReactWindows/react-native/blob/ReactWindows/ReactWindows/ReactNative/Bridge/IReactBridge.cs

impl Bridge {
    pub fn init(source_url: String) -> Bridge {
        // m_mainExecutorToken = folly::make_unique<ExecutorToken>(registerExecutor(
        //   std::move(mainExecutor),
        //   MessageQueues::getCurrentMessageQueueThread()));
        // let

        Bridge {
            source_url: source_url,
            modules: Vec::new(),
            javascript_executor: Box::new(JSCExecutor::init())
        }
    }

    pub fn load_application_script(&self) {
        let source_code = "function a() { return 3; }".to_string();
        // run on executor thread
        // runOnExecutorQueue(*m_mainExecutorToken, [=] (JSExecutor* executor) {
        //   executor->loadApplicationScript(script, sourceURL);
        // });
        self.javascript_executor.load_application_script(source_code, self.source_url.clone());
    }

    fn start(&self) {
        //self.load_application_script();

        // create bridge queue

        // load sourcecode into context

        // init native modules

        // on queue
            // init jsexecutor
    }
}

//
// MessageQueueThread* Bridge::getMessageQueueThread(const ExecutorToken& executorToken) {
//   std::lock_guard<std::mutex> registrationGuard(m_registrationMutex);
//   auto it = m_executorMap.find(executorToken);
//   if (it == m_executorMap.end()) {
//     return nullptr;
//   }
//   return it->second->messageQueueThread_.get();
// }
//
// JSExecutor* Bridge::getExecutor(const ExecutorToken& executorToken) {
//   std::lock_guard<std::mutex> registrationGuard(m_registrationMutex);
//   auto it = m_executorMap.find(executorToken);
//   if (it == m_executorMap.end()) {
//     return nullptr;
//   }
//   return it->second->executor_.get();
// }
//
// ExecutorToken Bridge::getTokenForExecutor(JSExecutor& executor) {
//   std::lock_guard<std::mutex> registrationGuard(m_registrationMutex);
//   return m_executorTokenMap.at(&executor);
// }
//
// run_on_executor_queue(ExecutorToken executorToken, std::function<void(JSExecutor*)> task) {
//   if (m_destroyed->load(std::memory_order_acquire)) {
//     return;
//   }
//
//   auto executorMessageQueueThread = getMessageQueueThread(executorToken);
//   if (executorMessageQueueThread == nullptr) {
//     LOG(WARNING) << "Dropping JS action for executor that has been unregistered...";
//     return;
//   }
//
//   std::shared_ptr<std::atomic_bool> isDestroyed = m_destroyed;
//   executorMessageQueueThread->runOnQueue([this, isDestroyed, executorToken, task=std::move(task)] {
//     if (isDestroyed->load(std::memory_order_acquire)) {
//       return;
//     }
//
//     JSExecutor *executor = getExecutor(executorToken);
//     if (executor == nullptr) {
//       LOG(WARNING) << "Dropping JS call for executor that has been unregistered...";
//       return;
//     }
//
//     // The executor is guaranteed to be valid for the duration of the task because:
//     // 1. the executor is only destroyed after it is unregistered
//     // 2. the executor is unregistered on this queue
//     // 3. we just confirmed that the executor hasn't been unregistered above
//     task(executor);
//   });
// }
