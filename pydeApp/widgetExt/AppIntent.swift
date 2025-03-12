////
////  AppIntent.swift
////  widgetExt
////
////  Created by Huima on 2024/6/11.
////
//
//import WidgetKit
//import AppIntents
//import Intents
//
////struct ConfigurationAppIntent: WidgetConfigurationIntent {
////    static var title: LocalizedStringResource = "Configuration"
////    static var description = IntentDescription("This is an example widget.")
////
////    // An example configurable parameter.
////    @Parameter(title: "Favorite Emoji", default: "😃")
////    var favoriteEmoji: String
////    
////    @Parameter(title: "args", default: nil)
////    var args: String?
////    
////    @Parameter(title: "input", default: nil)
////    var input: String?
////    
////    @Parameter(title: "script", default: nil)
////    var script: IntentFile?
////}
//
//
//@available(iOS 12.0, macOS 11.0, watchOS 5.0, *) @available(tvOS, unavailable)
//@objc(ScriptIntent)
//public class ScriptIntent: INIntent {
//
//    @available(iOS 13.0, macOS 10.16, watchOS 6.0, *)
//    @NSManaged public var script: INFile?
//}
//
///*!
// @abstract Protocol to declare support for handling a ScriptIntent. By implementing this protocol, a class can provide logic for resolving, confirming and handling the intent.
// @discussion The minimum requirement for an implementing class is that it should be able to handle the intent. The confirmation method is optional. The handling method is always called last, after confirming the intent.
// */
//@available(iOS 12.0, macOS 11.0, watchOS 5.0, *) @available(tvOS, unavailable)
//@objc(ScriptIntentHandling)
//public protocol ScriptIntentHandling: NSObjectProtocol {
//
//    /*!
//     @abstract Resolution methods - Determine if this intent is ready for the next step (confirmation)
//     @discussion Called to make sure the app extension is capable of handling this intent in its current form. This method is for validating if the intent needs any further fleshing out.
//
//     @param  intent The input intent
//     @param  completion The response block contains an INIntentResolutionResult for the parameter being resolved
//
//     @see INIntentResolutionResult
//     */
//    @available(iOS 13.0, macOS 11.0, watchOS 6.0, *)
//    @available(*, renamed: "resolveScript(for:)")
//    @objc(resolveScriptForScript:withCompletion:)
//    func resolveScript(for intent: ScriptIntent, with completion: @escaping (INFileResolutionResult) -> Swift.Void)
//
//    @available(iOS 13.0, macOS 11.0, watchOS 6.0, *)
//    @objc(resolveScriptForScript:withCompletion:)
//    func resolveScript(for intent: ScriptIntent) async -> INFileResolutionResult
//
//    /*!
//     @abstract Dynamic options methods - provide options for the parameter at runtime
//     @discussion Called to query dynamic options for the parameter and this intent in its current form.
//
//     @param  intent The input intent
//     @param  completion The response block contains options for the parameter
//     */
//    @available(iOS 14.0, macOS 11.0, watchOS 7.0, *)
//    @available(*, renamed: "provideScriptOptionsCollection(for:)")
//    @objc(provideScriptOptionsCollectionForScript:withCompletion:)
//    func provideScriptOptionsCollection(for intent: ScriptIntent, with completion: @escaping (INObjectCollection<INFile>?, Error?) -> Swift.Void)
//
//    @available(iOS 14.0, macOS 11.0, watchOS 7.0, *)
//    @objc(provideScriptOptionsCollectionForScript:withCompletion:)
//    func provideScriptOptionsCollection(for intent: ScriptIntent) async throws -> INObjectCollection<INFile>
//
//    @available(*, renamed: "confirm(intent:)")
//    @objc(confirmScript:completion:)
//    optional func confirm(intent: ScriptIntent, completion: @escaping (ScriptIntentResponse) -> Swift.Void)
//
//    /*!
//     @abstract Confirmation method - Validate that this intent is ready for the next step (i.e. handling)
//     @discussion Called prior to asking the app to handle the intent. The app should return a response object that contains additional information about the intent, which may be relevant for the system to show the user prior to handling. If unimplemented, the system will assume the intent is valid, and will assume there is no additional information relevant to this intent.
//
//     @param  intent The input intent
//     @param  completion The response block contains a ScriptIntentResponse containing additional details about the intent that may be relevant for the system to show the user prior to handling.
//
//     @see ScriptIntentResponse
//     */
//    @available(iOS 13.0, macOS 11.0, watchOS 6.0, *)
//    @objc(confirmScript:completion:)
//    optional func confirm(intent: ScriptIntent) async -> ScriptIntentResponse
//
//    /*!
//     @abstract Handling method - Execute the task represented by the ScriptIntent that's passed in
//     @discussion Called to actually execute the intent. The app must return a response for this intent.
//
//     @param  intent The input intent
//     @param  completion The response handling block takes a ScriptIntentResponse containing the details of the result of having executed the intent
//
//     @see  ScriptIntentResponse
//     */
//    @available(*, renamed: "handle(intent:)")
//    @objc(handleScript:completion:)
//    optional func handle(intent: ScriptIntent, completion: @escaping (ScriptIntentResponse) -> Swift.Void)
//    
//    @available(iOS 13.0, macOS 11.0, watchOS 6.0, *)
//    @objc(handleScript:completion:)
//    optional func handle(intent: ScriptIntent) async -> ScriptIntentResponse
//
//    /*!
//     @abstract Default values for parameters with dynamic options
//     @discussion Called to query the parameter default value.
//     */
//    @available(iOS 14.0, macOS 11.0, watchOS 7.0, *)
//    @objc(defaultScriptForScript:)
//    optional func defaultScript(for intent: ScriptIntent) -> INFile?
//
//    /*!
//     @abstract Deprecated dynamic options methods.
//     */
//    @available(iOS, introduced: 13.0, deprecated: 14.0, message: "")
//    @available(watchOS, introduced: 6.0, deprecated: 7.0, message: "")
//    @objc(provideScriptOptionsForScript:withCompletion:)
//    optional func provideScriptOptions(for intent: ScriptIntent, with completion: @escaping ([INFile]?, Error?) -> Swift.Void)
//
//}
//
///*!
// @abstract Constants indicating the state of the response.
// */
//@available(iOS 12.0, macOS 11.0, watchOS 5.0, *) @available(tvOS, unavailable)
//@objc public enum ScriptIntentResponseCode: Int {
//    case unspecified = 0
//    case ready
//    case continueInApp
//    case inProgress
//    case success
//    case failure
//    case failureRequiringAppLaunch
//}
//
//@available(iOS 12.0, macOS 11.0, watchOS 5.0, *) @available(tvOS, unavailable)
//@objc(ScriptIntentResponse)
//public class ScriptIntentResponse: INIntentResponse {
//
//    /*!
//     @abstract The response code indicating your success or failure in confirming or handling the intent.
//     */
//    @objc public fileprivate(set) var code: ScriptIntentResponseCode = .unspecified
//
//    /*!
//     @abstract Initializes the response object with the specified code and user activity object.
//     @discussion The app extension has the option of capturing its private state as an NSUserActivity and returning it as the 'currentActivity'. If the app is launched, an NSUserActivity will be passed in with the private state. The NSUserActivity may also be used to query the app's UI extension (if provided) for a view controller representing the current intent handling state. In the case of app launch, the NSUserActivity will have its activityType set to the name of the intent. This intent object will also be available in the NSUserActivity.interaction property.
//
//     @param  code The response code indicating your success or failure in confirming or handling the intent.
//     @param  userActivity The user activity object to use when launching your app. Provide an object if you want to add information that is specific to your app. If you specify nil, the system automatically creates a user activity object for you, sets its type to the class name of the intent being handled, and fills it with an INInteraction object containing the intent and your response.
//     */
//    @objc(initWithCode:userActivity:)
//    public convenience init(code: ScriptIntentResponseCode, userActivity: NSUserActivity?) {
//        self.init()
//        self.code = code
//        self.userActivity = userActivity
//    }
//
//}
