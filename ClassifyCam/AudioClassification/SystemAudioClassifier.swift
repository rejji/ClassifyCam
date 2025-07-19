/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class for listening to live system audio input, and for performing sound
classification using Sound Analysis.
*/

import Foundation
import AVFoundation
import SoundAnalysis
import Combine

/// A class for performing sound classification that the app interacts with through a singleton instance.
///
/// This class manages the app's audio session, so it's important to avoid adding audio behavior outside of
/// this instance. When the session is inactive, many instance variables assume a `nil` value, and
/// non-`nil` when the singleton is in an active state.
final class SystemAudioClassifier: NSObject {
    /// An enumeration that represents the error conditions that the class emits.
    ///
    /// This class emits classification results and errors through the subject you specify when calling
    /// `startSoundClassification`. The Sound Analysis framework provides most error conditions,
    /// but there are a few where this class generates an error.
    enum SystemAudioClassificationError: Error {

        /// The app encounters an interruption during audio recording.
        case audioStreamInterrupted

        /// The app doesn't have permission to access microphone input.
        case noMicrophoneAccess
    }

    /// A dispatch queue to asynchronously perform analysis on.
    private let analysisQueue = DispatchQueue(label: "com.example.apple-samplecode.classifying-sounds.AnalysisQueue")

    /// An audio engine the app uses to record system input.
    private var audioEngine: AVAudioEngine?

    /// An analyzer that performs sound classification.
    private var analyzer: SNAudioStreamAnalyzer?

    /// An array of sound analysis observers that the class stores to control their lifetimes.
    ///
    /// To perform sound classification, the app registers an observer and a request with an analyzer. While
    /// registered, the analyzer claims a strong reference on the request and not on the observer. It's the
    /// responsibility of the caller to handle the observer's lifetime. When sound classification isn't active,
    /// the variable is `nil`, freeing the observers from memory.
    private var retainedObservers: [SNResultsObserving]?

    /// A subject to deliver sound classification results to, including an error, if necessary.
    private var subject: PassthroughSubject<SNClassificationResult, Error>?

    /// Initializes a SystemAudioClassifier instance, and marks it as private because the instance operates as a singleton.
    private override init() {}

    /// A singleton instance of the SystemAudioClassifier class.
    static let singleton = SystemAudioClassifier()

