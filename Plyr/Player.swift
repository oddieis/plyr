//
//  Player.swift
//  Plyr
//
//  Created by Luka Kerr on 1/3/18.
//  Copyright © 2018 Luka Kerr. All rights reserved.
//

import Foundation
import AVFoundation

final class Player: NSObject, AVAudioPlayerDelegate, NSUserNotificationCenterDelegate {

  /// All songs
  private var songs: [Song]!

  /// Main audio player
  private var audioPlayer: AVAudioPlayer!

  /// Currently playing song
  private var currentSong: Song!

  /// Currently playing song index
  private var currentSongIndex: Int!

  /// Whether the player is currently playing or paused
  public var playing: Bool {
    return audioPlayer.isPlaying
  }

  override init() {
    super.init()

    self.currentSongIndex = preferences.currentSongIndex
    NSUserNotificationCenter.default.delegate = self
  }

  public func initialize() {
    self.songs = self.getAllSongs()
  }

  /// Plays all songs one by one
  public func playAll() {
    if songs.count > currentSongIndex {
      currentSong = songs[currentSongIndex]
      play(currentSong.url)
    } else {
      let notification = NSUserNotification()
      notification.title = "No music found"
      notification.informativeText = "No music could be found. Exiting"
      notification.soundName = NSUserNotificationDefaultSoundName
      NSUserNotificationCenter.default.deliver(notification)
      exit(0)
    }
  }

  // MARK: - Public methods to control the player

  public func pause() {
    audioPlayer.pause()
  }

  public func resume() {
    audioPlayer.prepareToPlay()
    audioPlayer.play()
  }

  public func skip() {
    audioPlayer.currentTime += 10.0
  }

  public func rewind() {
    audioPlayer.currentTime -= 10.0
  }

  public func next() {
    let newIndex = (currentSongIndex + 1) % songs.count

    currentSongIndex = newIndex
    preferences.currentSongIndex = newIndex

    playAll()
  }

  public func previous() {
    let newIndex = currentSongIndex <= 0 ? 0 : currentSongIndex - 1

    currentSongIndex = newIndex
    preferences.currentSongIndex = newIndex

    playAll()
  }

  public func play(_ song: Song) {
    if let index = songs.firstIndex(where: { $0.url == song.url }) {
      currentSongIndex = index
      preferences.currentSongIndex = index
      playAll()
    }
  }

  public func play(_ song: URL) {
    audioPlayer = try? AVAudioPlayer(contentsOf: song)
    audioPlayer.numberOfLoops = 0
    audioPlayer.delegate = self
    audioPlayer.prepareToPlay()
    audioPlayer.play()

    DispatchQueue.global(qos: .userInitiated).async {
      self.currentSong.setMetadata()

      DispatchQueue.main.async {
        NotificationCenter.default.post(
          name: NSNotification.Name(rawValue: "setSongDetails"),
          object: self.currentSong
        )
      }
    }
  }

  public func clearSongArtwork() {
    self.songs.forEach {
      if $0 != currentSong {
        $0.clearArtwork()
      }
    }
  }

  public func song(for term: String) -> [Song] {
    if term.count < 2 {
      return []
    }

    return songs.filter {
      if let path = $0.url.lastPathComponent.removingPercentEncoding {
        return path.lowercased().contains(term.lowercased())
      }

      return false
    }
  }

  // MARK: - Private methods

  // Returns an array of URLs found under ~/Music
  private func getAllSongs() -> [Song] {
    let path = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Music"
    let songs = FileManager.default.filteredMusicFileURLs(inDirectory: path)
    return songs
  }

  // MARK: - AVAudioPlayerDelegate methods

  // Called when a song playing the player ends
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    next()
  }

}
