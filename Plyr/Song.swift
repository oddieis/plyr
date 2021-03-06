//
//  Song.swift
//  plyr
//
//  Created by Luka Kerr on 24/2/19.
//  Copyright © 2019 Luka Kerr. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation

func ==(lhs: Song, rhs: Song) -> Bool {
  return lhs.url == rhs.url
}

func !=(lhs: Song, rhs: Song) -> Bool {
  return !(lhs == rhs)
}

let MISSING_ARTWORK = NSImage(named: "Missing")

class Song {

  public var url: URL
  public var name: String?
  public var artist: String?
  public var artwork: NSImage?

  init(url: URL) {
    self.url = url
    self.name = nil
    self.artist = nil
    self.artwork = nil

    self.artwork?.setSize()
  }

  public func clearArtwork() {
    self.artwork = nil
  }

  public func setMetadata() {
    let asset = AVURLAsset(url: url)

    for format in asset.availableMetadataFormats {
      if name != nil && artist != nil && artwork != nil {
        return
      }

      for item in asset.metadata(forFormat: format) {
        guard let key = item.commonKey else { continue }

        switch key {
        case .commonKeyTitle:
          name = item.value as? String

        case .commonKeyArtist:
          artist = item.value as? String

        case .commonKeyArtwork:
          guard let imageData = item.value as? Data else { continue }

          artwork = NSImage(data: imageData)
          artwork?.setSize()

        default:
          continue
        }
      }
    }
  }

}
