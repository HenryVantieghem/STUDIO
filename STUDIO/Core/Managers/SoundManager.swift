//
//  SoundManager.swift
//  STUDIO
//
//  Ambient music and sound effects system
//  Basel Afterdark Design System
//

import AVFoundation
import SwiftUI
import Combine

// MARK: - Sound Manager

/// Central manager for all audio in the app - ambient music, UI sounds, and effects
@Observable
@MainActor
final class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    var isMusicEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "soundManager.musicEnabled")
            if isMusicEnabled {
                resumeAmbientMusic()
            } else {
                pauseAmbientMusic()
            }
        }
    }

    var isSoundEffectsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEffectsEnabled, forKey: "soundManager.sfxEnabled")
        }
    }

    var musicVolume: Float = 0.3 {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "soundManager.musicVolume")
            ambientPlayer?.volume = musicVolume
        }
    }

    var sfxVolume: Float = 0.7 {
        didSet {
            UserDefaults.standard.set(sfxVolume, forKey: "soundManager.sfxVolume")
        }
    }

    private(set) var currentAmbientTrack: AmbientTrack?
    private(set) var isPlayingAmbient: Bool = false

    // MARK: - Audio Players

    private var ambientPlayer: AVAudioPlayer?
    private var sfxPlayers: [SoundEffect: AVAudioPlayer] = [:]

    // MARK: - Initialization

    private init() {
        loadSettings()
        configureAudioSession()
        preloadSoundEffects()
    }

    // MARK: - Configuration

    private func loadSettings() {
        if let enabled = UserDefaults.standard.object(forKey: "soundManager.musicEnabled") as? Bool {
            isMusicEnabled = enabled
        }
        if let enabled = UserDefaults.standard.object(forKey: "soundManager.sfxEnabled") as? Bool {
            isSoundEffectsEnabled = enabled
        }
        if let volume = UserDefaults.standard.object(forKey: "soundManager.musicVolume") as? Float {
            musicVolume = volume
        }
        if let volume = UserDefaults.standard.object(forKey: "soundManager.sfxVolume") as? Float {
            sfxVolume = volume
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Ambient Music

    /// Play ambient music track
    func playAmbientMusic(_ track: AmbientTrack) {
        guard isMusicEnabled else { return }

        // Stop current track
        stopAmbientMusic(fadeOut: false)

        currentAmbientTrack = track

        // Try to load from bundle
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: track.fileExtension) else {
            print("Ambient track not found: \(track.fileName).\(track.fileExtension)")
            isPlayingAmbient = false
            return
        }

        do {
            ambientPlayer = try AVAudioPlayer(contentsOf: url)
            ambientPlayer?.numberOfLoops = -1 // Loop forever
            ambientPlayer?.volume = 0
            ambientPlayer?.prepareToPlay()
            ambientPlayer?.play()
            isPlayingAmbient = true

            // Fade in
            fadeAmbientVolume(to: musicVolume, duration: 2.0)
        } catch {
            print("Failed to play ambient track: \(error)")
            isPlayingAmbient = false
        }
    }

    /// Stop ambient music with fade out
    func stopAmbientMusic(fadeOut: Bool = true) {
        guard let player = ambientPlayer else { return }

        if fadeOut && player.isPlaying {
            fadeAmbientVolume(to: 0, duration: 1.0) {
                self.ambientPlayer?.stop()
                self.ambientPlayer = nil
                self.isPlayingAmbient = false
                self.currentAmbientTrack = nil
            }
        } else {
            player.stop()
            ambientPlayer = nil
            isPlayingAmbient = false
            currentAmbientTrack = nil
        }
    }

    /// Fade ambient volume
    private func fadeAmbientVolume(to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player = ambientPlayer else {
            completion?()
            return
        }

        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = (targetVolume - player.volume) / Float(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak player] in
                player?.volume += volumeStep
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }

    /// Pause ambient music
    func pauseAmbientMusic() {
        ambientPlayer?.pause()
        isPlayingAmbient = false
    }

    /// Resume ambient music
    func resumeAmbientMusic() {
        guard isMusicEnabled, let player = ambientPlayer else { return }
        player.play()
        isPlayingAmbient = true
    }

    // MARK: - Sound Effects

    /// Preload common sound effects for quick playback
    private func preloadSoundEffects() {
        for effect in SoundEffect.allCases {
            preloadEffect(effect)
        }
    }

    private func preloadEffect(_ effect: SoundEffect) {
        guard let url = Bundle.main.url(forResource: effect.fileName, withExtension: effect.fileExtension) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            sfxPlayers[effect] = player
        } catch {
            // Silently fail - will use system sounds
        }
    }

    /// Play a sound effect
    func playSound(_ effect: SoundEffect) {
        guard isSoundEffectsEnabled else { return }

        // Try preloaded player first
        if let player = sfxPlayers[effect] {
            player.volume = sfxVolume
            player.currentTime = 0
            player.play()
            return
        }

        // Fall back to system sounds
        playSystemSound(for: effect)
    }

    /// Play system sound as fallback
    private func playSystemSound(for effect: SoundEffect) {
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }

    // MARK: - Legacy Methods (compatibility)

    func playSuccess() {
        playSound(.success)
    }

    func playError() {
        playSound(.error)
    }

    func playNotification() {
        playSound(.notification)
    }

    func playTap() {
        playSound(.tap)
    }

    func playCameraShutter() {
        playSound(.camera)
    }

    func playMessageSent() {
        playSound(.send)
    }

    // MARK: - Party Mode

    /// Enable party mode with appropriate ambient music
    func enablePartyMode(for partyType: PartyType?) {
        let track: AmbientTrack

        switch partyType {
        case .nightclub:
            track = .clubBass
        case .houseparty:
            track = .houseVibes
        case .rooftop:
            track = .chillBeats
        case .afterparty:
            track = .lateNight
        case .pregame:
            track = .buildUp
        case .concert:
            track = .liveCrowd
        case .festival:
            track = .festivalVibes
        case .rave:
            track = .techno
        case .brunch:
            track = .jazzLounge
        case .vip:
            track = .luxuryLounge
        case .none:
            track = .ambientNight
        }

        playAmbientMusic(track)
    }

    /// Disable party mode
    func disablePartyMode() {
        stopAmbientMusic()
    }
}

