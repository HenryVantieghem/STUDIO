//
//  SoundManager.swift
//  STUDIO
//
//  Created by Claude on 12/16/25.
//

import AVFoundation
import SwiftUI

// MARK: - Sound Manager

/// Centralized sound management for app audio feedback
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?

    @AppStorage("soundsEnabled") private var soundsEnabled = true

    private init() {
        setupAudioSession()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - System Sounds

    /// Play a system sound by ID
    func playSystemSound(_ soundID: SystemSoundID) {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
    }

    /// Play success sound
    func playSuccess() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1057) // Success sound
    }

    /// Play error sound
    func playError() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1053) // Error sound
    }

    /// Play notification sound
    func playNotification() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1007) // SMS received
    }

    /// Play tap sound
    func playTap() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tap sound
    }

    /// Play swipe sound
    func playSwipe() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1306) // Swipe sound
    }

    /// Play camera shutter sound
    func playCameraShutter() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1108) // Camera shutter
    }

    /// Play message sent sound
    func playMessageSent() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(1004) // Mail sent
    }

    // MARK: - Custom Sounds

    /// Play a custom sound from bundle
    func playCustomSound(named name: String, extension ext: String = "mp3") {
        guard soundsEnabled else { return }

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Sound file not found: \(name).\(ext)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    /// Stop any playing custom sound
    func stopCustomSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

// MARK: - Sound Effect Enum

enum SoundEffect {
    case success
    case error
    case notification
    case tap
    case swipe
    case cameraShutter
    case messageSent

    func play() {
        let manager = SoundManager.shared
        switch self {
        case .success:
            manager.playSuccess()
        case .error:
            manager.playError()
        case .notification:
            manager.playNotification()
        case .tap:
            manager.playTap()
        case .swipe:
            manager.playSwipe()
        case .cameraShutter:
            manager.playCameraShutter()
        case .messageSent:
            manager.playMessageSent()
        }
    }
}
