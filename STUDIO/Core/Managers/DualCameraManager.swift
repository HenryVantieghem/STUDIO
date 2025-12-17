//
//  DualCameraManager.swift
//  STUDIO
//
//  BeReal-style dual camera capture - front + back simultaneously
//  Basel Afterdark Design System
//

@preconcurrency import AVFoundation
import SwiftUI
import UIKit

// MARK: - Dual Camera Manager

@Observable
@MainActor
final class DualCameraManager: NSObject {
    // MARK: - Properties

    var isAuthorized = false
    var isSessionRunning = false
    var frontImage: UIImage?
    var backImage: UIImage?
    var compositeImage: UIImage?
    var error: DualCameraError?
    var flashMode: AVCaptureDevice.FlashMode = .off
    var isCapturing = false

    // For video capture
    var isRecordingVideo = false
    var frontVideoURL: URL?
    var backVideoURL: URL?

    // Camera position for PiP placement
    var pipPosition: PiPPosition = .topLeft

    // Non-isolated sessions
    private nonisolated let frontSession = AVCaptureSession()
    private nonisolated let backSession = AVCaptureSession()

    private var frontPhotoOutput: AVCapturePhotoOutput?
    private var backPhotoOutput: AVCapturePhotoOutput?
    private var frontVideoOutput: AVCaptureMovieFileOutput?
    private var backVideoOutput: AVCaptureMovieFileOutput?

    private let sessionQueue = DispatchQueue(label: "com.studio.dualcamera.session")

    // Completion handlers
    private var frontCaptureCompletion: ((UIImage?) -> Void)?
    private var backCaptureCompletion: ((UIImage?) -> Void)?

    // MARK: - Enums