    /// Requests permission to access microphone input, throwing an error if the user denies access.
    private func ensureMicrophoneAccess() throws {
        var hasMicrophoneAccess = false
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            let sem = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { success in
                hasMicrophoneAccess = success
                sem.signal()
            })
            _ = sem.wait(timeout: DispatchTime.distantFuture)
        case .denied, .restricted:
            break
        case .authorized:
            hasMicrophoneAccess = true
        @unknown default:
            fatalError("unknown authorization status for microphone access")
        }

        if !hasMicrophoneAccess {
            throw SystemAudioClassificationError.noMicrophoneAccess
        }
    }

    /// Configures and activates an AVAudioSession.
    ///
    /// If this method throws an error, it calls `stopAudioSession` to reverse its effects.
    private func startAudioSession() throws {
        //print("startAudioSession")
        stopAudioSession()
        do {
            let audioSession = AVAudioSession.sharedInstance()
            //try audioSession.setCategory(.record, mode: .default)
            //try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("error in startAudioSession: \(error.localizedDescription)")
            stopAudioSession()
            throw error
        }
    }

    /// Deactivates the app's AVAudioSession.
    private func stopAudioSession() {
        //print("stopAudioSession")
        autoreleasepool {
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setActive(false)
        }
    }

    /// Starts observing for audio recording interruptions.
    private func startListeningForAudioSessionInterruptions() {
        //print("startListeningForAudioSessionInterruptions")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.mediaServicesWereLostNotification,
            object: nil)
    }

    /// Stops observing for audio recording interruptions.
    private func stopListeningForAudioSessionInterruptions() {
        //print("stopListeningForAudioSessionInterruptions")
        NotificationCenter.default.removeObserver(
          self,
          name: AVAudioSession.interruptionNotification,
          object: nil)
        NotificationCenter.default.removeObserver(
          self,
          name: AVAudioSession.mediaServicesWereLostNotification,
          object: nil)
    }

    /// Handles notifications the system emits for audio interruptions.
    ///
    /// When an interruption occurs, the app notifies the subject of an error. The method terminates sound
    /// classification, so restart it to resume classification.
    ///
    /// - Parameter notification: A notification the system emits that indicates an interruption.
    @objc
    private func handleAudioSessionInterruption(_ notification: Notification) {
        //print("handleAudioSessionInterruption")
        let error = SystemAudioClassificationError.audioStreamInterrupted
        subject?.send(completion: .failure(error))
        stopSoundClassification()
    }
    
    /// Starts sound analysis of the system's audio input.
    ///
    /// This method configures AVAudioSession, and begins recording and classifying sounds for it. If
    /// an error occurs, it calls the `stopAnalyzing` method to reset the state.
    ///
    /// - Parameter requestsAndObservers: A list of pairs that contains an analysis request to
    ///   register, and an observer to send results to. The system retains both the requests and the observers
    ///   during analysis.
    private func startAnalyzing(_ requestsAndObservers: [(SNRequest, SNResultsObserving)]) throws {
        stopAnalyzing()
        //print("startAnalyzing")

        do {
            try startAudioSession()

            try ensureMicrophoneAccess()

            let newAudioEngine = AVAudioEngine()
            audioEngine = newAudioEngine

            let busIndex = AVAudioNodeBus(0)
            let bufferSize = AVAudioFrameCount(4096)
            let audioFormat = newAudioEngine.inputNode.outputFormat(forBus: busIndex)

            let newAnalyzer = SNAudioStreamAnalyzer(format: audioFormat)
            analyzer = newAnalyzer

            try requestsAndObservers.forEach { try newAnalyzer.add($0.0, withObserver: $0.1) }
            retainedObservers = requestsAndObservers.map { $0.1 }

            newAudioEngine.inputNode.installTap(
              onBus: busIndex,
              bufferSize: bufferSize,
              format: audioFormat,
              block: { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                  self.analysisQueue.async {
                      newAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
                  }
              })

            try newAudioEngine.start()
        } catch {
            print("error in startAnalyzing: \(error.localizedDescription)")
            stopAnalyzing()
            throw error
        }
    }

    /// Stops the active sound analysis and resets the state of the class.
    private func stopAnalyzing() {
        //print("stopAnalyzing")
        autoreleasepool {
            if let audioEngine = audioEngine {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }

            if let analyzer = analyzer {
                analyzer.removeAllRequests()
            }

            analyzer = nil
            retainedObservers = nil
            audioEngine = nil
        }
        stopAudioSession()
    }

    /// Classifies system audio input using the built-in classifier.
    ///
    /// - Parameters:
    ///   - subject: A subject publishes the results of the sound classification. The subject receives
    ///   notice when classification terminates. A caller may attach subscribers to the subject before or
    ///   after calling this method. By attaching after, you may miss errors if classification fails to start.
    ///   - inferenceWindowSize: The amount of audio, in seconds, to account for in each
    ///   classification prediction. As this value grows, the accuracy may increase for longer sounds that
    ///   need more context to identify. However, delays also increase between the moment a sound
    ///   occurs and the moment that a sound produces a classification. This is because the system needs
    ///   to collect enough audio to gather the amount of context necessary to produce a prediction.
    ///   Increased accuracy is a trade-off for the responsiveness of a live classification app.
    ///   - overlapFactor: A ratio that indicates what part of an audio window overlaps with an
    ///   adjacent audio window. A value of 0.5 indicates that the audio for two consecutive predictions
    ///   overlaps so that the last 50% of the first duration serves as the first 50% of the second
    ///   duration. The factor determines the stride between consecutive durations of audio that produce
    ///   sound classification. As the factor increases, the stride decreases. As the stride decreases, the
    ///   system produces more predictions. So, at the computational expense of producing more predictions,
    ///   decreasing the stride by raising the overlap factor can improve perceived responsiveness.
    func startSoundClassification(subject: PassthroughSubject<SNClassificationResult, Error>,
                                  inferenceWindowSize: Double,
                                  overlapFactor: Double) {
        stopSoundClassification()
        print("startSoundClassification")

        do {
            let observer = ClassificationResultsSubject(subject: subject)

            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            request.windowDuration = CMTimeMakeWithSeconds(inferenceWindowSize, preferredTimescale: 48_000)
            request.overlapFactor = overlapFactor

            self.subject = subject

            startListeningForAudioSessionInterruptions()
            try startAnalyzing([(request, observer)])
        } catch {
            print("error in startSoundClassification: \(error.localizedDescription)")
            subject.send(completion: .failure(error))
            self.subject = nil
            stopSoundClassification()
        }
    }

    /// Stops any active sound classification task.
    func stopSoundClassification() {
        print("stopSoundClassification")
        stopAnalyzing()
        stopListeningForAudioSessionInterruptions()
    }

    /// Emits the set of labels producible by sound classification.
    ///
    ///  - Returns: The set of all labels that sound classification emits.
    static func getAllPossibleLabels() throws -> Set<String> {
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        return Set<String>(request.knownClassifications)
    }
}

/// Contains customizable settings that control app behavior.
struct AppConfiguration {
    /// Indicates the amount of audio, in seconds, that informs a prediction.
    var inferenceWindowSize = Double(1.5)