// MARK: - Ambient Track

enum AmbientTrack: String, CaseIterable, Sendable {
    case ambientNight = "ambient_night"
    case clubBass = "club_bass"
    case houseVibes = "house_vibes"
    case chillBeats = "chill_beats"
    case lateNight = "late_night"
    case buildUp = "build_up"
    case liveCrowd = "live_crowd"
    case festivalVibes = "festival_vibes"
    case techno = "techno"
    case jazzLounge = "jazz_lounge"
    case luxuryLounge = "luxury_lounge"

    var name: String {
        switch self {
        case .ambientNight: return "Ambient Night"
        case .clubBass: return "Club Bass"
        case .houseVibes: return "House Vibes"
        case .chillBeats: return "Chill Beats"
        case .lateNight: return "Late Night"
        case .buildUp: return "Build Up"
        case .liveCrowd: return "Live Crowd"
        case .festivalVibes: return "Festival Vibes"
        case .techno: return "Techno"
        case .jazzLounge: return "Jazz Lounge"
        case .luxuryLounge: return "Luxury Lounge"
        }
    }

    var fileName: String { rawValue }
    var fileExtension: String { "mp3" }

    var emoji: String {
        switch self {
        case .ambientNight: return "🌙"
        case .clubBass: return "🔊"
        case .houseVibes: return "🏠"
        case .chillBeats: return "😎"
        case .lateNight: return "🌃"
        case .buildUp: return "⚡️"
        case .liveCrowd: return "🎤"
        case .festivalVibes: return "🎪"
        case .techno: return "💊"
        case .jazzLounge: return "🎷"
        case .luxuryLounge: return "🥂"
        }
    }
}

// MARK: - Sound Effect

enum SoundEffect: String, CaseIterable, Sendable {
    case tap = "tap"
    case success = "success"
    case error = "error"
    case notification = "notification"
    case send = "send"
    case receive = "receive"
    case unlock = "unlock"
    case camera = "camera"
    case like = "like"
    case levelUp = "level_up"
    case achievement = "achievement"
    case countdown = "countdown"
    case cheers = "cheers"
    case swipe = "swipe"

    var fileName: String { rawValue }
    var fileExtension: String { "wav" }

