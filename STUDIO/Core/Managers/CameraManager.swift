//
//  CameraManager.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

@preconcurrency import AVFoundation
import SwiftUI

// MARK: - Camera Manager

@Observable
@MainActor
final class CameraManager: NSObject {
    // MARK: - Properties

    var isAuthorized = false
    var isSessionRunning = false
    var capturedImage: UIImage?
    var capturedVideoURL: URL?
    var error: CameraError?
    var currentPosition: AVCaptureDevice.Position = .back
    var flashMode: AVCaptureDevice.FlashMode = .auto
    var isRecording = false

    // Non-isolated session for background operations
    private nonisolated let session = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentInput: AVCaptureDeviceInput?

    private let sessionQueue = DispatchQueue(label: "com.studio.camera.session")

    // MARK: - Camera Error

    enum CameraError: LocalizedError {
        case notAuthorized
        case configurationFailed
        case captureError(String)
        case deviceNotAvailable

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access is required to capture photos and videos"
            case .configurationFailed:
                return "Failed to configure camera"
            case .captureError(let message):
                return message
            case .deviceNotAvailable:
                return "Camera device is not available"
            }
        }
    }

    // MARK: - Authorization

    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            if granted {
                await configureSession()
            } else {
                error = .notAuthorized
            }
        case .authorized:
            isAuthorized = true
            await configureSession()
        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
        @unknown default:
            isAuthorized = false
            error = .notAuthorized
        }
    }

    // MARK: - Session Configuration

    private func configureSession() async {
        // Capture current position value for use in closure
        let position = currentPosition
        let captureSession = session

        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                captureSession.beginConfiguration()
                captureSession.sessionPreset = .photo

                // Add video input
                guard let videoDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: position
                ) else {
                    Task { @MainActor [weak self] in
                        self?.error = .deviceNotAvailable
                    }
                    captureSession.commitConfiguration()
                    continuation.resume()
                    return
                }

                do {
                    let videoInput = try AVCaptureDeviceInput(device: videoDevice)

                    if captureSession.canAddInput(videoInput) {
                        captureSession.addInput(videoInput)
                        Task { @MainActor [weak self] in
                            self?.currentInput = videoInput
                        }
                    }

                    // Add photo output
                    let newPhotoOutput = AVCapturePhotoOutput()
                    if captureSession.canAddOutput(newPhotoOutput) {
                        captureSession.addOutput(newPhotoOutput)
                        Task { @MainActor [weak self] in
                            self?.photoOutput = newPhotoOutput
                        }
                    }

                    // Add video output
                    let newVideoOutput = AVCaptureMovieFileOutput()
                    if captureSession.canAddOutput(newVideoOutput) {
                        captureSession.addOutput(newVideoOutput)
                        Task { @MainActor [weak self] in
                            self?.videoOutput = newVideoOutput
                        }
                    }

                    // Add audio input for video recording
                    if let audioDevice = AVCaptureDevice.default(for: .audio),
                       let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                       captureSession.canAddInput(audioInput) {
                        captureSession.addInput(audioInput)
                    }

                    captureSession.commitConfiguration()
                } catch {
                    Task { @MainActor [weak self] in
                        self?.error = .configurationFailed
                    }
                    captureSession.commitConfiguration()
                }
                continuation.resume()
            }
        }
    }

    // MARK: - Session Control

    func startSession() {
        let captureSession = session
        sessionQueue.async { [weak self] in
            guard self != nil, !captureSession.isRunning else { return }
            captureSession.startRunning()
            Task { @MainActor [weak self] in
                self?.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        let captureSession = session
        sessionQueue.async { [weak self] in
            guard self != nil, captureSession.isRunning else { return }
            captureSession.stopRunning()
            Task { @MainActor [weak self] in
                self?.isSessionRunning = false
            }
        }
    }

    // MARK: - Camera Controls

    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        let captureSession = session
        let capturedInput = currentInput

        sessionQueue.async { [weak self] in
            guard self != nil else { return }

            guard let newDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: newPosition
            ) else { return }

            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)

                captureSession.beginConfiguration()

                if let existingInput = capturedInput {
                    captureSession.removeInput(existingInput)
                }

                if captureSession.canAddInput(newInput) {
                    captureSession.addInput(newInput)
                    Task { @MainActor [weak self] in
                        self?.currentInput = newInput
                        self?.currentPosition = newPosition
                    }
                }

                captureSession.commitConfiguration()
            } catch {
                // Handle error silently - camera switch failed
            }
        }
    }

    func toggleFlash() {
        switch flashMode {
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        @unknown default:
            flashMode = .auto
        }
    }

    // MARK: - Photo Capture

    func capturePhoto() {
        guard let output = photoOutput else {
            error = .captureError("Photo output not configured")
            return
        }

        var settings = AVCapturePhotoSettings()

        if output.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }

        settings.flashMode = flashMode

        // Capture on session queue
        sessionQueue.async {
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Video Recording

    func startRecording() {
        guard let output = videoOutput, !isRecording else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        sessionQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            output.startRecording(to: tempURL, recordingDelegate: strongSelf)
            Task { @MainActor [weak self] in
                self?.isRecording = true
            }
        }
    }

    func stopRecording() {
        guard let output = videoOutput, isRecording else { return }

        sessionQueue.async {
            output.stopRecording()
        }
    }

    // MARK: - Preview Layer

    nonisolated func previewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    // MARK: - Cleanup

    func clearCapture() {
        capturedImage = nil
        capturedVideoURL = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            Task { @MainActor in
                self.error = .captureError(error.localizedDescription)
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor in
                self.error = .captureError("Failed to process photo")
            }
            return
        }

        Task { @MainActor in
            self.capturedImage = image
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            self.isRecording = false

            if let error {
                self.error = .captureError(error.localizedDescription)
                return
            }

            self.capturedVideoURL = outputFileURL
        }
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = cameraManager.previewLayer()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