    /// The amount of overlap between consecutive analysis windows.
    ///
    /// The system performs sound classification on a window-by-window basis. The system divides an
    /// audio stream into windows, and assigns labels and confidence values. This value determines how
    /// much two consecutive windows overlap. For example, 0.9 means that each window shares 90% of
    /// the audio that the previous window uses.
    var overlapFactor = Double(0.9)

    /// A list of sounds to identify from system audio input.
    var monitoredSounds = Set<SoundIdentifier>()

    /// Retrieves a list of the sounds the system can identify.
    ///
    /// - Returns: A set of identifiable sounds, including the associated labels that sound
    ///   classification emits, and names suitable for displaying to the user.
    static func listAllValidSoundIdentifiers() throws -> Set<SoundIdentifier> {
        let labels = try SystemAudioClassifier.getAllPossibleLabels()
        return Set<SoundIdentifier>(labels.map {
            SoundIdentifier(labelName: $0)
        })
    }
}

/// The runtime state of the app after setup.
///
/// Sound classification begins after completing the setup process. The `DetectSoundsView` displays
/// the results of the classification. Instances of this class contain the detection information that
/// `DetectSoundsView` renders. It incorporates new classification results as the app produces them into
/// the cumulative understanding of what sounds are currently present. It tracks interruptions, and allows for
/// restarting an analysis by providing a new configuration.
class AppState: ObservableObject {
    /// A cancellable object for the lifetime of the sound classification.
    ///
    /// While the app retains this cancellable object, a sound classification task continues to run until it
    /// terminates due to an error.
    private var detectionCancellable: AnyCancellable? = nil

    /// The configuration that governs sound classification.
    private var appConfig = AppConfiguration()

    /// A list of mappings between sounds and current detection states.
    ///
    /// The app sorts this list to reflect the order in which the app displays them.
    @Published var detectionStates: [(SoundIdentifier, DetectionState)] = []

    /// Indicates whether a sound classification is active.
    ///
    /// When `false,` the sound classification has ended for some reason. This could be due to an error
    /// emitted from Sound Analysis, or due to an interruption in the recorded audio. The app needs to prompt
    /// the user to restart classification when `false.`
    @Published var soundDetectionIsRunning: Bool = false
    
    /// Begins detecting sounds according to the configuration you specify.
    ///
    /// If the sound classification is running when calling this method, it stops before starting again.
    ///
    /// - Parameter config: A configuration that provides information for performing sound detection.
    func restartDetection(config: AppConfiguration) {
        print("restartDetection")
        SystemAudioClassifier.singleton.stopSoundClassification()

        let classificationSubject = PassthroughSubject<SNClassificationResult, Error>()

        detectionCancellable =
          classificationSubject
          .receive(on: DispatchQueue.main)
          .sink(
            receiveCompletion: { _ in
                self.soundDetectionIsRunning = false
            },
            receiveValue: { classificationResult in
                /*
                    for classification in classificationResult.classifications {
                        let label = classification.identifier
                        let confidence = classification.confidence
                        print("Received label: \(label) with confidence: \(confidence)")
                    }
                */
                self.detectionStates = AppState.advanceDetectionStates(
                    self.detectionStates,
                    givenClassificationResult: classificationResult)
            }
          )

        self.detectionStates =
          [SoundIdentifier](config.monitoredSounds)
          .sorted(by: { $0.displayName < $1.displayName })
          .map { ($0, DetectionState(presenceThreshold: 0.5,
                                     absenceThreshold: 0.3,
                                     presenceMeasurementsToStartDetection: 2,
                                     absenceMeasurementsToEndDetection: 30))
          }

        soundDetectionIsRunning = true
        appConfig = config
        SystemAudioClassifier.singleton.startSoundClassification(
          subject: classificationSubject,
          inferenceWindowSize: config.inferenceWindowSize,
          overlapFactor: config.overlapFactor)
    }

    /// Updates the detection states according to the latest classification result.
    ///
    /// - Parameters:
    ///   - oldStates: The previous detection states to update with a new observation from an ongoing
    ///   sound classification.
    ///   - result: The latest observation the app emits from an ongoing sound classification.
    ///
    /// - Returns: A new array of sounds with their updated detection states.
    static func advanceDetectionStates(_ oldStates: [(SoundIdentifier, DetectionState)],
                                       givenClassificationResult result: SNClassificationResult) -> [(SoundIdentifier, DetectionState)] {
        let confidenceForLabel = { (sound: SoundIdentifier) -> Double in
            let confidence: Double
            let label = sound.labelName
            if let classification = result.classification(forIdentifier: label) {
                confidence = classification.confidence
            } else {
                confidence = 0
            }
            return confidence
        }
        return oldStates.map { (key, value) in
            (key, DetectionState(advancedFrom: value, currentConfidence: confidenceForLabel(key)))
        }
    }
}