    var systemSoundID: SystemSoundID {
        switch self {
        case .tap: return 1104
        case .success: return 1057
        case .error: return 1053
        case .notification: return 1007
        case .send: return 1004
        case .receive: return 1003
        case .unlock: return 1111
        case .camera: return 1108
        case .like: return 1519
        case .levelUp: return 1025
        case .achievement: return 1026
        case .countdown: return 1103
        case .cheers: return 1114
        case .swipe: return 1306
        }
    }

    /// Play this sound effect
    func play() {
        SoundManager.shared.playSound(self)
    }
}

// MARK: - Sound Settings View

struct SoundSettingsView: View {
    @State private var soundManager = SoundManager.shared

    var body: some View {
        VStack(spacing: 24) {
            // Music toggle
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { soundManager.isMusicEnabled },
                    set: { soundManager.isMusicEnabled = $0 }
                )) {
                    HStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.studioMuted)

                        Text("AMBIENT MUSIC")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioPrimary)
                    }
                }
                .tint(Color.studioChrome)

                if soundManager.isMusicEnabled {
                    // Volume slider
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.studioMuted)

                        Slider(
                            value: Binding(
                                get: { Double(soundManager.musicVolume) },
                                set: { soundManager.musicVolume = Float($0) }
                            ),
                            in: 0...1
                        )
                        .tint(Color.studioChrome)

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.studioMuted)
                    }
                    .padding(.leading, 24)
                }
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }

            // Sound effects toggle
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { soundManager.isSoundEffectsEnabled },
                    set: { soundManager.isSoundEffectsEnabled = $0 }
                )) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.studioMuted)

                        Text("SOUND EFFECTS")
                            .font(StudioTypography.labelMedium)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioPrimary)
                    }
                }
                .tint(Color.studioChrome)

                if soundManager.isSoundEffectsEnabled {
                    // Volume slider
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.studioMuted)

                        Slider(
                            value: Binding(
                                get: { Double(soundManager.sfxVolume) },
                                set: { soundManager.sfxVolume = Float($0) }
                            ),
                            in: 0...1
                        )
                        .tint(Color.studioChrome)

                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color.studioMuted)
                    }
                    .padding(.leading, 24)

                    // Test button
                    Button {
                        soundManager.playSound(.tap)
                    } label: {
                        Text("TEST SOUND")
                            .font(StudioTypography.labelSmall)
                            .tracking(StudioTypography.trackingNormal)
                            .foregroundStyle(Color.studioMuted)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 24)
                }
            }
            .padding(16)
            .background(Color.studioSurface)
            .overlay {
                Rectangle()
                    .stroke(Color.studioLine, lineWidth: 1)
            }

            // Currently playing
            if soundManager.isPlayingAmbient, let track = soundManager.currentAmbientTrack {
                NowPlayingAmbientCard(track: track)
            }
        }
    }
}

// MARK: - Now Playing Ambient Card

struct NowPlayingAmbientCard: View {
    let track: AmbientTrack
    @State private var animateBars = false

    var body: some View {
        HStack(spacing: 12) {
            Text(track.emoji)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text("NOW PLAYING")
                    .font(StudioTypography.labelSmall)
                    .tracking(StudioTypography.trackingWide)
                    .foregroundStyle(Color.studioMuted)

                Text(track.name.uppercased())
                    .font(StudioTypography.labelMedium)
                    .tracking(StudioTypography.trackingNormal)
                    .foregroundStyle(Color.studioPrimary)
            }

            Spacer()

            // Animated equalizer bars
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(Color.studioChrome)
                        .frame(width: 3)
                        .frame(height: animateBars ? CGFloat.random(in: 8...20) : 8)
                        .animation(
                            .easeInOut(duration: 0.3)
                            .repeatForever()
                            .delay(Double(i) * 0.1),
                            value: animateBars
                        )
                }
            }
            .frame(height: 20)
        }
        .padding(16)
        .background(Color.studioSurface)
        .overlay {
            Rectangle()
                .stroke(Color.studioChrome, lineWidth: 1)
        }
        .onAppear {
            animateBars = true
        }
    }
}

// MARK: - Preview

#Preview("Sound Settings") {
    SoundSettingsView()
        .padding()
        .background(Color.studioBlack)
}