    enum DualCameraError: LocalizedError {
        case notAuthorized
        case configurationFailed
        case captureError(String)
        case deviceNotAvailable
        case multiCamNotSupported

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access is required to capture photos"
            case .configurationFailed:
                return "Failed to configure cameras"
            case .captureError(let message):
                return message
            case .deviceNotAvailable:
                return "Camera device is not available"
            case .multiCamNotSupported:
                return "This device doesn't support dual cameras"
            }
        }
    }

    enum PiPPosition: String, CaseIterable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight

        var alignment: Alignment {
            switch self {
            case .topLeft: return .topLeading
            case .topRight: return .topTrailing
            case .bottomLeft: return .bottomLeading
            case .bottomRight: return .bottomTrailing
            }
        }

        func next() -> PiPPosition {
            let all = PiPPosition.allCases
            let currentIndex = all.firstIndex(of: self)!
            let nextIndex = (currentIndex + 1) % all.count
            return all[nextIndex]
        }
    }

    // MARK: - Authorization

    func checkAuthorization() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            if granted {
                await configureSessions()
            } else {
                error = .notAuthorized
            }
        case .authorized:
            isAuthorized = true
            await configureSessions()
        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
        @unknown default:
            isAuthorized = false
            error = .notAuthorized
        }
    }

    // MARK: - Session Configuration

    private func configureSessions() async {
        let front = frontSession
        let back = backSession

        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                // Configure front camera
                front.beginConfiguration()
                front.sessionPreset = .photo

                guard let frontDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .front
                ) else {
                    Task { @MainActor [weak self] in
                        self?.error = .deviceNotAvailable
                    }
                    front.commitConfiguration()
                    continuation.resume()
                    return
                }

                do {
                    let frontInput = try AVCaptureDeviceInput(device: frontDevice)
                    if front.canAddInput(frontInput) {
                        front.addInput(frontInput)
                    }

                    let newFrontPhotoOutput = AVCapturePhotoOutput()
                    if front.canAddOutput(newFrontPhotoOutput) {
                        front.addOutput(newFrontPhotoOutput)
                        Task { @MainActor [weak self] in
                            self?.frontPhotoOutput = newFrontPhotoOutput
                        }
                    }

                    front.commitConfiguration()
                } catch {
                    Task { @MainActor [weak self] in
                        self?.error = .configurationFailed
                    }
                    front.commitConfiguration()
                }

                // Configure back camera
                back.beginConfiguration()
                back.sessionPreset = .photo

                guard let backDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                ) else {
                    Task { @MainActor [weak self] in
                        self?.error = .deviceNotAvailable
                    }
                    back.commitConfiguration()
                    continuation.resume()
                    return
                }

                do {
                    let backInput = try AVCaptureDeviceInput(device: backDevice)
                    if back.canAddInput(backInput) {
                        back.addInput(backInput)
                    }

                    let newBackPhotoOutput = AVCapturePhotoOutput()
                    if back.canAddOutput(newBackPhotoOutput) {
                        back.addOutput(newBackPhotoOutput)
                        Task { @MainActor [weak self] in
                            self?.backPhotoOutput = newBackPhotoOutput
                        }
                    }

                    back.commitConfiguration()
                } catch {
                    Task { @MainActor [weak self] in
                        self?.error = .configurationFailed
                    }
                    back.commitConfiguration()
                }

                continuation.resume()
            }
        }
    }

    // MARK: - Session Control

    func startSessions() {
        let front = frontSession
        let back = backSession

        sessionQueue.async { [weak self] in
            guard self != nil else { return }

            if !front.isRunning {
                front.startRunning()
            }
            if !back.isRunning {
                back.startRunning()
            }

            Task { @MainActor [weak self] in
                self?.isSessionRunning = true
            }
        }
    }

    func stopSessions() {
        let front = frontSession
        let back = backSession

        sessionQueue.async { [weak self] in
            guard self != nil else { return }

            if front.isRunning {
                front.stopRunning()
            }
            if back.isRunning {
                back.stopRunning()
            }

            Task { @MainActor [weak self] in
                self?.isSessionRunning = false
            }
        }
    }

    // MARK: - Dual Photo Capture

    func captureDualPhoto() async {
        guard let frontOutput = frontPhotoOutput,
              let backOutput = backPhotoOutput else {
            error = .captureError("Photo outputs not configured")
            return
        }

        isCapturing = true
        frontImage = nil
        backImage = nil
        compositeImage = nil

        // Capture both cameras simultaneously
        await withCheckedContinuation { continuation in
            var frontDone = false
            var backDone = false
            var frontResult: UIImage?
            var backResult: UIImage?

            let checkCompletion = { [weak self] in
                guard frontDone && backDone else { return }

                Task { @MainActor [weak self] in
                    self?.frontImage = frontResult
                    self?.backImage = backResult

                    // Create composite image
                    if let front = frontResult, let back = backResult {
                        self?.compositeImage = self?.createCompositeImage(back: back, front: front)
                    }

                    self?.isCapturing = false
                    continuation.resume()
                }
            }

            // Capture front
            frontCaptureCompletion = { image in
                frontResult = image
                frontDone = true
                checkCompletion()
            }

            // Capture back
            backCaptureCompletion = { image in
                backResult = image
                backDone = true
                checkCompletion()
            }

            // Trigger both captures
            sessionQueue.async { [weak self] in
                guard let self else { return }

                var frontSettings = AVCapturePhotoSettings()
                if frontOutput.availablePhotoCodecTypes.contains(.hevc) {
                    frontSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                frontOutput.capturePhoto(with: frontSettings, delegate: self)

                var backSettings = AVCapturePhotoSettings()
                if backOutput.availablePhotoCodecTypes.contains(.hevc) {
                    backSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                backSettings.flashMode = self.flashMode
                backOutput.capturePhoto(with: backSettings, delegate: self)
            }
        }
    }

    // MARK: - Composite Image Creation

    private func createCompositeImage(back: UIImage, front: UIImage) -> UIImage? {
        let size = CGSize(width: back.size.width, height: back.size.height)

        UIGraphicsBeginImageContextWithOptions(size, false, back.scale)
        defer { UIGraphicsEndImageContext() }

        // Draw back camera (full frame)
        back.draw(in: CGRect(origin: .zero, size: size))

        // Calculate PiP size and position (1/4 of width, positioned in corner)
        let pipWidth = size.width * 0.28
        let pipHeight = pipWidth * (front.size.height / front.size.width)
        let padding: CGFloat = 16

        var pipX: CGFloat = padding
        var pipY: CGFloat = padding

        switch pipPosition {
        case .topLeft:
            pipX = padding
            pipY = padding
        case .topRight:
            pipX = size.width - pipWidth - padding
            pipY = padding
        case .bottomLeft:
            pipX = padding
            pipY = size.height - pipHeight - padding
        case .bottomRight:
            pipX = size.width - pipWidth - padding
            pipY = size.height - pipHeight - padding
        }

        let pipRect = CGRect(x: pipX, y: pipY, width: pipWidth, height: pipHeight)

        // Draw pixel border around PiP
        let borderRect = pipRect.insetBy(dx: -3, dy: -3)
        UIColor.white.setFill()
        UIRectFill(borderRect)

        // Draw inner black border
        let innerBorderRect = pipRect.insetBy(dx: -1, dy: -1)
        UIColor.black.setFill()
        UIRectFill(innerBorderRect)

        // Draw front camera (PiP - mirrored for selfie)
        if let cgImage = front.cgImage {
            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()

            // Mirror horizontally for front camera
            context?.translateBy(x: pipRect.midX, y: pipRect.midY)
            context?.scaleBy(x: -1, y: 1)
            context?.translateBy(x: -pipRect.width/2, y: -pipRect.height/2)

            let flippedRect = CGRect(origin: .zero, size: pipRect.size)
            context?.draw(cgImage, in: flippedRect)

            context?.restoreGState()
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Toggle PiP Position

    func togglePiPPosition() {
        pipPosition = pipPosition.next()

        // Recreate composite if we have both images
        if let front = frontImage, let back = backImage {
            compositeImage = createCompositeImage(back: back, front: front)
        }
    }

    // MARK: - Toggle Flash

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

    // MARK: - Preview Layers

    nonisolated func frontPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: frontSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    nonisolated func backPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: backSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    // MARK: - Cleanup

    func clearCaptures() {
        frontImage = nil
        backImage = nil
        compositeImage = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension DualCameraManager: AVCapturePhotoCaptureDelegate {
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
            // Determine which camera this came from based on output
            if output === self.frontPhotoOutput {
                self.frontCaptureCompletion?(image)
            } else if output === self.backPhotoOutput {
                self.backCaptureCompletion?(image)
            }
        }
    }
}

// MARK: - Dual Camera Preview Views

struct DualCameraFrontPreview: UIViewRepresentable {
    let cameraManager: DualCameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = cameraManager.frontPreviewLayer()
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

struct DualCameraBackPreview: UIViewRepresentable {
    let cameraManager: DualCameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = cameraManager.backPreviewLayer()
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

// MARK: - Dual Capture Result

struct DualCaptureResult: Sendable {
    let frontImage: UIImage?
    let backImage: UIImage?
    let compositeImage: UIImage?
    let caption: String?
}
